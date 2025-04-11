import Foundation
import BigInt

public enum ExtrinsicConstants {
    static let extrinsicFormatVersion: UInt8 = 5
    static let legacyExtrinsicFormatVersion: UInt8 = 4
    static let signedExtrinsicType: UInt8 = 1 << 7
    static let generalExtrinsicType: UInt8 = 1 << 6
    static let bareExtrinsicType: UInt8 = 0
    static let extrinsicTypeMask: UInt8 = 3 << 6
    static let extrinsicVersionMask: UInt8 = ~extrinsicTypeMask
}

public enum Extrinsic: Codable {
    public struct Signed: Codable {
        public let signature: ExtrinsicSignature
        public let call: JSON

        public init(signature: ExtrinsicSignature, call: JSON) {
            self.signature = signature
            self.call = call
        }
    }

    public struct General: Codable {
        public let extensionVersion: UInt8
        public let call: JSON
        public let explicits: ExtrinsicExtra

        public init(extensionVersion: UInt8, call: JSON, explicits: ExtrinsicExtra) {
            self.extensionVersion = extensionVersion
            self.call = call
            self.explicits = explicits
        }
    }

    public struct Bare: Codable {
        public let extrinsicVersion: UInt8
        public let call: JSON

        public init(extrinsicVersion: UInt8, call: JSON) {
            self.extrinsicVersion = extrinsicVersion
            self.call = call
        }
    }

    case bare(Bare)
    case signed(Signed)
    case generalTransaction(General)

    public func getSignedExtrinsic() -> Signed? {
        switch self {
        case .bare, .generalTransaction:
            nil
        case let .signed(signed):
            signed
        }
    }

    public func getBareExtrinsic() -> Bare? {
        switch self {
        case let .bare(bare):
            return bare
        case .generalTransaction, .signed:
            return nil
        }
    }
}

public extension Extrinsic {
    enum Version {
        case V4
        case V5(extensionVersion: UInt8)
    }
}
