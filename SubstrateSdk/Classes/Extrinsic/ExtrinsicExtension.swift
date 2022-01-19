import Foundation

public protocol ExtrinsicExtension: AnyObject {
    var name: String { get }

    func setAdditionalExtra(to extraStore: inout ExtrinsicExtra)
    func readAdditionalExtra(to extraStore: inout ExtrinsicExtra, decoder: DynamicScaleDecoding) throws
    func writeAdditionalExtra(from extra: ExtrinsicExtra, encoder: DynamicScaleEncoding) throws
}
