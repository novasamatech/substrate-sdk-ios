import Foundation
import BigInt

public typealias ExtrinsicExtra = [String: JSON]

public extension ExtrinsicExtra {
    func getTip() -> BigUInt? {
        guard let tipJson = self[Extrinsic.TransactionExtensionId.txPayment] else {
            return nil
        }

        if case let .stringValue(value) = tipJson {
            return BigUInt(value)
        } else {
            return nil
        }
    }
    
    func getNonce() -> UInt32? {
        guard let nonceJson = self[Extrinsic.TransactionExtensionId.nonce] else {
            return nil
        }

        if case let .stringValue(value) = nonceJson {
            return UInt32(value)
        } else {
            return nil
        }
    }
    
    func getEra() -> Era? {
        guard let eraJson = self[Extrinsic.TransactionExtensionId.mortality] else {
            return nil
        }

        if case .null = eraJson {
            return nil
        }

        return try? eraJson.map(to: Era.self, with: nil)
    }
}
