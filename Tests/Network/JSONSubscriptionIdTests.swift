import XCTest
@testable import SubstrateSdk

class JSONSubscriptionIdTests: XCTestCase {

    func testParsingSubscriptionResponseWithIntValue() {
        do {
            // given
            let actualValue: Int = 4116100730548372
            let data = "{\"jsonrpc\":\"2.0\",\"result\":\(actualValue),\"id\":57265}".data(using: .utf8)!

            // when

            let response = try JSONDecoder().decode(JSONRPCData<JSONRPCSubscriptionId>.self, from: data)

            // then

            XCTAssertEqual(response.result.wrappedValue, "\(actualValue)")
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testParsingSubscriptionBasicUpdateWithIntValue() {
        do {
            // given
            let actualValue: Int = 4116100730548372
            let data =
"""
{\"jsonrpc\":\"2.0\",\"method\":\"state_storage\",\"params\":{\"subscription\":\(actualValue),\"result\":{\"block\":\"0xa4cfe7a61fd0a960145ab564c1b030daa767e0f347dc5256b6f724d2a01e7487\"}}}
""".data(using: .utf8)!

            // when

            let response = try JSONDecoder().decode(JSONRPCSubscriptionBasicUpdate.self, from: data)

            // then

            XCTAssertEqual(response.params.subscription, "\(actualValue)")
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testParsingSubscriptionActualUpdateWithIntValue() {
        do {
            // given
            let actualValue: Int = 4116100730548372
            let data =
"""
{\"jsonrpc\":\"2.0\",\"method\":\"state_storage\",\"params\":{\"subscription\":\(actualValue),\"result\":{\"block\":\"0xa4cfe7a61fd0a960145ab564c1b030daa767e0f347dc5256b6f724d2a01e7487\"}}}
""".data(using: .utf8)!

            // when

            let response = try JSONDecoder().decode(JSONRPCSubscriptionUpdate<[String: String]>.self, from: data)

            // then

            XCTAssertEqual(response.params.subscription, "\(actualValue)")
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testParsingSubscriptionResponseWithStringValue() {
        do {
            // given
            let actualValue: String = "uTNBXBfU4QViGdEQ"
            let data = "{\"jsonrpc\":\"2.0\",\"result\":\"\(actualValue)\",\"id\":57265}".data(using: .utf8)!

            // when

            let response = try JSONDecoder().decode(JSONRPCData<JSONRPCSubscriptionId>.self, from: data)

            // then

            XCTAssertEqual(response.result.wrappedValue, "\(actualValue)")
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testParsingSubscriptionBasicUpdateWithStringValue() {
        do {
            // given
            let actualValue: String = "uTNBXBfU4QViGdEQ"
            let data =
"""
{\"jsonrpc\":\"2.0\",\"method\":\"state_storage\",\"params\":{\"subscription\":\"\(actualValue)\",\"result\":{\"block\":\"0xa4cfe7a61fd0a960145ab564c1b030daa767e0f347dc5256b6f724d2a01e7487\"}}}
""".data(using: .utf8)!

            // when

            let response = try JSONDecoder().decode(JSONRPCSubscriptionBasicUpdate.self, from: data)

            // then

            XCTAssertEqual(response.params.subscription, "\(actualValue)")
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testParsingSubscriptionActualUpdateWithStringValue() {
        do {
            // given
            let actualValue: String = "uTNBXBfU4QViGdEQ"
            let data =
"""
{\"jsonrpc\":\"2.0\",\"method\":\"state_storage\",\"params\":{\"subscription\":\"\(actualValue)\",\"result\":{\"block\":\"0xa4cfe7a61fd0a960145ab564c1b030daa767e0f347dc5256b6f724d2a01e7487\"}}}
""".data(using: .utf8)!

            // when

            let response = try JSONDecoder().decode(JSONRPCSubscriptionUpdate<[String: String]>.self, from: data)

            // then

            XCTAssertEqual(response.params.subscription, "\(actualValue)")
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
}
