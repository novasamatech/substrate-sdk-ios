import NovaCrypto

public class BIP32ExtendedKeypair {
    let keypair: IRCryptoKeypairProtocol
    let chaincode: Data

    init(
        keypair: IRCryptoKeypairProtocol,
        chaincode: Data
    ) {
        self.keypair = keypair
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
