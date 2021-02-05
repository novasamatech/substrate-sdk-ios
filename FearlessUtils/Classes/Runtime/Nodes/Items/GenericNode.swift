import Foundation

public struct GenericNode: Node {
    public let typeName: String

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        throw DynamicScaleCoderError.unresolverType(name: typeName)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        throw DynamicScaleCoderError.unresolverType(name: typeName)
    }
}

public struct ExtrinsicsDecoderNode: Node {
    public var typeName: String { "ExtrinsicsDecoder" }

    public init() {}
}

public struct CallBytesNode: Node {
    public var typeName: String { "CallBytes" }

    public init() {}
}

public struct EraNode: Node {
    public var typeName: String { "Era" }

    public init() {}
}

public struct DataNode: Node {
    public var typeName: String { "Data" }

    public init() {}
}

public struct BoxProposalNode: Node {
    public var typeName: String { "BoxProposal" }

    public init() {}
}

public struct GenericConsensusEngineIdNode: Node {
    public var typeName: String { "GenericConsensusEngineId" }

    public init() {}
}

public struct SessionKeysSubstrateNode: Node {
    public var typeName: String { "SessionKeysSubstrate" }

    public init() {}
}

public struct GenericMultiAddressNode: Node {
    public var typeName: String { "GenericMultiAddress" }

    public init() {}
}

public struct OpaqueCallNode: Node {
    public var typeName: String { "OpaqueCall" }

    public init() {}
}

public struct GenericAccountIndexNode: Node {
    public var typeName: String { "GenericAccountIndex" }

    public init() {}
}

public struct GenericEventNode: Node {
    public var typeName: String { "GenericEvent" }

    public init() {}
}

public struct EventRecordNode: Node {
    public var typeName: String { "EventRecord" }

    public init() {}
}

public struct AccountIdAddressNode: Node {
    public var typeName: String { "AccountIdAddress" }

    public init() {}
}
