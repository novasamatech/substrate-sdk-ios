import Foundation

public struct BasisNodes {
    public static func allNodes(for runtimeMetadata: RuntimeMetadata) -> [Node] {
        supportedBaseNodes() + supportedGenericNodes(for: runtimeMetadata)
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
            StringNode()
        ]
    }

    public static func supportedGenericNodes(for runtimeMetadata: RuntimeMetadata) -> [Node] {
        [
            GenericAccountIdNode(),
            NullNode(),
            GenericBlockNode(),
            GenericCallNode(runtimeMetadata: runtimeMetadata),
            GenericVoteNode(),
            H160Node(),
            H256Node(),
            H512Node(),
            EcdsaNode(),
            BytesNode(),
            BitVecNode(),
            ExtrinsicsDecoderNode(),
            CallBytesNode(),
            EraNode(),
            DataNode(),
            BoxProposalNode(runtimeMetadata: runtimeMetadata),
            GenericConsensusEngineIdNode(),
            SessionKeysSubstrateNode(),
            GenericMultiAddressNode(),
            OpaqueCallNode(runtimeMetadata: runtimeMetadata),
            GenericAccountIdNode(),
            GenericAccountIndexNode(),
            GenericEventNode(runtimeMetadata: runtimeMetadata),
            EventRecordNode(runtimeMetadata: runtimeMetadata),
            AccountIdAddressNode(),
            ExtrinsicNode(),
            ExtrinsicSignatureNode(runtimeMetadata: runtimeMetadata),
            ExtrinsicExtraNode(runtimeMetadata: runtimeMetadata)
        ]
    }
}
