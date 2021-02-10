import Foundation

public enum ExtrinsicSignatureNodeError: Error {
    case invalidParams
}

public struct ExtrinsicSignatureNode: Node {
    public var typeName: String { "FearlessExtrinsicSignature" }
    public let runtimeMetadata: RuntimeMetadata

    public init(runtimeMetadata: RuntimeMetadata) {
        self.runtimeMetadata = runtimeMetadata
    }

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        guard let params = value.arrayValue, params.count == 3 else {
            throw ExtrinsicSignatureNodeError.invalidParams
        }

        try encoder.append(json: params[0], type: "Address")
        try encoder.append(json: params[1], type: "MultiSignature")

        let signedExtentionNames = runtimeMetadata.extrinsic.signedExtensions
        guard let extensions = params[2].arrayValue,
              extensions.count == signedExtentionNames.count else {
            throw ExtrinsicSignatureNodeError.invalidParams
        }

        for index in 0..<extensions.count {
            try encoder.append(json: extensions[index], type: signedExtentionNames[index])
        }
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        let address = try decoder.read(type: "Address")
        let signature = try decoder.read(type: "MultiSignature")

        let extentions = try runtimeMetadata.extrinsic.signedExtensions.map { name in
            try decoder.read(type: name)
        }

        return .arrayValue([address, signature, .arrayValue(extentions)])
    }
}
