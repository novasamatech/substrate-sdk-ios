import Foundation

public enum StateCallRpc {
    public static var method: String { "state_call" }
    public static var feeBuiltInModule: String { "TransactionPaymentApi" }
    public static var feeBuiltInMethod: String { "query_info" }
    public static var feeBuiltIn: String { "TransactionPaymentApi_query_info" }
    public static var feeResultType: String { "RuntimeDispatchInfo" }

    public struct Request: Encodable {
        let builtInFunction: String
        let blockHash: BlockHash?
        let paramsClosure: (inout UnkeyedEncodingContainer) throws -> Void

        public init(
            builtInFunction: String,
            blockHash: BlockHash? = nil,
            paramsClosure: @escaping (inout UnkeyedEncodingContainer) throws -> Void
        ) {
            self.builtInFunction = builtInFunction
            self.paramsClosure = paramsClosure
            self.blockHash = blockHash
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.unkeyedContainer()

            try container.encode(builtInFunction)

            try paramsClosure(&container)

            if let blockHash {
                try container.encode(blockHash.withHexPrefix())
            }
        }
    }
}
