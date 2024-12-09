import Foundation

public enum TransactionExtension {
    public struct Explicit {
        let extensionId: String
        let value: JSON
        let customEncoder: ExtrinsicSignedExtensionCoding
        
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
    }
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
