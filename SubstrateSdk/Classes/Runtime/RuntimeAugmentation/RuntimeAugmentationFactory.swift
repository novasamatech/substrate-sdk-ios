import Foundation

public protocol RuntimeAugmentationFactoryProtocol: AnyObject {
    func createSubstrateAugmentation(for runtime: PostV14RuntimeMetadataProtocol) -> RuntimeAugmentationResult
    func createEthereumBasedAugmentation(for runtime: PostV14RuntimeMetadataProtocol) -> RuntimeAugmentationResult
}

public final class RuntimeAugmentationFactory: RuntimeAugmentationFactoryProtocol {
    static let uncheckedExtrinsicModuleName = "sp_runtime.UncheckedExtrinsic"

    public init() {}

    private func addingAdditionalOneOfTo(
        types: [String],
        fromType: String,
        additionalNodes: RuntimeAugmentationResult.AdditionalNodes,
        runtime: PostV14RuntimeMetadataProtocol,
        mode: RuntimeTypeMatchingMode
    ) -> RuntimeAugmentationResult.AdditionalNodes {
        for type in types {
            if let metadataType = RuntimeMetadataSearchEngine.find(type: type, in: runtime, mode: mode) {
                let node = AliasNode(typeName: fromType, underlyingTypeName: metadataType)
                return additionalNodes.adding(node: node)
            }
        }

        return additionalNodes.adding(notMatchedType: fromType)
    }

    private func addingAdditionalOneOfFrom(
        types: [String],
        toType: String,
        additionalNodes: RuntimeAugmentationResult.AdditionalNodes,
        runtime: PostV14RuntimeMetadataProtocol,
        mode: RuntimeTypeMatchingMode
    ) -> RuntimeAugmentationResult.AdditionalNodes {
        for type in types {
            if let metadataType = RuntimeMetadataSearchEngine.find(type: type, in: runtime, mode: mode) {
                let node = AliasNode(typeName: metadataType, underlyingTypeName: toType)
                return additionalNodes.adding(node: node)
            }
        }

        return additionalNodes.adding(notMatchedType: toType)
    }

    private func addingEventPhaseNode(
        to additionalNodes: RuntimeAugmentationResult.AdditionalNodes,
        runtime: PostV14RuntimeMetadataProtocol
    ) -> RuntimeAugmentationResult.AdditionalNodes {
        addingAdditionalOneOfTo(
            types: ["frame_system.Phase"],
            fromType: KnownType.phase.name,
            additionalNodes: additionalNodes,
            runtime: runtime,
            mode: .firstLastComponents
        )
    }

    private func addingSubstrateAddressNode(
        to additionalNodes: RuntimeAugmentationResult.AdditionalNodes,
        runtime: PostV14RuntimeMetadataProtocol
    ) -> RuntimeAugmentationResult.AdditionalNodes {
        if let addressType = RuntimeMetadataSearchEngine.findParameterType(
            for: Self.uncheckedExtrinsicModuleName,
            parameterName: "Address",
            in: runtime,
            mode: .firstLastComponents
        ) {
            let node = AliasNode(typeName: KnownType.address.name, underlyingTypeName: addressType)
            return additionalNodes.adding(node: node)
        } else {
            return additionalNodes.adding(notMatchedType: KnownType.address.name)
        }
    }

    private func addingEthereumBasedAddressNode(
        to additionalNodes: RuntimeAugmentationResult.AdditionalNodes,
        runtime: PostV14RuntimeMetadataProtocol
    ) -> RuntimeAugmentationResult.AdditionalNodes {
        addingAdditionalOneOfTo(
            types: ["AccountId20"],
            fromType: KnownType.address.name,
            additionalNodes: additionalNodes,
            runtime: runtime,
            mode: .lastComponent
        )
    }

    private func addingSubstrateSignatureNode(
        to additionalNodes: RuntimeAugmentationResult.AdditionalNodes,
        runtime: PostV14RuntimeMetadataProtocol
    ) -> RuntimeAugmentationResult.AdditionalNodes {
        if let signatureType = RuntimeMetadataSearchEngine.findParameterType(
            for: Self.uncheckedExtrinsicModuleName,
            parameterName: "Signature",
            in: runtime,
            mode: .firstLastComponents
        ) {
            let node = AliasNode(typeName: KnownType.signature.name, underlyingTypeName: signatureType)
            return additionalNodes.adding(node: node)
        } else {
            return additionalNodes.adding(notMatchedType: KnownType.signature.name)
        }
    }

    private func addingEthereumBasedSignatureNode(
        to additionalNodes: RuntimeAugmentationResult.AdditionalNodes
    ) -> RuntimeAugmentationResult.AdditionalNodes {
        let node = StructNode(
            typeName: KnownType.signature.name,
            typeMapping: [
                NameNode(name: "r", node: ProxyNode(typeName: GenericType.h256.name)),
                NameNode(name: "s", node: ProxyNode(typeName: GenericType.h256.name)),
                NameNode(name: "v", node: ProxyNode(typeName: PrimitiveType.u8.name))
            ]
        )

        return additionalNodes.adding(node: node)
    }

    private func addingSubstrateAccountIdNode(
        to additionalNodes: RuntimeAugmentationResult.AdditionalNodes,
        runtime: PostV14RuntimeMetadataProtocol
    ) -> RuntimeAugmentationResult.AdditionalNodes {
        addingAdditionalOneOfFrom(
            types: ["AccountId32"],
            toType: GenericType.accountId.name,
            additionalNodes: additionalNodes,
            runtime: runtime,
            mode: .lastComponent
        )
    }

    private func addingPalletIdentityDataNode(
        to additionalNodes: RuntimeAugmentationResult.AdditionalNodes,
        runtime: PostV14RuntimeMetadataProtocol
    ) -> RuntimeAugmentationResult.AdditionalNodes {
        addingAdditionalOneOfFrom(
            types: ["pallet_identity.Data"],
            toType: GenericType.data.name,
            additionalNodes: additionalNodes,
            runtime: runtime,
            mode: .firstLastComponents
        )
    }

    private func addingRuntimeEventNode(
        to additionalNodes: RuntimeAugmentationResult.AdditionalNodes,
        runtime: PostV14RuntimeMetadataProtocol
    ) -> RuntimeAugmentationResult.AdditionalNodes {
        addingAdditionalOneOfFrom(
            types: ["RuntimeEvent", "Event"],
            toType: GenericType.event.name,
            additionalNodes: additionalNodes,
            runtime: runtime,
            mode: .lastComponent
        )
    }

    private func addingRuntimeCallNode(
        to additionalNodes: RuntimeAugmentationResult.AdditionalNodes,
        runtime: PostV14RuntimeMetadataProtocol
    ) -> RuntimeAugmentationResult.AdditionalNodes {
        addingAdditionalOneOfFrom(
            types: ["RuntimeCall", "Call"],
            toType: GenericType.call.name,
            additionalNodes: additionalNodes,
            runtime: runtime,
            mode: .lastComponent
        )
    }

    private func addingRuntimeDispatchNode(
        to additionalNodes: RuntimeAugmentationResult.AdditionalNodes,
        runtime: PostV14RuntimeMetadataProtocol
    ) -> RuntimeAugmentationResult.AdditionalNodes {
        let feeType = KnownType.runtimeDispatchInfo.name
        let runtimeType = "frame_support.dispatch.DispatchInfo"

        guard
            let portableType = RuntimeMetadataSearchEngine.findPortableTypes(
                for: runtimeType,
                in: runtime,
                mode: .firstLastComponents
            ).first,
            case let .composite(compositeType) = portableType.type.typeDefinition else {
            return additionalNodes.adding(notMatchedType: feeType)
        }

        guard
            let weightLookupId = compositeType.fields.first(where: { $0.name == "weight" })?.type,
            let dispatchClassLookupId = compositeType.fields.first(where: { $0.name == "class" })?.type else {
            return additionalNodes.adding(notMatchedType: feeType)
        }

        let weightType = runtime.types.types.first(
            where: { $0.identifier == weightLookupId }
        )?.type.pathBasedName ?? String(weightLookupId)

        let dispatchClassType = runtime.types.types.first(
            where: { $0.identifier == dispatchClassLookupId }
        )?.type.pathBasedName ?? String(dispatchClassLookupId)

        let node = StructNode(
            typeName: feeType,
            typeMapping: [
                NameNode(name: "weight", node: ProxyNode(typeName: weightType)),
                NameNode(name: "class", node: ProxyNode(typeName: dispatchClassType)),
                NameNode(name: "partialFee", node: ProxyNode(typeName: PrimitiveType.u128.name))
            ]
        )

        return additionalNodes.adding(node: node)
    }

    private func getCommonAdditionalNodes(
        for runtime: PostV14RuntimeMetadataProtocol
    ) -> RuntimeAugmentationResult.AdditionalNodes {
        var additionalNodes = RuntimeAugmentationResult.AdditionalNodes(
            nodes: [
                AliasNode(typeName: KnownType.balance.name, underlyingTypeName: PrimitiveType.u128.name),
                AliasNode(typeName: KnownType.index.name, underlyingTypeName: PrimitiveType.u32.name)
            ],
            notMatch: []
        )

        additionalNodes = addingEventPhaseNode(to: additionalNodes, runtime: runtime)
        additionalNodes = addingRuntimeEventNode(to: additionalNodes, runtime: runtime)
        additionalNodes = addingRuntimeCallNode(to: additionalNodes, runtime: runtime)
        additionalNodes = addingSubstrateAccountIdNode(to: additionalNodes, runtime: runtime)
        additionalNodes = addingPalletIdentityDataNode(to: additionalNodes, runtime: runtime)
        additionalNodes = addingRuntimeDispatchNode(to: additionalNodes, runtime: runtime)

        return additionalNodes
    }

    private func addingSubstrateSpecificNodes(
        to additionalNodes: RuntimeAugmentationResult.AdditionalNodes,
        runtime: PostV14RuntimeMetadataProtocol
    ) -> RuntimeAugmentationResult.AdditionalNodes {
        var updatedNodes = additionalNodes
        updatedNodes = addingSubstrateAddressNode(to: updatedNodes, runtime: runtime)
        updatedNodes = addingSubstrateSignatureNode(to: updatedNodes, runtime: runtime)

        return updatedNodes
    }

    private func addingEthereumBasedSpecificNodes(
        to additionalNodes: RuntimeAugmentationResult.AdditionalNodes,
        runtime: PostV14RuntimeMetadataProtocol
    ) -> RuntimeAugmentationResult.AdditionalNodes {
        var updatedNodes = additionalNodes
        updatedNodes = addingEthereumBasedAddressNode(to: updatedNodes, runtime: runtime)
        updatedNodes = addingEthereumBasedSignatureNode(to: updatedNodes)

        return updatedNodes
    }
}

public extension RuntimeAugmentationFactory {
    func createSubstrateAugmentation(for runtime: PostV14RuntimeMetadataProtocol) -> RuntimeAugmentationResult {
        var additionalNodes = getCommonAdditionalNodes(for: runtime)
        additionalNodes = addingSubstrateSpecificNodes(to: additionalNodes, runtime: runtime)

        return RuntimeAugmentationResult(additionalNodes: additionalNodes)
    }

    func createEthereumBasedAugmentation(
        for runtime: PostV14RuntimeMetadataProtocol
    ) -> RuntimeAugmentationResult {
        var additionalNodes = getCommonAdditionalNodes(for: runtime)
        additionalNodes = addingEthereumBasedSpecificNodes(to: additionalNodes, runtime: runtime)

        return RuntimeAugmentationResult(additionalNodes: additionalNodes)
    }
}
