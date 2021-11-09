import XCTest
import SubstrateSdk

class SubstrateQREncoderTests: XCTestCase {

    func testSuccessfullEncodingWithName() throws {
        let expectedData = try Data(hexString: "7375627374726174653a354633794b66354b7651343978356b346e5258624157674a485368516a51544245655a3950754e646d6562614e7837343a3078383432353834306636633337306637663264383239316333653639303436376530613866626238623036343866633964363439356439396463613763376133663a425642")

        let publicKey = try Data(hexString: "0x8425840f6c370f7f2d8291c3e690467e0a8fbb8b0648fc9d6495d99dca7c7a3f")
        let info = SubstrateQRInfo(prefix: SubstrateQR.prefix,
                                   address: "5F3yKf5KvQ49x5k4nRXbAWgJHShQjQTBEeZ9PuNdmebaNx74",
                                   rawPublicKey: publicKey,
                                   username: "BVB")

        let resultData = try SubstrateQREncoder().encode(info: info)

        XCTAssertEqual(expectedData, resultData)
    }

    func testSuccessfullEncodingWithoutName() throws {
        let expectedData = try Data(hexString: "7375627374726174653a354633794b66354b7651343978356b346e5258624157674a485368516a51544245655a3950754e646d6562614e7837343a307838343235383430663663333730663766326438323931633365363930343637653061386662623862303634386663396436343935643939646361376337613366")

        let publicKey = try Data(hexString: "0x8425840f6c370f7f2d8291c3e690467e0a8fbb8b0648fc9d6495d99dca7c7a3f")
        let info = SubstrateQRInfo(prefix: SubstrateQR.prefix,
                                   address: "5F3yKf5KvQ49x5k4nRXbAWgJHShQjQTBEeZ9PuNdmebaNx74",
                                   rawPublicKey: publicKey,
                                   username: nil)

        let resultData = try SubstrateQREncoder().encode(info: info)

        XCTAssertEqual(expectedData, resultData)
    }

    func testSuccessfullEncodingWithEthereumAddress() throws {
        let expectedData =  "7375627374726174653a3078396433333237323432303430646532353965653739336338313430613963326235333538313763353a3078303337363936333135626563623737323761613234313233313236366339366634626639333837383034363134636230326232633462623564313631396137643964"

        let publicKey = try Data(
            hexString: "0x037696315becb7727aa241231266c96f4bf9387804614cb02b2c4bb5d1619a7d9d"
        )

        let address = try publicKey.ethereumAddressFromPublicKey()

        let info = SubstrateQRInfo(prefix: SubstrateQR.prefix,
                                   address: address.toHex(includePrefix: true),
                                   rawPublicKey: publicKey,
                                   username: nil)

        let resultData = try SubstrateQREncoder().encode(info: info)

        XCTAssertEqual(expectedData, resultData.toHex())
    }
}
