import BigInt

extension BigUInt {
    static let secp256k1CurveOrder =
        BigUInt("FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141", radix: 16)!
}
