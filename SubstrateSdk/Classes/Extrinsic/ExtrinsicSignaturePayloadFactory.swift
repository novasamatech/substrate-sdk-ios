import Foundation

public protocol ExtrinsicSignaturePayloadFactoryProtocol {
    func createPayload(
        from implication: TransactionExtension.Implication,
        using encodingFactory: DynamicScaleEncodingFactoryProtocol
    ) throws -> Data
}

public final class ExtrinsicSignaturePayloadFactory {
    // New tx pipeline always requires version byte
    // This is a fallback for v4 extrinsics
    static let v4ExtrinsicVersion: UInt8 = 0
    
    public enum Mode {
        case txExtensionPipeline
        case extrinsicSignature
    }
    
    let extrinsicVersion: Extrinsic.Version
    let mode: Mode

    public init(extrinsicVersion: Extrinsic.Version, mode: Mode) {
        self.extrinsicVersion = extrinsicVersion
        self.mode = mode
    }
}

private extension ExtrinsicSignaturePayloadFactory {
    func appendV4VersionIfNeeded(into encoder: DynamicScaleEncoding) throws {
        switch mode {
        case .txExtensionPipeline:
            try encoder.append(encodable: Self.v4ExtrinsicVersion)
        case .extrinsicSignature:
            break
        }
    }
}

extension ExtrinsicSignaturePayloadFactory: ExtrinsicSignaturePayloadFactoryProtocol {
    public func createPayload(
        from implication: TransactionExtension.Implication,
        using encodingFactory: DynamicScaleEncodingFactoryProtocol
    ) throws -> Data {
        let encoder = encodingFactory.createEncoder()

        switch extrinsicVersion {
        case let .V5(extensionVersion):
            try encoder.append(encodable: extensionVersion)
        case .V4:
            try appendV4VersionIfNeeded(into: encoder)
        }

        try encoder.append(json: implication.call, type: GenericType.call.name)

        try implication.explicits.forEach { explicit in
            try explicit.encode(to: encoder)
        }

        try implication.implicits.forEach { implicit in
            try encoder.appendRawData(implicit)
        }

        return try encoder.encode()
    }
}
