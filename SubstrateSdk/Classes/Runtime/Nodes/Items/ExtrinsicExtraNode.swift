import Foundation

public enum ExtrinsicExtraNodeError: Error {
    case invalidParams
}

public class ExtrinsicExtraNode: Node {
    static let defaultExtensions: [ExtrinsicSignedExtensionCoding] = [
        DefaultExtrinsicSignedExtensionCoder(
            signedExtensionId: Extrinsic.SignedExtensionId.mortality,
            extraType: GenericType.era.name
        ),
        
        CompactExtrinsicSignedExtensionCoder(
            signedExtensionId: Extrinsic.SignedExtensionId.nonce,
            extraType: KnownType.index.name
        ),
        
        CompactExtrinsicSignedExtensionCoder(
            signedExtensionId: Extrinsic.SignedExtensionId.txPayment,
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
            if let includer = coders[checkString] {
                try includer.encodeIncludedInExtrinsic(from: params, encoder: encoder)
            } else if let type = runtimeMetadata.getSignedExtensionType(for: checkString) {
                try? encoder.append(json: JSON.null, type: type)
            }
        }
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        let coders = getCoders()
        
        let extra = try runtimeMetadata.getSignedExtensions().reduce(into: [String: JSON]()) { (result, item) in
            if let coder = coders[item] {
                try coder.decodeIncludedInExtrinsic(to: &result, decoder: decoder)
            } else if let type = runtimeMetadata.getSignedExtensionType(for: item) {
                result[item] = try decoder.read(type: type)
            }
        }

        return .dictionaryValue(extra)
    }
}
