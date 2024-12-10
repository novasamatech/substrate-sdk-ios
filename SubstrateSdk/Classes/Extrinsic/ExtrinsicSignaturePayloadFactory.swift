import Foundation

public protocol ExtrinsicSignaturePayloadFactoryProtocol {
    func createPayload(
        from implication: TransactionExtension.Implication,
        using encodingFactory: DynamicScaleEncodingFactoryProtocol
    ) throws -> Data
}

public final class ExtrinsicSignaturePayloadFactory {
    let extrinsicVersion: Extrinsic.Version
    
    public init(extrinsicVersion: Extrinsic.Version) {
        self.extrinsicVersion = extrinsicVersion
    }
}

extension ExtrinsicSignaturePayloadFactory: ExtrinsicSignaturePayloadFactoryProtocol {
    public func createPayload(
        from implication: TransactionExtension.Implication,
        using encodingFactory: DynamicScaleEncodingFactoryProtocol
    ) throws -> Data {
        let encoder = try encodingFactory.createEncoder()
        
        switch extrinsicVersion {
        case let .V5(extensionVersion):
            try encoder.append(encodable: extensionVersion)
        case .V4:
            break
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
