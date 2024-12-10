import Foundation
import BigInt

public extension TransactionExtension {
    struct ChargeTransactionPayment: Codable, OnlyExplicitTransactionExtending {
        public var txExtensionId: String { Extrinsic.TransactionExtensionId.txPayment }

        public let tip: BigUInt

        public init(tip: BigUInt = 0) {
            self.tip = tip
        }
        
        public func explicit(
            for implication: TransactionExtension.Implication,
            encodingFactory: DynamicScaleEncodingFactoryProtocol,
            metadata: RuntimeMetadataProtocol,
            context: RuntimeJsonContext?
        ) throws -> TransactionExtension.Explicit? {
            let value = try StringScaleMapper(value: tip).toScaleCompatibleJSON(with: context?.toRawContext())
            
            return TransactionExtension.Explicit(
                extensionId: txExtensionId,
                value: value,
                customEncoder: DefaultTransactionExtensionCoder(
                    txExtensionId: txExtensionId,
                    extensionExplicitType: KnownType.balance.name
                )
            )
        }
    }
}
