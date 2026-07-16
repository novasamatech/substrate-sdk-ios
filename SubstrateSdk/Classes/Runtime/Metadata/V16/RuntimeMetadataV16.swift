import Foundation
import BigInt

public struct RuntimeMetadataV16 {
    public let types: RuntimeTypesLookup
    public let pallets: [PalletMetadataV16]
    public let extrinsic: ExtrinsicMetadataV16
    public let apis: [RuntimeApiMetadataV16]

    public init(
        types: RuntimeTypesLookup,
        pallets: [PalletMetadataV16],
        extrinsic: ExtrinsicMetadataV16,
        apis: [RuntimeApiMetadataV16]
    ) {
        self.types = types
        self.pallets = pallets
        self.extrinsic = extrinsic
        self.apis = apis
    }
}

extension RuntimeMetadataV16: PostV14RuntimeMetadataProtocol {
    public var postV14Pallets: [PostV14PalletMetadataProtocol] {
        pallets
    }

    public var postV14Extrinsic: PostV14ExtrinsicMetadataProtocol {
        extrinsic
    }

    public func getRuntimeApiMethod(for runtimeApiName: String, methodName: String) -> RuntimeApiQueryResult? {
        guard let api = apis.first(where: { $0.name == runtimeApiName }) else {
            return nil
        }

        guard let method = api.methods.first(where: { $0.name == methodName }) else {
            return nil
        }

        let commonMethod = RuntimeApiMethodMetadata(
            name: method.name,
            inputs: method.inputs,
            output: method.output,
            docs: method.docs
        )

        return .init(callName: runtimeApiName + "_" + methodName, method: commonMethod)
    }

    public func getViewFunction(for palletName: String, functionName: String) -> ViewFunctionQueryResult? {
        guard let pallet = pallets.first(where: { $0.name == palletName }) else {
            return nil
        }

        guard let function = pallet.viewFunctions.first(where: { $0.name == functionName }) else {
            return nil
        }

        return .init(functionId: function.id, function: function)
    }
}

extension RuntimeMetadataV16: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try types.encode(scaleEncoder: scaleEncoder)
        try pallets.encode(scaleEncoder: scaleEncoder)
        try extrinsic.encode(scaleEncoder: scaleEncoder)
        try apis.encode(scaleEncoder: scaleEncoder)
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        types = try RuntimeTypesLookup(scaleDecoder: scaleDecoder)
        pallets = try [PalletMetadataV16](scaleDecoder: scaleDecoder)
        extrinsic = try ExtrinsicMetadataV16(scaleDecoder: scaleDecoder)
        apis = try [RuntimeApiMetadataV16](scaleDecoder: scaleDecoder)
    }
}
