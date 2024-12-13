import Foundation

public enum ExtrinsicExtraNodeError: Error {
    case invalidParams
}

public class ExtrinsicExtraNode: Node {
    static let defaultExtensions: [TransactionExtensionCoding] = [
        TransactionExtension.CheckMortality.getTransactionExtensionCoder(),
        TransactionExtension.CheckNonce.getTransactionExtensionCoder(),
        TransactionExtension.ChargeTransactionPayment.getTransactionExtensionCoder(),
        CheckMetadataHashCoder()
    ]
    
    public var typeName: String { GenericType.extrinsicExtra.name }
    public let runtimeMetadata: RuntimeMetadataProtocol
    public let customExtensions: [TransactionExtensionCoding]

    public init(
        runtimeMetadata: RuntimeMetadataProtocol,
        customExtensions: [TransactionExtensionCoding]
    ) {
        self.runtimeMetadata = runtimeMetadata
        self.customExtensions = customExtensions
    }
    
    private func getCoders() -> [String: TransactionExtensionCoding] {
        (Self.defaultExtensions + customExtensions).reduce(into: [String: TransactionExtensionCoding]()) {
            $0[$1.txExtensionId] = $1
        }
    }

    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        guard let params = value.dictValue else {
            throw DynamicScaleEncoderError.dictExpected(json: value)
        }

        let coders = getCoders()
        
        for checkString in runtimeMetadata.getSignedExtensions() {
            if let includer = coders[checkString] {
                try includer.encodeIncludedInExtrinsic(from: params, encoder: encoder)
            } else if
                let extensionParams = params[checkString],
                let type = runtimeMetadata.getSignedExtensionType(for: checkString) {
                try encoder.append(json: extensionParams, type: type)
            } else if
                let type = runtimeMetadata.getSignedExtensionType(for: checkString),
                encoder.canEncodeOptional(for: type) {
                try encoder.append(json: JSON.null, type: type)
            }
        }
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        let coders = getCoders()
        
        let extra = try runtimeMetadata.getSignedExtensions().reduce(into: [String: JSON]()) { (result, item) in
            if let coder = coders[item] {
                try coder.decodeIncludedInExtrinsic(to: &result, decoder: decoder)
            } else if let type = runtimeMetadata.getSignedExtensionType(for: item) {
                result[item] = try decoder.read(type: type)
            }
        }

        return .dictionaryValue(extra)
    }
}
