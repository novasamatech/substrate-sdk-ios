import Testing
import Foundation
@testable import SubstrateSdk

@Suite("JSONRPCSubscriptionId")
struct JSONSubscriptionIdTests {
    static let numericId: UInt64 = 2_595_588_254_652_828
    static let stringId = "n6in3VIm96u3ABQE"

    @Test("decodes a numeric subscribe response preserving the wire type")
    func decodesNumericSubscribeResponse() throws {
        let data = Data(#"{"jsonrpc":"2.0","result":\#(Self.numericId),"id":123}"#.utf8)

        let response = try JSONDecoder().decode(JSONRPCData<JSONRPCSubscriptionId>.self, from: data)

        #expect(response.result == .number(Self.numericId))
    }

    @Test("decodes a string subscribe response preserving the wire type")
    func decodesStringSubscribeResponse() throws {
        let data = Data(#"{"jsonrpc":"2.0","result":"\#(Self.stringId)","id":123}"#.utf8)

        let response = try JSONDecoder().decode(JSONRPCData<JSONRPCSubscriptionId>.self, from: data)

        #expect(response.result == .string(Self.stringId))
    }

    @Test("decodes numeric and string ids in basic update frames")
    func decodesBasicUpdateIds() throws {
        let numericFrame = Data(
            #"{"jsonrpc":"2.0","method":"state_storage","params":{"subscription":\#(Self.numericId),"result":{}}}"#
                .utf8
        )
        let stringFrame = Data(
            #"{"jsonrpc":"2.0","method":"state_storage","params":{"subscription":"\#(Self.stringId)","result":{}}}"#
                .utf8
        )

        let numeric = try JSONDecoder().decode(JSONRPCSubscriptionBasicUpdate.self, from: numericFrame)
        let string = try JSONDecoder().decode(JSONRPCSubscriptionBasicUpdate.self, from: stringFrame)

        #expect(numeric.params.subscription == .number(Self.numericId))
        #expect(string.params.subscription == .string(Self.stringId))
    }

    @Test("decodes a typed update carrying a numeric id")
    func decodesTypedUpdateWithNumericId() throws {
        let data = Data(
            #"{"jsonrpc":"2.0","method":"state_storage","params":{"subscription":\#(Self.numericId),"result":{"block":"0xa4"}}}"#
                .utf8
        )

        let update = try JSONDecoder().decode(JSONRPCSubscriptionUpdate<[String: String]>.self, from: data)

        #expect(update.params.subscription == .number(Self.numericId))
        #expect(update.params.result["block"] == "0xa4")
    }

    @Test("encodes ids back in their original wire type")
    func encodesPreservingWireType() throws {
        let numeric = try JSONEncoder().encode([JSONRPCSubscriptionId.number(7)])
        let string = try JSONEncoder().encode([JSONRPCSubscriptionId.string("7")])

        #expect(String(decoding: numeric, as: UTF8.self) == "[7]")
        #expect(String(decoding: string, as: UTF8.self) == #"["7"]"#)
    }
}
