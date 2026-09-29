import Foundation

public enum TransactionExtension {
    public struct Explicit {
        let extensionId: String
        let value: JSON
        let customEncoder: TransactionExtensionCoding

        public init(extensionId: String, value: JSON, customEncoder: TransactionExtensionCoding) {
            self.extensionId = extensionId
            self.value = value
            self.customEncoder = customEncoder
        }
        
        func encode(to encoder: DynamicScaleEncoding, extensionVersion: UInt8) throws {
            try customEncoder.encodeIncludedInExtrinsic(
                from: [extensionId: value],
                extensionVersion: extensionVersion,
                encoder: encoder
            )
        }
    }

    public typealias Implicit = Data

    public struct Implication {
        public let extensionVersion: UInt8
        let call: JSON
        let explicits: [Explicit]
        let implicits: [Implicit]
        
        func encodeImplicits(
            using encodingFactory: DynamicScaleEncodingFactoryProtocol
        ) throws -> Data {
            let encoder = encodingFactory.createEncoder()
            
            for implicit in implicits {
                try encoder.appendRawData(implicit)
            }
            
            return try encoder.encode()
        }
        
        func encodeExplicits(
            using encodingFactory: DynamicScaleEncodingFactoryProtocol
        ) throws -> Data {
            let encoder = encodingFactory.createEncoder()
            
            for explicit in explicits {
                try explicit.encode(to: encoder, extensionVersion: extensionVersion)
            }
            
            return try encoder.encode()
        }
        
        func encodeCall(
            using encodingFactory: DynamicScaleEncodingFactoryProtocol
        ) throws -> Data {
            let encoder = encodingFactory.createEncoder()
            
            try encoder.append(json: call, type: GenericType.call.name)
            
            return try encoder.encode()
        }
    }
}

public enum TransactionExtensionError: Error {
    case typeNotFound(String)
}

extension TransactionExtension.Implication {
    func adding(
        explicit: TransactionExtension.Explicit?,
        implicit: TransactionExtension.Implicit?
    ) -> TransactionExtension.Implication {
        let newExplicits = explicit.map { [$0] + explicits } ?? explicits
        let newImplicits = implicit.map { [$0] + implicits } ?? implicits

        return TransactionExtension.Implication(
            extensionVersion: extensionVersion,
            call: call,
            explicits: newExplicits,
            implicits: newImplicits
        )
    }
}

public extension TransactionExtension.Explicit {
    init(
        from value: JSON,
        txExtensionId: String,
        metadata: RuntimeMetadataProtocol
    ) {
        extensionId = txExtensionId
        self.value = value
        customEncoder = DefaultVersionedTransactionExtensionCoder(
            txExtensionId: txExtensionId,
            metadata: metadata
        )
    }
}

extension Array where Element == TransactionExtension.Explicit {
    func toExtrinsicExplicits() -> ExtrinsicExtra {
        reduce(
            into: ExtrinsicExtra()
        ) { accum, explicit in
            accum[explicit.extensionId] = explicit.value
        }
    }
}
