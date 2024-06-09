import Foundation
import BigInt
import IrohaCrypto

public protocol ExtrinsicBuilderProtocol: AnyObject {
    func with<A: Codable>(address: A) throws -> Self
    func with(nonce: UInt32) -> Self
    func with(era: Era, blockHash: String) -> Self
    func with(tip: BigUInt) -> Self
    func with(metadataHash: Data) -> Self
    func with(batchType: ExtrinsicBatch) -> Self
    func with(runtimeJsonContext: RuntimeJsonContext) -> Self
    func with(signaturePayloadFormat: ExtrinsicSignaturePayloadFormat) -> Self
    func adding<T: RuntimeCallable>(call: T) throws -> Self
    func adding(rawCall: Data) throws -> Self
    func adding(extrinsicSignedExtension: ExtrinsicSignedExtending) -> Self
    func wrappingCalls(for mapClosure: (JSON) throws -> JSON) throws -> Self
    func getCalls() -> [JSON]
    func reset() -> Self
    func signing(by signer: (Data) throws -> Data,
                 of type: CryptoType,
                 using encoder: DynamicScaleEncoding,
                 metadata: RuntimeMetadataProtocol) throws -> Self

    func signing(
        by signer: (Data) throws -> JSON,
        using encoder: DynamicScaleEncoding,
        metadata: RuntimeMetadataProtocol
    ) throws -> Self

    func buildRawSignature(
        using signer: (Data) throws -> Data,
        encoder: DynamicScaleEncoding,
        metadata: RuntimeMetadataProtocol
    ) throws -> Data

    func buildSignaturePayload(
        encoder: DynamicScaleEncoding,
        metadata: RuntimeMetadataProtocol
    ) throws -> Data

    func build(encodingBy encoder: DynamicScaleEncoding, metadata: RuntimeMetadataProtocol) throws -> Data
}

public extension ExtrinsicBuilderProtocol {
    func with(shouldUseAtomicBatch: Bool) -> Self {
        with(batchType: shouldUseAtomicBatch ? .atomic : .untilFail)
    }
}

public enum ExtrinsicBuilderError: Error {
    case missingCall
    case missingNonce
    case missingAddress
    case unsupportedSignedExtension(_ value: String)
    case unsupportedBatch
}

public class ExtrinsicBuilder {
    private let specVersion: UInt32
    private let transactionVersion: UInt32
    private let genesisHash: String

    private var calls: [JSON]
    private var blockHash: String
    private var address: JSON?
    private var nonce: UInt32
    private var era: Era
    private var tip: BigUInt
    private var signature: ExtrinsicSignature?
    private var signaturePayloadFormat: ExtrinsicSignaturePayloadFormat = .regular
    private var metadataHash: Data?
    private var batchType: ExtrinsicBatch = .atomic
    private var runtimeJsonContext: RuntimeJsonContext?
    private var additionalExtensions: [ExtrinsicSignedExtending] = []

    public init(specVersion: UInt32,
                transactionVersion: UInt32,
                genesisHash: String) {
        self.specVersion = specVersion
        self.transactionVersion = transactionVersion
        self.genesisHash = genesisHash
        self.blockHash = genesisHash
        self.era = .immortal
        self.tip = 0
        self.nonce = 0
        self.calls = []
    }

    private func prepareExtrinsicCall(for metadata: RuntimeMetadataProtocol) throws -> JSON {
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

        let call = RuntimeCall(moduleName: KnowRuntimeModule.Utility.name,
                               callName: callName,
                               args: BatchArgs(calls: calls))

        guard metadata.getCall(from: call.moduleName, with: call.callName) != nil else {
            throw ExtrinsicBuilderError.unsupportedBatch
        }

        return try call.toScaleCompatibleJSON(with: runtimeJsonContext?.toRawContext())
    }
    
    private func getExtensions() -> [String: ExtrinsicSignedExtending] {
        var store = additionalExtensions.reduce(into: [String: ExtrinsicSignedExtending]()) { accum, item in
            accum[item.signedExtensionId] = item
        }
        
        let mortalityId = Extrinsic.SignedExtensionId.mortality.rawValue
        store[mortalityId] = ExtrinsicSignedExtension.CheckMortality(
            era: era,
            blockHash: blockHash
        )
        
        let checkGenesisId = Extrinsic.SignedExtensionId.genesis.rawValue
        store[checkGenesisId] = ExtrinsicSignedExtension.CheckGenesis(genesisHash: genesisHash)
        
        let checkTxVersionId = Extrinsic.SignedExtensionId.txVersion.rawValue
        store[checkTxVersionId] = ExtrinsicSignedExtension.CheckTxVersion(transactionVersion: transactionVersion)
        
        let checkSpecVersionId = Extrinsic.SignedExtensionId.specVersion.rawValue
        store[checkSpecVersionId] = ExtrinsicSignedExtension.CheckSpecVersion(specVersion: specVersion)
        
        let nonceId = Extrinsic.SignedExtensionId.nonce.rawValue
        store[nonceId] = ExtrinsicSignedExtension.CheckNonce(nonce: nonce)
        
        let txPaymentId = Extrinsic.SignedExtensionId.txPayment.rawValue
        store[txPaymentId] = ExtrinsicSignedExtension.ChargeTransactionPayment(tip: tip)
        
        let metadataHashId = Extrinsic.SignedExtensionId.checkMetadataHash.rawValue
        if let metadataHash = metadataHash {
            store[metadataHashId] = ExtrinsicSignedExtension.CheckMetadataHash(mode: .enabled(metadataHash))
        } else {
            store[metadataHashId] = ExtrinsicSignedExtension.CheckMetadataHash(mode: .disabled)
        }
        
        return store
    }

    private func createExtra() throws -> ExtrinsicExtra {
        var extra = ExtrinsicExtra()
    
        let signedExtensions = getExtensions()
        
        for signedExtension in signedExtensions.values {
            try signedExtension.setIncludedInExtrinsic(to: &extra, context: runtimeJsonContext?.toRawContext())
        }

        return extra
    }

    private func appendExtraToPayload(encodingBy encoder: DynamicScaleEncoding) throws {
        let extra = try createExtra()
        try encoder.append(extra, ofType: GenericType.extrinsicExtra.name, with: runtimeJsonContext?.toRawContext())
    }

    private func appendAdditionalSigned(
        encodingBy encoder: DynamicScaleEncoding,
        metadata: RuntimeMetadataProtocol
    ) throws {
        let signedExtensions = getExtensions()
        
        for checkString in metadata.getSignedExtensions() {
            try signedExtensions[checkString]?.includeInSignature(
                encoder: encoder,
                context: runtimeJsonContext?.toRawContext()
            )
        }
    }

    private func prepareParitySignerSignaturePayload(
        encodingBy encoder: DynamicScaleEncoding,
        using metadata: RuntimeMetadataProtocol
    ) throws -> Data {
        let call = try prepareExtrinsicCall(for: metadata)
        let callEncoder = encoder.newEncoder()
        try callEncoder.append(json: call, type: GenericType.call.name)

        let encodedCall = try callEncoder.encode()

        try encoder.append(encodable: encodedCall)

        try appendExtraToPayload(encodingBy: encoder)
        try appendAdditionalSigned(encodingBy: encoder, metadata: metadata)

        return try encoder.encode()
    }

    private func prepareRegularSignaturePayload(
        encodingBy encoder: DynamicScaleEncoding,
        using metadata: RuntimeMetadataProtocol
    ) throws -> Data {
        let payload = try prepareNotHashedSignaturePayload(encodingBy: encoder, using: metadata)
        return try ExtrinsicSignatureConverter.convertExtrinsicPayloadToRegular(payload)
    }

    private func prepareNotHashedSignaturePayload(
        encodingBy encoder: DynamicScaleEncoding,
        using metadata: RuntimeMetadataProtocol
    ) throws -> Data {
        let call = try prepareExtrinsicCall(for: metadata)
        try encoder.append(json: call, type: GenericType.call.name)

        try appendExtraToPayload(encodingBy: encoder)
        try appendAdditionalSigned(encodingBy: encoder, metadata: metadata)

        let payload = try encoder.encode()

        return payload
    }

    private func prepareSignaturePayload(
        encodingBy encoder: DynamicScaleEncoding,
        using metadata: RuntimeMetadataProtocol
    ) throws -> Data {
        switch signaturePayloadFormat {
        case .regular:
            return try prepareRegularSignaturePayload(encodingBy: encoder, using: metadata)
        case .paritySigner:
            return try prepareParitySignerSignaturePayload(encodingBy: encoder, using: metadata)
        case .extrinsicPayload:
            return try prepareNotHashedSignaturePayload(encodingBy: encoder, using: metadata)
        }
    }
}

extension ExtrinsicBuilder: ExtrinsicBuilderProtocol {
    public func with<A: Codable>(address: A) throws -> Self {
        self.address = try address.toScaleCompatibleJSON(with: runtimeJsonContext?.toRawContext())
        self.signature = nil

        return self
    }

    public func with(nonce: UInt32) -> Self {
        self.nonce = nonce
        self.signature = nil

        return self
    }

    public func with(era: Era, blockHash: String) -> Self {
        self.era = era
        self.blockHash = blockHash
        self.signature = nil

        return self
    }

    public func with(tip: BigUInt) -> Self {
        self.tip = tip
        self.signature = nil

        return self
    }
    
    public func with(metadataHash: Data) -> Self {
        self.metadataHash = metadataHash
        
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

    public func with(signaturePayloadFormat: ExtrinsicSignaturePayloadFormat) -> Self {
        self.signaturePayloadFormat = signaturePayloadFormat
        return self
    }

    public func adding<T: RuntimeCallable>(call: T) throws -> Self {
        let json = try call.toScaleCompatibleJSON(with: runtimeJsonContext?.toRawContext())
        calls.append(json)

        return self
    }

    public func adding(rawCall: Data) throws -> Self {
        let json = JSON.stringValue(rawCall.toHex())
        calls.append(json)

        return self
    }

    public func adding(extrinsicSignedExtension: ExtrinsicSignedExtending) -> Self {
        additionalExtensions.append(extrinsicSignedExtension)
        return self
    }

    public func wrappingCalls(for mapClosure: (JSON) throws -> JSON) throws -> Self {
        let newCalls = try calls.map { try mapClosure($0) }
        self.calls = newCalls
        return self
    }

    public func getCalls() -> [JSON] {
        calls
    }

    public func reset() -> Self {
        calls = []
        return self
    }

    public func signing(by signer: (Data) throws -> Data,
                        of type: CryptoType,
                        using encoder: DynamicScaleEncoding,
                        metadata: RuntimeMetadataProtocol) throws -> Self {
        guard let address = address else {
            throw ExtrinsicBuilderError.missingAddress
        }

        let data = try prepareSignaturePayload(encodingBy: encoder, using: metadata)

        let rawSignature = try signer(data)

        let signature: MultiSignature

        switch type {
        case .sr25519:
            signature = .sr25519(data: rawSignature)
        case .ed25519:
            signature = .ed25519(data: rawSignature)
        case .ecdsa:
            signature = .ecdsa(data: rawSignature)
        }

        let sigJson = try signature.toScaleCompatibleJSON(with: runtimeJsonContext?.toRawContext())

        let extra = try createExtra()
        self.signature = ExtrinsicSignature(address: address,
                                            signature: sigJson,
                                            extra: extra)

        return self
    }

    public func signing(
        by signer: (Data) throws -> JSON,
        using encoder: DynamicScaleEncoding,
        metadata: RuntimeMetadataProtocol
    ) throws -> Self {
        guard let address = address else {
            throw ExtrinsicBuilderError.missingAddress
        }

        let data = try prepareSignaturePayload(encodingBy: encoder, using: metadata)

        let sigJson = try signer(data)

        let extra = try createExtra()
        self.signature = ExtrinsicSignature(address: address, signature: sigJson, extra: extra)

        return self
    }

    public func buildRawSignature(
        using signer: (Data) throws -> Data,
        encoder: DynamicScaleEncoding,
        metadata: RuntimeMetadataProtocol
    ) throws -> Data {
        let data = try prepareSignaturePayload(encodingBy: encoder, using: metadata)

        return try signer(data)
    }

    public func buildSignaturePayload(
        encoder: DynamicScaleEncoding,
        metadata: RuntimeMetadataProtocol
    ) throws -> Data {
        try prepareSignaturePayload(encodingBy: encoder, using: metadata)
    }

    public func build(encodingBy encoder: DynamicScaleEncoding,
                      metadata: RuntimeMetadataProtocol) throws -> Data {
        let call = try prepareExtrinsicCall(for: metadata)

        let extrinsic = Extrinsic(signature: signature, call: call)

        try encoder.append(extrinsic, ofType: GenericType.extrinsic.name, with: runtimeJsonContext?.toRawContext())

        return try encoder.encode()
    }
}
