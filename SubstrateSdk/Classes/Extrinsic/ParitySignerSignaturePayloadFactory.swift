import Foundation

public final class ParitySignerSignaturePayloadFactory {
    let formatVersion: Extrinsic.FormatVersion

    public init(formatVersion: Extrinsic.FormatVersion) {
        self.formatVersion = formatVersion
    }
}

extension ParitySignerSignaturePayloadFactory: ImplicationSignaturePayloadFactoryProtocol {
    public func createPayload(
        from implication: TransactionExtension.Implication,
        using encodingFactory: DynamicScaleEncodingFactoryProtocol
    ) throws -> Data {
        let encoder = encodingFactory.createEncoder()

        switch formatVersion {
        case .V5:
            try encoder.append(encodable: implication.extensionVersion)
        case .V4:
            break
        }

        let callEncoder = encoder.newEncoder()
        try callEncoder.append(json: implication.call, type: GenericType.call.name)

        let encodedCall = try callEncoder.encode()

        try encoder.append(encodable: encodedCall)

        try implication.explicits.forEach { explicit in
            try explicit.encode(to: encoder, extensionVersion: implication.extensionVersion)
        }

        try implication.implicits.forEach { implicit in
            try encoder.appendRawData(implicit)
        }

        return try encoder.encode()
    }
}
