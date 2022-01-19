import Foundation
import BigInt

public typealias ExtrinsicExtra = [String: JSON]

public enum KnownExtrinsicExtraKey {
    public static let era = "era"
    public static let nonce = "nonce"
    public static let tip = "tip"
}

public extension ExtrinsicExtra {
    mutating func setEra(_ era: Era?) throws {
        if let era = era {
            self[KnownExtrinsicExtraKey.era] = try era.toScaleCompatibleJSON(with: nil)
        } else {
            self[KnownExtrinsicExtraKey.era] = .null
        }
    }

    func getEra() -> Era? {
        guard let eraJson = self[KnownExtrinsicExtraKey.era] else {
            return nil
        }

        if case .null = eraJson {
            return nil
        }

        return try? eraJson.map(to: Era.self, with: nil)
    }

    mutating func setNonce(_ nonce: UInt32?) {
        if let nonce = nonce {
            self[KnownExtrinsicExtraKey.nonce] = .stringValue(String(nonce))
        } else {
            self[KnownExtrinsicExtraKey.nonce] = .null
        }
    }

    func getNonce() -> UInt32? {
        guard let nonceJson = self[KnownExtrinsicExtraKey.nonce] else {
            return nil
        }

        if case let .stringValue(value) = nonceJson {
            return UInt32(value)
        } else {
            return nil
        }
    }

    mutating func setTip(_ tip: BigUInt?) {
        if let tip = tip {
            self[KnownExtrinsicExtraKey.tip] = .stringValue(String(tip))
        } else {
            self[KnownExtrinsicExtraKey.nonce] = .null
        }
    }

    func getTip() -> BigUInt? {
        guard let tipJson = self[KnownExtrinsicExtraKey.tip] else {
            return nil
        }

        if case let .stringValue(value) = tipJson {
            return BigUInt(value)
        } else {
            return nil
        }
    }
}
