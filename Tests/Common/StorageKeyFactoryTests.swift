import XCTest
import FearlessUtils

class StorageKeyFactoryTests: XCTestCase {

    func testBlake128ConcatKeyCreation() throws {
        let factory = StorageKeyFactory()

        let identifier = try Data(hexString: "8ad2a3fba73321961cd5d1b8272aa95a21e75dd5b098fb36ed996961ac7b2931")

        let expectedKey = try Data(hexString: "0x26aa394eea5630e07c48ae0c9558cef7b99d880ec681799c0cf30e8886371da9d14d49c37bcc0afd3d9093917c6d46ea8ad2a3fba73321961cd5d1b8272aa95a21e75dd5b098fb36ed996961ac7b2931")

        let key = try factory.createStorageKey(moduleName: "System",
                                               storageName: "Account",
                                               key: identifier,
                                               hasher: .blake128Concat)

        XCTAssertEqual(key, expectedKey)
    }

    func testTwox64ConcatKeyCreation() throws {
        let factory = StorageKeyFactory()

        let identifier = try Data(hexString: "8ad2a3fba73321961cd5d1b8272aa95a21e75dd5b098fb36ed996961ac7b2931")

        let expectedKey = try Data(hexString: "0x5f3e4907f716ac89b6347d15ececedca3ed14b45ed20d054f05e37e2542cfe70c18acca30c9341bf8ad2a3fba73321961cd5d1b8272aa95a21e75dd5b098fb36ed996961ac7b2931")

        let key = try factory.createStorageKey(moduleName: "Staking",
                                               storageName: "Bonded",
                                               key: identifier,
                                               hasher: .twox64Concat)

        XCTAssertEqual(key, expectedKey)
    }

    func testIdentityKeyCreation() throws {
        let factory = StorageKeyFactory()

        let key = try Data(hexString: "0x086650c6a3966e8179e5213fdb8bcc01b109d82d58c492c6f2c198f4237ec3cb")

        let expectedKey = try Data(hexString: "0xf2794c22e353e9a839f12faab03a911be6e976fedc31c7b8cf73483554bd2be2086650c6a3966e8179e5213fdb8bcc01b109d82d58c492c6f2c198f4237ec3cb")

        let storageKey = try factory.createStorageKey(moduleName: "Democracy",
                                                      storageName: "Cancellations",
                                                      key: key,
                                                      hasher: .identity)

        XCTAssertEqual(storageKey, expectedKey)
    }
}
