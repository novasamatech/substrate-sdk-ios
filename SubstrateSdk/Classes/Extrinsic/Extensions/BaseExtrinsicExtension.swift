import Foundation

public extension ExtrinsicExtension where Self: Codable {
    func setAdditionalExtra(to extraStore: inout ExtrinsicExtra, context: [CodingUserInfoKey: Any]?) {
        extraStore[Self.name] = try? self.toScaleCompatibleJSON(with: context)
    }
}
