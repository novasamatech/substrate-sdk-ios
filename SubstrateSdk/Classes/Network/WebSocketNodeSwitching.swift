import Foundation

public protocol WebSocketNodeSwitching {
    func shouldInterceptAndSwitchNode(for error: JSONRPCError, identifier: UInt16) -> Bool
}

public final class JSONRRPCodeNodeSwitcher: WebSocketNodeSwitching {
    let codes: Set<Int>

    public init(codes: Set<Int>) {
        self.codes = codes
    }

    public func shouldInterceptAndSwitchNode(for error: JSONRPCError, identifier: UInt16) -> Bool {
        codes.contains(error.code)
    }
}
