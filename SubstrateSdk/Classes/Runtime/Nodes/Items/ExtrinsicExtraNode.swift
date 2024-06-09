import Foundation

public enum ExtrinsicExtraNodeError: Error {
    case invalidParams
}

public class ExtrinsicExtraNode: Node {
    static let defaultExtensions: [ExtrinsicSignedExtensionCoding] = [
        DefaultExtrinsicSignedExtensionCoder(
            signedExtensionId: Extrinsic.SignedExtensionId.mortality.rawValue,
            extraType: GenericType.era.name
        ),
        
        CompactExtrinsicSignedExtensionCoder(
            signedExtensionId: Extrinsic.SignedExtensionId.nonce.rawValue,
            extraType: KnownType.index.name
        ),
        
        CompactExtrinsicSignedExtensionCoder(
            signedExtensionId: Extrinsic.SignedExtensionId.txPayment.rawValue,
            extraType: KnownType.balance.name
        ),
        
        CheckMetadataHashCoder()
    ]
    
    public var typeName: String { GenericType.extrinsicExtra.name }
    public let runtimeMetadata: RuntimeMetadataProtocol
    public let customExtensions: [ExtrinsicSignedExtensionCoding]

    public init(
        runtimeMetadata: RuntimeMetadataProtocol,
        customExtensions: [ExtrinsicSignedExtensionCoding]
    ) {
        self.runtimeMetadata = runtimeMetadata
        self.customExtensions = customExtensions
    }
    
    private func getCoders() -> [String: ExtrinsicSignedExtensionCoding] {
        (Self.defaultExtensions + customExtensions).reduce(into: [String: ExtrinsicSignedExtensionCoding]()) {
            $0[$1.signedExtensionId] = $1
        }
    }

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        guard let params = value.dictValue else {
            throw DynamicScaleEncoderError.dictExpected(json: value)
        }

        let coders = getCoders()
        
        for checkString in runtimeMetadata.getSignedExtensions() {
            try coders[checkString]?.encodeIncludedInExtrinsic(from: params, encoder: encoder)
        }
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        let coders = getCoders()
        
        let extra = try runtimeMetadata.getSignedExtensions().reduce(into: [String: JSON]()) { (result, item) in
            try coders[item]?.decodeIncludedInExtrinsic(to: &result, decoder: decoder)
        }

        return .dictionaryValue(extra)
    }
}
