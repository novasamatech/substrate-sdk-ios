import Foundation

public protocol ExtrinsicExtension: AnyObject {
    var name: String { get }

    func setAdditionalExtra(to extraStore: inout ExtrinsicExtra)
}

public protocol ExtrinsicExtensionCoder: AnyObject {
    var name: String { get }

    func decodeAdditionalExtra(to extraStore: inout ExtrinsicExtra, decoder: DynamicScaleDecoding) throws
    func encodeAdditionalExtra(from extra: ExtrinsicExtra, encoder: DynamicScaleEncoding) throws
}
