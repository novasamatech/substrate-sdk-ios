import Foundation

public extension ExtrinsicSignedExtension {
    enum CheckMetadataHash {
        var name: String { Extrinsic.SignedExtensionId.checkMetadataHash.rawValue }
        
        case enabled(Data)
        case disabled
    }
}

public extension ExtrinsicSignedExtension.CheckMetadataHash: ExtrinsicSignedExtending {
    func setIncludedInExtrinsic(to extraStore: inout ExtrinsicExtra, context: [CodingUserInfoKey : Any]?) {
        switch self {
        case .enabled:
            extraStore[name] = .dictionaryValue(["mode": .arrayValue(["Enabled", JSON.null])])
        case .disabled:
            extraStore[name] = .dictionaryValue(["mode": .arrayValue(["Disabled", JSON.null])])
        }
    }
    
    func includeInSignature(encoder: DynamicScaleEncoding, context: [CodingUserInfoKey : Any]?) throws {
        switch self {
        case let .enabled(data):
            try encoder.appendCommonOption(isNull: false)
            try encoder.appendRawData(data)
        case .disabled:
            try encoder.appendCommonOption(isNull: true)
        }
    }
}
