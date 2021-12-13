import XCTest
@testable import SubstrateSdk

class JSONSubscriptionIdTests: XCTestCase {

    func testParsingSubscriptionResponseWithIntValue() {
        do {
            // given
            let actualValue: Int = 2595588254652828
            let data = "{\"jsonrpc\":\"2.0\",\"result\":\(actualValue),\"id\":123}".data(using: .utf8)!

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
            let actualValue: Int = 2595588254652828
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
            let actualValue: Int = 2595588254652828
            let data =
"""
{\"jsonrpc\":\"2.0\",\"method\":\"state_storage\",\"params\":{\"subscription\":\(actualValue), \"result\":{\"block\":\"0x1deed482cbed9cec67398ca222d073f99e36c48aeba7ebfb418135f7a81c9c87\",\"changes\":[[\"0x26aa394eea5630e07c48ae0c9558cef7b99d880ec681799c0cf30e8886371da9b82e146c42d93bbe2c219bbdfaf698482a1e637d38ab3279321e34f878cabc1fd411dd40d5fde3482601275ef189663c\",\"0x01000000000000007ae384e5ae0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000\"]]}}}
""".data(using: .utf8)!

            // when

            let response = try JSONDecoder().decode(JSONRPCSubscriptionUpdate<JSON>.self, from: data)

            // then

            XCTAssertEqual(response.params.subscription, "\(actualValue)")
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testParsingSubscriptionResponseWithStringValue() {
        do {
            // given
            let actualValue: String = "n6in3VIm96u3ABQE"
            let data = "{\"jsonrpc\":\"2.0\",\"result\":\"\(actualValue)\",\"id\":123}".data(using: .utf8)!

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
            let actualValue: String = "n6in3VIm96u3ABQE"
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
            let actualValue: String = "n6in3VIm96u3ABQE"
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
