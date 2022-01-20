import Foundation
import BigInt
import IrohaCrypto

public protocol ExtrinsicBuilderProtocol: AnyObject {
    func with<A: Codable>(address: A) throws -> Self
    func with(nonce: UInt32) -> Self
    func with(era: Era, blockHash: String) -> Self
    func with(tip: BigUInt) -> Self
    func with(shouldUseAtomicBatch: Bool) -> Self
    func with(runtimeJsonContext: RuntimeJsonContext) -> Self
    func adding<T: RuntimeCallable>(call: T) throws -> Self
    func adding(rawCall: Data) throws -> Self
    func adding(extrinsicExtension: ExtrinsicExtension) -> Self
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

public enum ExtrinsicBuilderError: Error {
    case missingCall
    case missingNonce
    case missingAddress
    case unsupportedSignedExtension(_ value: String)
    case unsupportedBatch
}

public final class ExtrinsicBuilder {
    static let payloadHashingTreshold = 256

    struct InternalCall: Codable {
        let moduleName: String
        let callName: String
        let args: JSON
    }

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
    private var shouldUseAtomicBatch: Bool = true
    private var runtimeJsonContext: RuntimeJsonContext?
    private var additionalExtensions: [ExtrinsicExtension] = []

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

        let callName = shouldUseAtomicBatch ? KnowRuntimeModule.Utitlity.batchAll : KnowRuntimeModule.Utitlity.batch

        let call = RuntimeCall(moduleName: KnowRuntimeModule.Utitlity.name,
                               callName: callName,
                               args: BatchArgs(calls: calls))

        guard metadata.getCall(from: call.moduleName, with: call.callName) != nil else {
            throw ExtrinsicBuilderError.unsupportedBatch
        }

        return try call.toScaleCompatibleJSON(with: runtimeJsonContext?.toRawContext())
    }

    private func createExtra() throws -> ExtrinsicExtra {
        var extra = ExtrinsicExtra()
        try extra.setEra(era)
        extra.setNonce(nonce)
        extra.setTip(tip)

        for extrinsicExtension in additionalExtensions {
            extrinsicExtension.setAdditionalExtra(to: &extra, context: runtimeJsonContext?.toRawContext())
        }

        return extra
    }

    private func appendExtraToPayload(encodingBy encoder: DynamicScaleEncoding) throws {
        let extra = try createExtra()
        try encoder.append(extra, ofType: GenericType.extrinsicExtra.name, with: runtimeJsonContext?.toRawContext())
    }

    private func appendAdditionalSigned(encodingBy encoder: DynamicScaleEncoding,
                                        metadata: RuntimeMetadataProtocol) throws {
        for checkString in metadata.getSignedExtensions() {
            guard let check = ExtrinsicCheck(rawValue: checkString) else {
                continue
            }

            switch check {
            case .genesis:
                try encoder.appendBytes(json: .stringValue(genesisHash))
            case .mortality:
                try encoder.appendBytes(json: .stringValue(blockHash))
            case .specVersion:
                try encoder.append(encodable: specVersion)
            case .txVersion:
                try encoder.append(encodable: transactionVersion)
            default:
                continue
            }
        }
    }

    private func prepareSignaturePayload(encodingBy encoder: DynamicScaleEncoding,
                                         using metadata: RuntimeMetadataProtocol) throws -> Data {
        let call = try prepareExtrinsicCall(for: metadata)
        try encoder.append(json: call, type: GenericType.call.name)

        try appendExtraToPayload(encodingBy: encoder)
        try appendAdditionalSigned(encodingBy: encoder, metadata: metadata)

        let payload = try encoder.encode()

        return payload.count > Self.payloadHashingTreshold ? (try payload.blake2b32()) : payload
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

    public func with(shouldUseAtomicBatch: Bool) -> Self {
        self.shouldUseAtomicBatch = shouldUseAtomicBatch
        return self
    }

    public func with(runtimeJsonContext: RuntimeJsonContext) -> Self {
        self.runtimeJsonContext = runtimeJsonContext
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

    public func adding(extrinsicExtension: ExtrinsicExtension) -> Self {
        additionalExtensions.append(extrinsicExtension)
        return self
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
