import Foundation

public final class ParitySignerSignaturePayloadFactory {
    let extrinsicVersion: Extrinsic.Version
    
    public init(extrinsicVersion: Extrinsic.Version) {
        self.extrinsicVersion = extrinsicVersion
    }
}

extension ParitySignerSignaturePayloadFactory: ExtrinsicSignaturePayloadFactoryProtocol {
    public func createPayload(
        from implication: TransactionExtension.Implication,
        using encodingFactory: DynamicScaleEncodingFactoryProtocol
    ) throws -> Data {
        let encoder = encodingFactory.createEncoder()
        
        switch extrinsicVersion {
        case let .V5(extensionVersion):
            try encoder.append(encodable: extensionVersion)
        case .V4:
            break
        }
        
        let callEncoder = encoder.newEncoder()
        try callEncoder.append(json: implication.call, type: GenericType.call.name)
        
        let encodedCall = try callEncoder.encode()
        
        try encoder.append(encodable: encodedCall)
        
        try implication.explicits.forEach { explicit in
            try explicit.encode(to: encoder)
        }
        
        try implication.implicits.forEach { implicit in
            try encoder.appendRawData(implicit)
        }
        
        return try encoder.encode()
    }
}
