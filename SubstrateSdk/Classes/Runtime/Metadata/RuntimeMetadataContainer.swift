import Foundation
import BigInt

public struct RuntimeMetadataContainer {
    public enum OneOfRuntimeMetadata {
        case v13(_ metadata: RuntimeMetadata)
        case v14(_ metadata: RuntimeMetadataV14)
        case v15(_ metadata: RuntimeMetadataV15)
    }

    public let metaReserved: UInt32
    public let runtimeMetadataVersion: UInt8
    public let runtimeMetadata: OneOfRuntimeMetadata

    public init(metaReserved: UInt32, runtimeMetadataVersion: UInt8, runtimeMetadata: OneOfRuntimeMetadata) {
        self.metaReserved = metaReserved
        self.runtimeMetadataVersion = runtimeMetadataVersion
        self.runtimeMetadata = runtimeMetadata
    }
}

extension RuntimeMetadataContainer: ScaleCodable {
    public func encode(scaleEncoder: ScaleEncoding) throws {
        try metaReserved.encode(scaleEncoder: scaleEncoder)
        try runtimeMetadataVersion.encode(scaleEncoder: scaleEncoder)

        switch runtimeMetadata {
        case .v13(let metadata):
            try metadata.encode(scaleEncoder: scaleEncoder)
        case .v14(let metadata):
            try metadata.encode(scaleEncoder: scaleEncoder)
        case let .v15(metadata):
            try metadata.encode(scaleEncoder: scaleEncoder)
        }
    }

    public init(scaleDecoder: ScaleDecoding) throws {
        self.metaReserved = try UInt32(scaleDecoder: scaleDecoder)
        self.runtimeMetadataVersion = try UInt8(scaleDecoder: scaleDecoder)

        if runtimeMetadataVersion < 14 {
            let metadata = try RuntimeMetadata(scaleDecoder: scaleDecoder)
            runtimeMetadata = .v13(metadata)
        } else if runtimeMetadataVersion == 14 {
            let metadata = try RuntimeMetadataV14(scaleDecoder: scaleDecoder)
            runtimeMetadata = .v14(metadata)
        } else {
            let metadata = try RuntimeMetadataV15(scaleDecoder: scaleDecoder)
            runtimeMetadata = .v15(metadata)
        }
    }
}

public enum RuntimeMetadataContainerError: Error {
    case nonExistentMetadata
    case invalidMetadataLength
}

extension RuntimeMetadataContainer {
    /**
     * Can be used to read Option<OpaqueMetadata>, which is the response of
     * runtime call metadata_versionedMetadata()
     */
    public static func createFromOpaque(data: Data) throws -> RuntimeMetadataContainer {
        let scaleDecoder = try ScaleDecoder(data: data)

        let exists = try Bool(scaleDecoder: scaleDecoder)

        guard exists else {
            throw RuntimeMetadataContainerError.nonExistentMetadata
        }

        // skip metadata len
        let metadataLength = try BigUInt(scaleDecoder: scaleDecoder)

        guard metadataLength <= scaleDecoder.remained else {
            throw RuntimeMetadataContainerError.invalidMetadataLength
        }

        return try RuntimeMetadataContainer(scaleDecoder: scaleDecoder)
    }
}
