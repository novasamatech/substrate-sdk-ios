import Foundation

public enum TransactionExtension {
    public struct Explicit {
        let extensionId: String
        let value: JSON
        let customEncoder: TransactionExtensionCoding

        func encode(to encoder: DynamicScaleEncoding) throws {
            try customEncoder.encodeIncludedInExtrinsic(
                from: [extensionId: value],
                encoder: encoder
            )
        }
    }

    public typealias Implicit = Data

    public struct Implication {
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
                try explicit.encode(to: encoder)
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

        return TransactionExtension.Implication(call: call, explicits: newExplicits, implicits: newImplicits)
    }
}

public extension TransactionExtension.Explicit {
    init(
        from value: JSON,
        txExtensionId: String,
        metadata: RuntimeMetadataProtocol
    ) throws {
        guard let extensionExplicitType = metadata.getSignedExtensionType(for: txExtensionId) else {
            throw TransactionExtensionError.typeNotFound(txExtensionId)
        }

        extensionId = txExtensionId
        self.value = value
        customEncoder = DefaultTransactionExtensionCoder(
            txExtensionId: txExtensionId,
            extensionExplicitType: extensionExplicitType
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
