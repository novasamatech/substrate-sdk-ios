import Foundation

struct GenericTransaction: Codable {
    let version: UInt8
    let call: JSON
    let explicits: ExtrinsicExtra // TODO: Check if we need a separate type
}
