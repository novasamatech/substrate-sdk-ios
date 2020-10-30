import XCTest
import FearlessUtils

class StorageKeyFactoryTests: XCTestCase {

    func testBlake128ConcatKeyCreation() throws {
        let factory = StorageKeyFactory()

        let identifier = try Data(hexString: "8ad2a3fba73321961cd5d1b8272aa95a21e75dd5b098fb36ed996961ac7b2931")

        let expectedKey = try Data(hexString: "0x26aa394eea5630e07c48ae0c9558cef7b99d880ec681799c0cf30e8886371da9d14d49c37bcc0afd3d9093917c6d46ea8ad2a3fba73321961cd5d1b8272aa95a21e75dd5b098fb36ed996961ac7b2931")

        let key = try factory.createStorageKey(moduleName: "System",
                                               serviceName: "Account",
                                               identifier: identifier,
                                               hasher: Blake128Concat())

        XCTAssertEqual(key, expectedKey)
    }

    func testTwox64ConcatKeyCreation() throws {
        let factory = StorageKeyFactory()

        let identifier = try Data(hexString: "8ad2a3fba73321961cd5d1b8272aa95a21e75dd5b098fb36ed996961ac7b2931")

        let expectedKey = try Data(hexString: "0x5f3e4907f716ac89b6347d15ececedca3ed14b45ed20d054f05e37e2542cfe70c18acca30c9341bf8ad2a3fba73321961cd5d1b8272aa95a21e75dd5b098fb36ed996961ac7b2931")

        let key = try factory.createStorageKey(moduleName: "Staking",
                                               serviceName: "Bonded",
                                               identifier: identifier,
                                               hasher: Twox64Concat())

        XCTAssertEqual(key, expectedKey)
    }
}
