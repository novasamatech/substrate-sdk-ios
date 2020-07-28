import Foundation

private let mnemonic = "bottom drive obey lake curtain smoke basket hold race lonely fit walk"

let sr25519Deriviation: [KeypairDeriviation] = [
    KeypairDeriviation(mnemonic: mnemonic,
                       publicKey: try! Data(hexString: "0x46ebddef8cd9bb167dc30878d7113b7e168e6f0646beffd77d69d39bad76b47a"),
                       path: ""),
    KeypairDeriviation(mnemonic: mnemonic,
                       publicKey: try! Data(hexString: "0xb69355deefa7a8f33e9297f5af22e680f03597a99d4f4b1c44be47e7a2275802"),
                       path: "///password"),
    KeypairDeriviation(mnemonic: mnemonic,
                       publicKey: try! Data(hexString: "0x40b9675df90efa6069ff623b0fdfcf706cd47ca7452a5056c7ad58194d23440a"),
                       path: "/foo"),
    KeypairDeriviation(mnemonic: mnemonic,
                       publicKey: try! Data(hexString: "0x547d4a55642ec7ebadc0bd29b6e570b8c926059b3c0655d4948075e9a7e6f31e"),
                       path: "//foo"),
    KeypairDeriviation(mnemonic: mnemonic,
                       publicKey: try! Data(hexString: "0x3841947ffcde6f5fef26fb68b59bb8665637e30e32ec2051f99cf6b9c674fe09"),
                       path: "//foo/bar"),
    KeypairDeriviation(mnemonic: mnemonic,
                       publicKey: try! Data(hexString: "0xdc142f7476a7b0aa262aeccf207f1d18daa90762db393006741e8a31f39dbc53"),
                       path: "/foo//bar"),
    KeypairDeriviation(mnemonic: mnemonic,
                       publicKey: try! Data(hexString: "0xa2e56b06407a6d1e819d2fc33fa0ec604b29c2e868b70b3696bb049b8725934b"),
                       path: "//foo/bar//42/69"),
    KeypairDeriviation(mnemonic: mnemonic,
                       publicKey: try! Data(hexString: "0x0e0d24e3e1ff2c07f269c99e2e0df8681fda1851ac42fc846ca2daaa90cd8f14"),
                       path: "//foo/bar//42/69///password"),
    KeypairDeriviation(mnemonic: mnemonic,
                       publicKey: try! Data(hexString: "0xd43593c715fdd31c61141abd04a99fd6822c8558854ccde39a5684e7a56da27d"),
                       path: "//Alice")
]
