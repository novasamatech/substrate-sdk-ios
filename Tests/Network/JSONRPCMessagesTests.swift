import Testing
import Foundation
@testable import SubstrateSdk

@Suite("JSONRPCMessages")
struct JSONRPCMessagesTests {
    private func jsonObject(_ data: Data) throws -> [String: Any] {
        let object = try JSONSerialization.jsonObject(with: data)
        return try #require(object as? [String: Any])
    }

    @Test("request envelope encodes numeric and string ids in their wire type")
    func requestEnvelopeEncodesIdTypes() throws {
        let numeric = JSONRPCRequestEnvelope(id: .number(7), method: "m", params: [1])
        let string = JSONRPCRequestEnvelope(id: .string("a-1"), method: "m", params: [1])

        let numericObject = try jsonObject(JSONEncoder().encode(numeric))
        let stringObject = try jsonObject(JSONEncoder().encode(string))

        #expect(numericObject["id"] as? UInt64 == 7)
        #expect(stringObject["id"] as? String == "a-1")
        #expect(numericObject["jsonrpc"] as? String == "2.0")
    }

    @Test("request envelope with nil id omits the id member (notification)")
    func requestEnvelopeOmitsNilId() throws {
        let notification = JSONRPCRequestEnvelope<[Int]>(id: nil, method: "m", params: nil)

        let object = try jsonObject(JSONEncoder().encode(notification))

        #expect(object["id"] == nil)
        #expect(object["method"] as? String == "m")
    }

    @Test("response envelope round-trips through Codable")
    func responseEnvelopeRoundTrip() throws {
        let envelope = JSONRPCResponseEnvelope(id: .number(42), result: "ok")

        let data = try JSONEncoder().encode(envelope)
        let decoded = try JSONDecoder().decode(JSONRPCResponseEnvelope<String>.self, from: data)

        #expect(decoded.id == .number(42))
        #expect(decoded.result == "ok")
    }

    @Test("error envelope encodes a nil id as explicit null")
    func errorEnvelopeEncodesNullId() throws {
        let envelope = JSONRPCErrorEnvelope(
            id: nil,
            error: JSONRPCError(message: "boom", code: -32600, data: nil)
        )

        let object = try jsonObject(JSONEncoder().encode(envelope))

        #expect(object["id"] is NSNull)
        let error = try #require(object["error"] as? [String: Any])
        #expect(error["code"] as? Int == -32600)
        #expect(error["message"] as? String == "boom")
    }

    @Test("error envelope with a known id round-trips through Codable")
    func errorEnvelopeRoundTrip() throws {
        let envelope = JSONRPCErrorEnvelope(
            id: .string("req-9"),
            error: JSONRPCError(message: "invalid", code: -32602, data: "details")
        )

        let data = try JSONEncoder().encode(envelope)
        let decoded = try JSONDecoder().decode(JSONRPCErrorEnvelope.self, from: data)

        #expect(decoded.id == .string("req-9"))
        #expect(decoded.error.code == -32602)
        #expect(decoded.error.data == "details")
    }

    @Test("notification envelope round-trips a numeric subscription id")
    func notificationEnvelopeRoundTrip() throws {
        let envelope = JSONRPCNotificationEnvelope(
            method: "chainHead_v1_followEvent",
            params: JSONRPCSubscriptionParams(subscription: .number(7), result: ["event": "stop"])
        )

        let data = try JSONEncoder().encode(envelope)
        let decoded = try JSONDecoder().decode(
            JSONRPCNotificationEnvelope<[String: String]>.self,
            from: data
        )

        #expect(decoded.params.subscription == .number(7))
        #expect(decoded.params.result["event"] == "stop")

        let object = try jsonObject(data)
        let params = try #require(object["params"] as? [String: Any])
        #expect(params["subscription"] as? UInt64 == 7)
    }
}
