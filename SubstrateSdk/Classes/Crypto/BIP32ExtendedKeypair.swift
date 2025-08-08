import NovaCrypto

public class BIP32ExtendedKeypair {
    let keypair: IRCryptoKeypairProtocol
    let nextSeed: Data
    let chaincode: Data

    init(
        keypair: IRCryptoKeypairProtocol,
        nextSeed: Data,
        chaincode: Data
    ) {
        self.keypair = keypair
        self.nextSeed = nextSeed
        self.chaincode = chaincode
    }
}

extension BIP32ExtendedKeypair: IRCryptoKeypairProtocol {
    public func publicKey() -> IRPublicKeyProtocol {
        keypair.publicKey()
    }

    public func privateKey() -> IRPrivateKeyProtocol {
        keypair.privateKey()
    }
}
