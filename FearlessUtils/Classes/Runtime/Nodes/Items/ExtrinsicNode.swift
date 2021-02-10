import Foundation
import BigInt

public enum ExtrinsicNodeError: Error {
    case invalidParams
    case invalidVersion
}

public struct ExtrinsicNode: Node {
    public var typeName: String { "FearlessExtrinsic" }

    public init() {}

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        guard let params = value.arrayValue, params.count == 2 else {
            throw ExtrinsicNodeError.invalidParams
        }

        let subEncoder = encoder.newEncoder()

        if params[0] != .null {
            let version: UInt8 = ExtrinsicConstants.version | ExtrinsicConstants.signedMask
            try subEncoder.append(encodable: version)

            try subEncoder.append(json: params[0], type: "FearlessExtrinsicSignature")
        } else {
            try subEncoder.append(encodable: ExtrinsicConstants.version)
        }

        try subEncoder.append(json: params[1], type: "Call")

        let encoded = try subEncoder.encode()

        try encoder.append(encodable: encoded)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        // read and ignore extrinsic length
        let _: BigUInt? = try decoder.read()

        guard let version: UInt8 = try decoder.read() else {
            throw ExtrinsicNodeError.invalidVersion
        }

        let isSigned = (version & ExtrinsicConstants.signedMask) != 0

        if (version & (~ExtrinsicConstants.signedMask)) != ExtrinsicConstants.version {
            throw ExtrinsicNodeError.invalidVersion
        }

        var result: [JSON] = []

        if isSigned {
            let signature = try decoder.read(type: "FearlessExtrinsicSignature")
            result.append(signature)
        }

        let call = try decoder.read(type: "Call")
        result.append(call)

        return .arrayValue(result)
    }
}
