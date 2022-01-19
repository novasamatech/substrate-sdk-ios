import Foundation

public struct BasisNodes {
    public static func allNodes(
        for runtimeMetadata: RuntimeMetadataProtocol,
        customExtensions: [ExtrinsicExtensionCoder]
    ) -> [Node] {
        supportedBaseNodes() + supportedGenericNodes(for: runtimeMetadata, customExtensions: customExtensions)
    }

    public static func supportedBaseNodes() -> [Node] {
        [
            U8Node(),
            U16Node(),
            U32Node(),
            U64Node(),
            U128Node(),
            U256Node(),
            BoolNode(),
            StringNode(),
            I8Node(),
            I16Node(),
            I32Node(),
            I64Node(),
            I128Node(),
            I256Node()
        ]
    }

    public static func supportedGenericNodes(
        for runtimeMetadata: RuntimeMetadataProtocol,
        customExtensions: [ExtrinsicExtensionCoder]
    ) -> [Node] {
        [
            GenericAccountIdNode(),
            NullNode(),
            GenericBlockNode(),
            GenericCallNode(runtimeMetadata: runtimeMetadata),
            GenericVoteNode(),
            KeyValueNode(typeName: GenericType.hashMap.rawValue),
            H160Node(),
            H256Node(),
            H512Node(),
            BytesNode(),
            BitVecNode(),
            ExtrinsicsDecoderNode(),
            CallBytesNode(),
            EraNode(),
            DataNode(),
            BoxProposalNode(),
            GenericConsensusEngineIdNode(),
            SessionKeysSubstrateNode(),
            GenericMultiAddressNode(),
            OpaqueCallNode(),
            GenericAccountIndexNode(),
            GenericEventNode(runtimeMetadata: runtimeMetadata),
            EventRecordNode(),
            AccountIdAddressNode(),
            ExtrinsicNode(),
            ExtrinsicSignatureNode(),
            ExtrinsicExtraNode(runtimeMetadata: runtimeMetadata, customExtensions: customExtensions),
            MappingNode.consensus,
            MappingNode.seal,
            MappingNode.sealv0,
            MappingNode.preRuntime,
            AliasNode(typeName: GenericType.voteWeight.rawValue, underlyingTypeName: PrimitiveType.u64.rawValue)
        ]
    }

}
