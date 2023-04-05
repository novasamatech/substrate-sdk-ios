import Foundation

public protocol JSONRPCNodeSwitching {
    func shouldInterceptAndSwitchNode(for error: JSONRPCError, identifier: UInt16) -> Bool
}

public final class JSONRRPCodeNodeSwitcher: JSONRPCNodeSwitching {
    let codes: Set<Int>

    public init(codes: Set<Int>) {
        self.codes = codes
    }

    public func shouldInterceptAndSwitchNode(for error: JSONRPCError, identifier: UInt16) -> Bool {
        codes.contains(error.code)
    }
}
