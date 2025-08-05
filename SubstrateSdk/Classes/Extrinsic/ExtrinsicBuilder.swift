import Foundation
import BigInt
import NovaCrypto

public protocol ExtrinsicBuilderProtocol {
    func with<A: Codable>(address: A) throws -> Self
    func with(nonce: UInt32) -> Self
    func getNonce() -> UInt32?
    func with(era: Era, blockHash: String) -> Self
    func with(tip: BigUInt) -> Self
    func with(metadataHash: Data) -> Self
    func with(batchType: ExtrinsicBatch) -> Self
    func with(signaturePayloadFormat: ExtrinsicSignaturePayloadFormat) -> Self
    func adding<T: RuntimeCallable>(call: T) throws -> Self
    func adding<T: RuntimeCallable>(call: T, at index: Int) throws -> Self
    func adding(rawCall: Data) throws -> Self
    func adding(transactionExtension: TransactionExtending) -> Self
    func with(runtimeJsonContext: RuntimeJsonContext) -> Self
    func wrappingCalls(for mapClosure: (JSON) throws -> JSON) throws -> Self
    func batchingCalls(with metadata: RuntimeMetadataProtocol) throws -> Self
    func getCalls() -> [JSON]
    func resetCalls() -> Self

    func signing(
        by signer: @escaping (Data) throws -> Data,
        of type: CryptoType,
        using encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol
    ) throws -> Self

    func signing(
        by signer: @escaping (Data) throws -> JSON,
        using encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol
    ) throws -> Self

    func buildRawSignature(
        using signer: @escaping (Data) throws -> Data,
        encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol
    ) throws -> Data

    func buildExtrinsicSignatureParams(
        encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol
    ) throws -> ExtrinsicSignatureParams
    
    func buildSignaturePayload(
        encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol
    ) throws -> Data

    func build(
        using encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol
    ) throws -> Data

    func makeMemo() -> ExtrinsicBuilderMemoProtocol
}

public extension ExtrinsicBuilderProtocol {
    func with(shouldUseAtomicBatch: Bool) -> Self {
        with(batchType: shouldUseAtomicBatch ? .atomic : .untilFail)
    }
}

public enum ExtrinsicBuilderError: Error {
    case missingCall
    case missingAddress
    case unsupportedBatch
    case indexOutOfBounds
    case noSignature
}

///
/// A class that provides an interface for building extrinsics.
///
/// ## Supported Extrinsic Types
/// - **Bare Extrinsics**:
///   - Bare extrinsics are unsigned and consist of:
///     - `Version`: Specifies the extrinsic version.
///     - `Call`: The function to be executed.
///   - These are the simplest type of extrinsics and do not define a call origin.
///
/// - **Versioned Extrinsics**:
///   - Extrinsics that define the call origin are versioned. Supported types:
///     - **V4 (Legacy)**:
///       - Always defines a signed origin.
///       - Requires a signature from the account on whose behalf the extrinsic is executed.
///       - Components:
///         - `Version`: Specifies the extrinsic version.
///         - `Signature`: The signature of the executing account.
///         - `Signed Extension Parameters`: Additional parameters for the extrinsic.
///         - `Call`: The function to be executed.
///
///     - **V5 (General Transactions)**:
///       - Uses transaction extensions to define the origin.
///       - Example: A signed origin can be defined using the `VerifySignature` transaction extension. But it is not needed to provide
///       the extension manually as builder automatically configures when signing function is called.
///       - More flexible than V4 extrinsics, as it supports any origin via transaction extensions.
///       - Components:
///         - `Version`: Specifies the extrinsic version.
///         - `Extension Version`: Indicates the transaction extension version.
///         - `Transaction Extension Parameters`: Define the origin and transaction-specific details.
///         - `Call`: The function to be executed.
///
/// ## Using the Builder
/// 1. **Select the Extrinsic Version**:
///    - Choose between `V4` or `V5` extrinsics.
///    - For bare extrinsics, any version can be used.
/// 2. **Initialize the Builder**:
///    - Provide the necessary parameters, such as:
///      - `Nonce`
///      - `Metadata Hash`
///      - Other parameters, depending on the use case.
/// 3. **Specify Calls**:
///    - Add the calls to be executed as part of the extrinsic.
///    - Multiple calls can be grouped into a batch, with configurable batch types.
/// 4. **Set Execution Type**:
///    - Choose between signing the extrinsic or using transaction extensions.
///    - Example:
///      - If a call requires a specific origin different from the signed one, provide appropriate transaction extension parameters instead of signing the extrinsic.
///
///
public final class ExtrinsicBuilder {
    
    
    let extrinsicVersion: Extrinsic.Version

    private var address: JSON?
    private var runtimeJsonContext: RuntimeJsonContext?
    private var calls: [JSON]
    private var batchType: ExtrinsicBatch = .atomic
    private var transactionExtensions: [String: TransactionExtending]
    private var signaturePayloadFormat: ExtrinsicSignaturePayloadFormat = .regular
    private var extrinsic: Extrinsic?

    public init(
        extrinsicVersion: Extrinsic.Version = .V4,
        specVersion: UInt32,
        transactionVersion: UInt32,
        genesisHash: String
    ) {
        self.extrinsicVersion = extrinsicVersion
        calls = []

        transactionExtensions = [
            Extrinsic.TransactionExtensionId.specVersion: TransactionExtension.CheckSpecVersion(
                specVersion: specVersion
            ),
            Extrinsic.TransactionExtensionId.txVersion: TransactionExtension.CheckTxVersion(
                transactionVersion: transactionVersion
            ),
            Extrinsic.TransactionExtensionId.genesis: TransactionExtension.CheckGenesis(
                genesisHash: genesisHash
            ),
            Extrinsic.TransactionExtensionId.mortality: TransactionExtension.CheckMortality(
                era: .immortal,
                blockHash: genesisHash
            ),
            Extrinsic.TransactionExtensionId.nonce: TransactionExtension.CheckNonce(nonce: 0),
            Extrinsic.TransactionExtensionId.txPayment: TransactionExtension.ChargeTransactionPayment(
                tip: 0
            ),
            Extrinsic.TransactionExtensionId.checkMetadataHash: TransactionExtension.CheckMetadataHash(mode: .disabled),
            Extrinsic.TransactionExtensionId.verifySignature: TransactionExtension.VerifySignature(
                extrinsicVersion: extrinsicVersion,
                usability: .disabled
            )
        ]
    }

    public init(
        extrinsicVersion: Extrinsic.Version = .V4,
        calls: [JSON] = [],
        transactionExtensions: [TransactionExtending] = []
    ) {
        self.extrinsicVersion = extrinsicVersion
        self.calls = calls
        self.transactionExtensions = transactionExtensions.reduce(into: [:]) { $0[$1.txExtensionId] = $1 }
    }

    init(memo: ExtrinsicBuilderMemo) {
        extrinsicVersion = memo.extrinsicVersion
        extrinsic = memo.extrinsic
        address = memo.address
        calls = memo.calls
        batchType = memo.batchType
        transactionExtensions = memo.transactionExtensions
        signaturePayloadFormat = memo.signaturePayloadFormat
        runtimeJsonContext = memo.runtimeJsonContext
    }
}

private extension ExtrinsicBuilder {
    private func prepareTransactionCall(
        for metadata: RuntimeMetadataProtocol
    ) throws -> JSON {
        guard !calls.isEmpty else {
            throw ExtrinsicBuilderError.missingCall
        }

        guard calls.count > 1 else {
            return calls[0]
        }

        let callName: String

        switch batchType {
        case .atomic:
            if metadata.getCall(from: KnowRuntimeModule.Utility.name, with: KnowRuntimeModule.Utility.batchAll) != nil {
                callName = KnowRuntimeModule.Utility.batchAll
            } else {
                callName = KnowRuntimeModule.Utility.batchAtomic
            }
        case .untilFail:
            callName = KnowRuntimeModule.Utility.batch
        case .ignoreFails:
            callName = KnowRuntimeModule.Utility.forceBatch
        }

        let call = RuntimeCall(
            moduleName: KnowRuntimeModule.Utility.name,
            callName: callName,
            args: BatchArgs(calls: calls)
        )

        guard metadata.getCall(from: call.moduleName, with: call.callName) != nil else {
            throw ExtrinsicBuilderError.unsupportedBatch
        }

        return try call.toScaleCompatibleJSON(with: runtimeJsonContext?.toRawContext())
    }

    private func prepareImplication(
        using encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol
    ) throws -> TransactionExtension.Implication {
        let call = try prepareTransactionCall(for: metadata)

        let initialImplication = TransactionExtension.Implication(call: call, explicits: [], implicits: [])

        let requiredExtensions = metadata.getSignedExtensions()

        return try requiredExtensions.reversed().reduce(initialImplication) { implication, extensionId in
            if let transactionExtension = transactionExtensions[extensionId] {
                let implicit = try transactionExtension.implicit(
                    using: encodingFactory,
                    metadata: metadata,
                    context: runtimeJsonContext
                )

                let explicit = try transactionExtension.explicit(
                    for: implication,
                    encodingFactory: encodingFactory,
                    metadata: metadata,
                    context: runtimeJsonContext
                )

                return implication.adding(explicit: explicit, implicit: implicit)
            } else {
                // add default implementation in case explicit is either empty or null acceptable

                let coder = encodingFactory.createEncoder()

                if
                    let extensionType = metadata.getSignedExtensionType(for: extensionId),
                    coder.canEncodeOptional(for: extensionType) {
                    let explicit = try TransactionExtension.Explicit(
                        from: JSON.null,
                        txExtensionId: extensionId,
                        metadata: metadata
                    )

                    return implication.adding(explicit: explicit, implicit: nil)
                } else {
                    return implication
                }
            }
        }
    }

    private func prepareParitySignerSignaturePayload(
        implication: TransactionExtension.Implication,
        encodingFactory: DynamicScaleEncodingFactoryProtocol
    ) throws -> Data {
        let signaturePayloadFactory = ParitySignerSignaturePayloadFactory(extrinsicVersion: extrinsicVersion)
        return try signaturePayloadFactory.createPayload(from: implication, using: encodingFactory)
    }

    private func prepareRegularSignaturePayload(
        implication: TransactionExtension.Implication,
        encodingFactory: DynamicScaleEncodingFactoryProtocol
    ) throws -> Data {
        let payload = try prepareNotHashedSignaturePayload(implication: implication, encodingFactory: encodingFactory)
        return try ExtrinsicSignatureConverter.convertExtrinsicPayloadToRegular(payload)
    }

    private func prepareNotHashedSignaturePayload(
        implication: TransactionExtension.Implication,
        encodingFactory: DynamicScaleEncodingFactoryProtocol
    ) throws -> Data {
        let signaturePayloadFactory = ExtrinsicSignaturePayloadFactory(extrinsicVersion: extrinsicVersion)

        return try signaturePayloadFactory.createPayload(
            from: implication,
            using: encodingFactory
        )
    }

    private func prepareSignaturePayload(
        implication: TransactionExtension.Implication,
        encodingFactory: DynamicScaleEncodingFactoryProtocol
    ) throws -> Data {
        switch signaturePayloadFormat {
        case .regular:
            return try prepareRegularSignaturePayload(implication: implication, encodingFactory: encodingFactory)
        case .paritySigner:
            return try prepareParitySignerSignaturePayload(implication: implication, encodingFactory: encodingFactory)
        case .extrinsicPayload:
            return try prepareNotHashedSignaturePayload(implication: implication, encodingFactory: encodingFactory)
        }
    }

    private func prepareV4SignedExtrinsic(
        account: JSON,
        signatureFactory: ExtrinsicSignatureFactoryProtocol,
        encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol
    ) throws -> Extrinsic {
        let implication = try prepareImplication(using: encodingFactory, metadata: metadata)
        let payload = try prepareSignaturePayload(implication: implication, encodingFactory: encodingFactory)

        let sigJson = try signatureFactory.createSignature(from: payload, context: runtimeJsonContext)

        let explicits = implication.explicits.toExtrinsicExplicits()
        let signature = ExtrinsicSignature(address: account, signature: sigJson, extra: explicits)
        let signed = Extrinsic.Signed(signature: signature, call: implication.call)

        return .signed(signed)
    }

    private func prepareV5SignedExtrinsic(
        extensionVersion: UInt8,
        encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol
    ) throws -> Extrinsic {
        let implication = try prepareImplication(using: encodingFactory, metadata: metadata)

        let explicits = implication.explicits.toExtrinsicExplicits()

        let general = Extrinsic.General(
            extensionVersion: extensionVersion,
            call: implication.call,
            explicits: explicits
        )

        return .generalTransaction(general)
    }

    private func prepareSignedExtrinsic(
        account: JSON,
        signatureFactory: ExtrinsicSignatureFactoryProtocol,
        encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol
    ) throws -> Extrinsic {
        switch extrinsicVersion {
        case .V4:
            return try prepareV4SignedExtrinsic(
                account: account,
                signatureFactory: signatureFactory,
                encodingFactory: encodingFactory,
                metadata: metadata
            )
        case let .V5(extensionVersion):
            let signingParams = TransactionExtension.VerifySignature.SigningParams(
                account: account
            )

            let verifySignature = TransactionExtension.VerifySignature(
                extrinsicVersion: extrinsicVersion,
                usability: .toSign(signatureFactory, signingParams)
            )

            transactionExtensions[Extrinsic.TransactionExtensionId.verifySignature] = verifySignature

            return try prepareV5SignedExtrinsic(
                extensionVersion: extensionVersion,
                encodingFactory: encodingFactory,
                metadata: metadata
            )
        }
    }

    private func setupOrCreateExtrinsic(
        using encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol
    ) throws -> Extrinsic {
        if let extrinsic {
            return extrinsic
        }

        switch extrinsicVersion {
        case let .V5(extensionVersion):
            let extrinsic = try prepareV5SignedExtrinsic(
                extensionVersion: extensionVersion,
                encodingFactory: encodingFactory,
                metadata: metadata
            )

            self.extrinsic = extrinsic

            return extrinsic
        case .V4:
            let call = try prepareTransactionCall(for: metadata)
            let bare = Extrinsic.Bare(extrinsicVersion: ExtrinsicConstants.legacyExtrinsicFormatVersion, call: call)
            return .bare(bare)
        }
    }
}

extension ExtrinsicBuilder: ExtrinsicBuilderProtocol {
    public func with<A: Codable>(address: A) throws -> Self {
        self.address = try address.toScaleCompatibleJSON(with: runtimeJsonContext?.toRawContext())

        return self
    }

    public func with(nonce: UInt32) -> Self {
        transactionExtensions[Extrinsic.TransactionExtensionId.nonce] = TransactionExtension.CheckNonce(nonce: nonce)

        return self
    }

    public func getNonce() -> UInt32? {
        let nonceExtension = transactionExtensions[Extrinsic.TransactionExtensionId.nonce] as? TransactionExtension.CheckNonce
        return nonceExtension?.nonce
    }

    public func with(era: Era, blockHash: String) -> Self {
        transactionExtensions[Extrinsic.TransactionExtensionId.mortality] = TransactionExtension.CheckMortality(
            era: era,
            blockHash: blockHash
        )

        return self
    }

    public func with(tip: BigUInt) -> Self {
        let txExtensionId = Extrinsic.TransactionExtensionId.txPayment
        transactionExtensions[txExtensionId] = TransactionExtension.ChargeTransactionPayment(
            tip: tip
        )

        return self
    }

    public func with(metadataHash: Data) -> Self {
        let txExtensionId = Extrinsic.TransactionExtensionId.checkMetadataHash
        transactionExtensions[txExtensionId] = TransactionExtension.CheckMetadataHash(
            mode: .enabled(metadataHash)
        )

        return self
    }

    public func with(signaturePayloadFormat: ExtrinsicSignaturePayloadFormat) -> Self {
        self.signaturePayloadFormat = signaturePayloadFormat
        return self
    }

    public func adding<T: RuntimeCallable>(call: T) throws -> Self {
        let json = try call.toScaleCompatibleJSON(with: runtimeJsonContext?.toRawContext())
        calls.append(json)

        return self
    }

    public func adding<T: RuntimeCallable>(call: T, at index: Int) throws -> Self {
        guard index <= calls.count else {
            throw ExtrinsicBuilderError.indexOutOfBounds
        }

        let json = try call.toScaleCompatibleJSON(with: runtimeJsonContext?.toRawContext())
        calls.insert(json, at: index)

        return self
    }

    public func adding(rawCall: Data) throws -> Self {
        let json = JSON.stringValue(rawCall.toHex())
        calls.append(json)

        return self
    }

    public func with(batchType: ExtrinsicBatch) -> Self {
        self.batchType = batchType

        return self
    }

    public func with(runtimeJsonContext: RuntimeJsonContext) -> Self {
        self.runtimeJsonContext = runtimeJsonContext

        return self
    }

    public func adding(transactionExtension: TransactionExtending) -> Self {
        transactionExtensions[transactionExtension.txExtensionId] = transactionExtension

        return self
    }

    public func wrappingCalls(for mapClosure: (JSON) throws -> JSON) throws -> Self {
        let newCalls = try calls.map { try mapClosure($0) }
        calls = newCalls
        return self
    }
    
    public func batchingCalls(with metadata: RuntimeMetadataProtocol) throws -> Self {
        let reducedCall = try prepareTransactionCall(for: metadata)
        
        calls = [reducedCall]
        
        return self
    }

    public func getCalls() -> [JSON] {
        calls
    }

    public func resetCalls() -> Self {
        calls = []
        return self
    }

    public func signing(
        by signer: @escaping (Data) throws -> Data,
        of type: CryptoType,
        using encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol
    ) throws -> Self {
        guard let account = address else {
            throw ExtrinsicBuilderError.missingAddress
        }

        extrinsic = try prepareSignedExtrinsic(
            account: account,
            signatureFactory: MultiSignatureExtrinsicFactory(signer: signer, cryptoType: type),
            encodingFactory: encodingFactory,
            metadata: metadata
        )

        return self
    }

    public func signing(
        by signer: @escaping (Data) throws -> JSON,
        using encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol
    ) throws -> Self {
        guard let account = address else {
            throw ExtrinsicBuilderError.missingAddress
        }

        extrinsic = try prepareSignedExtrinsic(
            account: account,
            signatureFactory: ClosureSignatureExtrinsicFactory(signer: signer),
            encodingFactory: encodingFactory,
            metadata: metadata
        )

        return self
    }

    public func buildRawSignature(
        using signer: @escaping (Data) throws -> Data,
        encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol
    ) throws -> Data {
        let implication = try prepareImplication(using: encodingFactory, metadata: metadata)
        let data = try prepareSignaturePayload(implication: implication, encodingFactory: encodingFactory)

        return try signer(data)
    }

    public func buildSignaturePayload(
        encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol
    ) throws -> Data {
        let implication = try prepareImplication(using: encodingFactory, metadata: metadata)
        return try prepareSignaturePayload(implication: implication, encodingFactory: encodingFactory)
    }
    
    public func buildExtrinsicSignatureParams(
        encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol
    ) throws -> ExtrinsicSignatureParams {
        let implication = try prepareImplication(using: encodingFactory, metadata: metadata)
        
        let callEncoder = encodingFactory.createEncoder()
        
        try callEncoder.append(json: implication.call, type: GenericType.call.name)
        
        let encodedCall = try callEncoder.encode()
        
        let extrinsicExtraEncoder = encodingFactory.createEncoder()
        
        for explicit in implication.explicits {
            try explicit.encode(to: extrinsicExtraEncoder)
        }
        
        let includedInExtrinsicExtra = try extrinsicExtraEncoder.encode()
        
        let signatureExtraEncoder = encodingFactory.createEncoder()
        
        for implicit in implication.implicits {
            try signatureExtraEncoder.appendRawData(implicit)
        }
        
        let includedInSignatureExtra = try signatureExtraEncoder.encode()
        
        return ExtrinsicSignatureParams(
            encodedCall: encodedCall,
            includedInExtrinsicExtra: includedInExtrinsicExtra,
            includedInSignatureExtra: includedInSignatureExtra
        )
    }

    public func build(
        using encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol
    ) throws -> Data {
        let extrinsic = try setupOrCreateExtrinsic(using: encodingFactory, metadata: metadata)

        let encoder = encodingFactory.createEncoder()

        try encoder.append(extrinsic, ofType: GenericType.extrinsic.name, with: runtimeJsonContext?.toRawContext())

        return try encoder.encode()
    }

    public func makeMemo() -> any ExtrinsicBuilderMemoProtocol {
        ExtrinsicBuilderMemo(
            extrinsicVersion: extrinsicVersion,
            extrinsic: extrinsic,
            address: address,
            calls: calls,
            transactionExtensions: transactionExtensions,
            signaturePayloadFormat: signaturePayloadFormat,
            runtimeJsonContext: runtimeJsonContext
        )
    }
}
