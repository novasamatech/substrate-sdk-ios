import XCTest
import FearlessUtils
import IrohaCrypto

class KeystoreBuilderTests: XCTestCase {
    func testOnSr25519Json() {
        guard let url = Bundle(for: KeystoreExtractorTests.self)
            .url(forResource: "keystore-sr25519", withExtension: "json") else {
            XCTFail("Can't find resource")
            return
        }

        do {
            let testData = try Data(contentsOf: url)
            performTestForData(testData, password: "test5")
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testOnEd25519Json() {
        guard let url = Bundle(for: KeystoreExtractorTests.self)
            .url(forResource: "keystore-ed25519", withExtension: "json") else {
            XCTFail("Can't find resource")
            return
        }

        do {
            let testData = try Data(contentsOf: url)
            performTestForData(testData, password: "test2")
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testOnEcdsaJson() {
        guard let url = Bundle(for: KeystoreExtractorTests.self)
            .url(forResource: "keystore-ecdsa", withExtension: "json") else {
            XCTFail("Can't find resource")
            return
        }

        do {
            let testData = try Data(contentsOf: url)
            performTestForData(testData, password: "test3")
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    // MARK: Private

    private func performTestForData(_ testData: Data, password: String) {
        do {
            let definition = try JSONDecoder().decode(KeystoreDefinition.self, from: testData)

            let extractor = KeystoreExtractor()

            let expectedKeystoreData = try extractor.extractFromDefinition(definition,
                                                                           password: password)

            var builder = KeystoreBuilder()

            if let name = definition.meta?.name {
                builder = builder.with(name: name)
            }

            if let creationTimestamp = definition.meta?.createdAt {
                builder = builder.with(creationDate: Date(timeIntervalSince1970: TimeInterval(creationTimestamp)))
            }

            let resultDefinition = try builder.build(from: expectedKeystoreData, password: password)

            let resultKeystoreData = try extractor.extractFromDefinition(resultDefinition, password: password)

            XCTAssertEqual(expectedKeystoreData, resultKeystoreData)
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
}
