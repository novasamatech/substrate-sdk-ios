import Foundation
import BigInt
import IrohaCrypto

public protocol ExtrinsicBuilderProtocol: class {
    func with<A: Codable>(address: A) throws -> Self
    func with(nonce: UInt32) -> Self
    func with(era: Era, blockHash: String) -> Self
    func with(tip: BigUInt) -> Self
    func adding<T: RuntimeCallable>(call: T) throws -> Self

    func signing(by signer: (Data) throws -> Data,
                 of type: CryptoType,
                 using encoder: DynamicScaleEncoding,
                 metadata: RuntimeMetadata) throws -> Self

    func build(encodingBy encoder: DynamicScaleEncoding, metadata: RuntimeMetadata) throws -> Data
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
    private var nonce: UInt32?
    private var era: Era
    private var tip: BigUInt
    private var signature: ExtrinsicSignature?

    public init(specVersion: UInt32,
                transactionVersion: UInt32,
                genesisHash: String) {
        self.specVersion = specVersion
        self.transactionVersion = transactionVersion
        self.genesisHash = genesisHash
        self.blockHash = genesisHash
        self.era = .immortal
        self.tip = 0
        self.calls = []
    }

    private func prepareExtrinsicCall(for metadata: RuntimeMetadata) throws -> JSON {
        guard !calls.isEmpty else {
            throw ExtrinsicBuilderError.missingCall
        }

        guard calls.count > 1 else {
            return calls[0]
        }

        let call = RuntimeCall(moduleName: KnowRuntimeModule.Utitlity.name,
                               callName: KnowRuntimeModule.Utitlity.batch,
                               args: BatchArgs(calls: calls))

        guard metadata.getFunction(from: call.moduleName, with: call.callName) != nil else {
            throw ExtrinsicBuilderError.unsupportedBatch
        }

        return try call.toScaleCompatibleJSON()
    }

    private func appendExtraToPayload(encodingBy encoder: DynamicScaleEncoding) throws {
        let extra = ExtrinsicSignedExtra(era: era, nonce: nonce ?? 0, tip: tip)
        try encoder.append(extra, ofType: GenericType.extrinsicExtra.name)
    }

    private func appendAdditionalSigned(encodingBy encoder: DynamicScaleEncoding,
                                        metadata: RuntimeMetadata) throws {
        for checkString in metadata.extrinsic.signedExtensions {
            guard let check = ExtrinsicCheck(rawValue: checkString) else {
                throw ExtrinsicBuilderError.unsupportedSignedExtension(checkString)
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
                                         using metadata: RuntimeMetadata) throws -> Data {
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
        self.address = try address.toScaleCompatibleJSON()
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

    public func adding<T: RuntimeCallable>(call: T) throws -> Self {
        let json = try call.toScaleCompatibleJSON()
        calls.append(json)

        return self
    }

    public func signing(by signer: (Data) throws -> Data,
                        of type: CryptoType,
                        using encoder: DynamicScaleEncoding,
                        metadata: RuntimeMetadata) throws -> Self {
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

        let sigJson = try signature.toScaleCompatibleJSON()

        let extra = ExtrinsicSignedExtra(era: era, nonce: nonce ?? 0, tip: tip)
        self.signature = ExtrinsicSignature(address: address,
                                            signature: sigJson,
                                            extra: extra)

        return self
    }

    public func build(encodingBy encoder: DynamicScaleEncoding,
                      metadata: RuntimeMetadata) throws -> Data {
        let call = try prepareExtrinsicCall(for: metadata)

        let extrinsic = Extrinsic(signature: signature, call: call)

        try encoder.append(extrinsic, ofType: GenericType.extrinsic.name)

        return try encoder.encode()
    }
}
