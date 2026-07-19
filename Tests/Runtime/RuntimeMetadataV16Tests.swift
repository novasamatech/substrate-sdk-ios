import XCTest
@testable import SubstrateSdk

final class RuntimeMetadataV16Tests: XCTestCase {
    func testPolkadotV16MetadataParsing() {
        performOpaqueV16MetadataTest(filename: "polkadot-v16-metadata")
    }

    func testWestendV16MetadataParsing() {
        performOpaqueV16MetadataTest(filename: "westend-v16-metadata")
    }

    func testViewFunctionLookupByName() {
        guard let metadata = loadV16Metadata(filename: "polkadot-v16-metadata") else {
            return
        }

        guard let query = metadata.getViewFunction(for: "Proxy", functionName: "is_superset") else {
            XCTFail("expected Proxy.is_superset view function")
            return
        }

        XCTAssertEqual(query.functionId.count, 32)

        let expectedPrefix = "Proxy".data(using: .utf8)!.twox128()
        XCTAssertEqual(query.functionId.prefix(16), expectedPrefix)

        XCTAssertEqual(query.function.name, "is_superset")
        XCTAssertEqual(query.function.inputs.count, 2)
        XCTAssertEqual(query.function.inputs.map(\.name), ["to_check", "against"])
        XCTAssertTrue(
            metadata.types.types.contains { $0.identifier == query.function.output },
            "expected output type to resolve in types registry"
        )
    }

    func testViewFunctionLookupReturnsNilForUnknownName() {
        guard let metadata = loadV16Metadata(filename: "polkadot-v16-metadata") else {
            return
        }

        XCTAssertNil(metadata.getViewFunction(for: "Proxy", functionName: "no_such_function"))
        XCTAssertNil(metadata.getViewFunction(for: "NoSuchPallet", functionName: "is_superset"))
    }

    func testViewFunctionLookupReturnsNilForPreV16Metadata() {
        guard let data = loadMetadataData(filename: "westend-v15-metadata") else {
            XCTFail("Can't load metadata file")
            return
        }

        do {
            let container = try RuntimeMetadataContainer.createFromOpaque(data: data)

            guard case let .v15(metadata) = container.runtimeMetadata else {
                XCTFail("unexpected metadata")
                return
            }

            XCTAssertNil(metadata.getViewFunction(for: "Proxy", functionName: "is_superset"))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testCommonLookupsOnV16Metadata() {
        for filename in ["polkadot-v16-metadata", "westend-v16-metadata"] {
            guard let metadata = loadV16Metadata(filename: filename) else {
                return
            }

            XCTAssertNotNil(metadata.getCall(from: "Balances", with: "transfer_keep_alive"), filename)
            XCTAssertNotNil(metadata.getStorageMetadata(in: "System", storageName: "Account"), filename)
            XCTAssertNotNil(metadata.getConstant(in: "Balances", constantName: "ExistentialDeposit"), filename)
            XCTAssertNotNil(metadata.getRuntimeApiMethod(for: "Metadata", methodName: "metadata_at_version"), filename)
            XCTAssertNotNil(
                metadata.getRuntimeApiMethod(
                    for: ViewFunctionQueryResult.executeApiName,
                    methodName: ViewFunctionQueryResult.executeMethodName
                ),
                filename
            )
            XCTAssertTrue(metadata.getSignedExtensions().contains("CheckNonce"), filename)
            XCTAssertNotNil(metadata.getSignedExtensionType(for: "CheckNonce"), filename)
        }
    }

    private func loadV16Metadata(filename: String) -> RuntimeMetadataV16? {
        guard let data = loadMetadataData(filename: filename) else {
            XCTFail("Can't load metadata file")
            return nil
        }

        do {
            let container = try RuntimeMetadataContainer.createFromOpaque(data: data)

            guard case let .v16(metadata) = container.runtimeMetadata else {
                XCTFail("unexpected metadata")
                return nil
            }

            return metadata
        } catch {
            XCTFail("Unexpected error: \(error)")
            return nil
        }
    }

    private func loadMetadataData(filename: String) -> Data? {
        let bundle: Bundle
#if SWIFT_PACKAGE
        bundle = Bundle.module
#else
        bundle = Bundle(for: type(of: self))
#endif

        guard let url = bundle.url(forResource: filename, withExtension: "") else {
            return nil
        }

        guard
            let hex = try? String(contentsOf: url)
                .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) else {
            return nil
        }

        return try? Data(hexString: hex)
    }

    private func performOpaqueV16MetadataTest(filename: String) {
        guard let expectedData = loadMetadataData(filename: filename) else {
            XCTFail("Can't load metadata file")
            return
        }

        do {
            let runtimeMetadataContainer = try RuntimeMetadataContainer.createFromOpaque(data: expectedData)

            guard case .v16 = runtimeMetadataContainer.runtimeMetadata else {
                XCTFail("unexpected metadata")
                return
            }

            let encoder = ScaleEncoder()
            try runtimeMetadataContainer.encode(scaleEncoder: encoder)
            let resultData = encoder.encode()

            XCTAssertNotNil(expectedData.range(of: resultData))
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
