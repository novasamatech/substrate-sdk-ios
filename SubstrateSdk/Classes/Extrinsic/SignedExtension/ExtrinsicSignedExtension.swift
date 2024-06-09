import Foundation

public enum ExtrinsicSignedExtension {}

public protocol ExtrinsicSignedExtending {
    var signedExtensionId: String { get }

    func setIncludedInExtrinsic(to extraStore: inout ExtrinsicExtra, context: [CodingUserInfoKey: Any]?) throws
    func includeInSignature(encoder: DynamicScaleEncoding, context: [CodingUserInfoKey: Any]?) throws
}

public protocol OnlyExtrinsicSignedExtending: ExtrinsicSignedExtending {}

public extension OnlyExtrinsicSignedExtending {
    func includeInSignature(encoder: DynamicScaleEncoding, context: [CodingUserInfoKey: Any]?) throws {}
}

public extension OnlyExtrinsicSignedExtending where Self: Codable {
    func setIncludedInExtrinsic(to extraStore: inout ExtrinsicExtra, context: [CodingUserInfoKey: Any]?) {
        extraStore[signedExtensionId] = try? self.toScaleCompatibleJSON(with: context)
    }
}

public protocol OnlyExtrinsicSignatureExtending: ExtrinsicSignedExtending {}

public extension OnlyExtrinsicSignatureExtending {
    func setIncludedInExtrinsic(to extraStore: inout ExtrinsicExtra, context: [CodingUserInfoKey: Any]?) {}
}

public protocol ExtrinsicSignedExtensionCoding: AnyObject {
    var signedExtensionId: String { get }

    func decodeIncludedInExtrinsic(to extraStore: inout ExtrinsicExtra, decoder: DynamicScaleDecoding) throws
    func encodeIncludedInExtrinsic(from extra: ExtrinsicExtra, encoder: DynamicScaleEncoding) throws
}
