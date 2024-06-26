import Foundation

public extension ExtrinsicSignedExtension {
    struct CheckMetadataHash {
        public enum Mode {
            case enabled(Data)
            case disabled
        }
        
        public var signedExtensionId: String { Extrinsic.SignedExtensionId.checkMetadataHash }
        
        public let mode: Mode
        
        public init(mode: Mode) {
            self.mode = mode
        }
    }
}

extension ExtrinsicSignedExtension.CheckMetadataHash: ExtrinsicSignedExtending {
    public func setIncludedInExtrinsic(to extraStore: inout ExtrinsicExtra, context: [CodingUserInfoKey: Any]?) {
        switch mode {
        case .enabled:
            extraStore[signedExtensionId] = JSON.stringValue("1")
        case .disabled:
            extraStore[signedExtensionId] = JSON.stringValue("0")
        }
    }
    
    public func includeInSignature(encoder: DynamicScaleEncoding, context: [CodingUserInfoKey: Any]?) throws {
        switch mode {
        case let .enabled(data):
            try encoder.appendCommonOption(isNull: false)
            try encoder.appendRawData(data)
        case .disabled:
            try encoder.appendCommonOption(isNull: true)
        }
    }
}


public final class CheckMetadataHashCoder: ExtrinsicSignedExtensionCoding {
    public var signedExtensionId: String { Extrinsic.SignedExtensionId.checkMetadataHash }
    
    public func encodeIncludedInExtrinsic(from extra: ExtrinsicExtra, encoder: DynamicScaleEncoding) throws {
        guard let index = extra[signedExtensionId] else {
            return
        }
        
        // the Mode type used for metadata hash is actually a enum but it encoded as u8
        try encoder.appendU8(json: index)
    }
    
    public func decodeIncludedInExtrinsic(to extraStore: inout ExtrinsicExtra, decoder: DynamicScaleDecoding) throws {
        let isEnabled = try decoder.readU8()
        extraStore[signedExtensionId] = isEnabled
    }
}
