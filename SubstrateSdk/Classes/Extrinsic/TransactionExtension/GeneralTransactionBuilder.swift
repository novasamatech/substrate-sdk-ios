import Foundation

public protocol GeneralTransactionBuilderProtocol {
    func with(batchType: ExtrinsicBatch) -> Self
    func adding<T: RuntimeCallable>(call: T) throws -> Self
    func adding(transactionExtension: TransactionExtending) -> Self
    func with(runtimeJsonContext: RuntimeJsonContext) -> Self
    
    func build(
        using encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol
    ) throws -> Data
}

public final class GeneralTransactionBuilder {
    let version: UInt8
    
    private var runtimeJsonContext: RuntimeJsonContext?
    private var calls: [JSON]
    private var batchType: ExtrinsicBatch
    private var transactionExtensions: [String: TransactionExtending]
    
    init(
        version: UInt8,
        calls: [JSON] = [],
        batchType: ExtrinsicBatch = .atomic,
        transactionExtensions: [TransactionExtending] = []
    ) {
        self.version = version
        self.calls = calls
        self.batchType = batchType
        self.transactionExtensions = transactionExtensions.reduce(into: [:]) { $0[$1.extensionId] = $1 }
    }
}

private extension GeneralTransactionBuilder {
    private func prepareTransactionCall(
        for metadata: RuntimeMetadataProtocol
    ) throws -> JSON {
        guard !calls.isEmpty else {
            throw ExtrinsicBuilderError.missingCall
        }

        guard calls.count > 1 else {
            return calls[0]
        }

        let callName: String

        switch batchType {
        case .atomic:
            if metadata.getCall(from: KnowRuntimeModule.Utility.name, with: KnowRuntimeModule.Utility.batchAll) != nil {
                callName = KnowRuntimeModule.Utility.batchAll
            } else {
                callName = KnowRuntimeModule.Utility.batchAtomic
            }
        case .untilFail:
            callName = KnowRuntimeModule.Utility.batch
        case .ignoreFails:
            callName = KnowRuntimeModule.Utility.forceBatch
        }

        let call = RuntimeCall(moduleName: KnowRuntimeModule.Utility.name,
                               callName: callName,
                               args: BatchArgs(calls: calls))

        guard metadata.getCall(from: call.moduleName, with: call.callName) != nil else {
            throw ExtrinsicBuilderError.unsupportedBatch
        }

        return try call.toScaleCompatibleJSON(with: runtimeJsonContext?.toRawContext())
    }
    
    private func prepareImplication(
        using encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol
    ) throws -> TransactionExtension.Implication {
        let call = try prepareTransactionCall(for: metadata)
        
        let initialImplication = TransactionExtension.Implication(call: call, explicits: [], implicits: [])
        
        let requiredExtensions = metadata.getSignedExtensions()
        
        return try requiredExtensions.reduce(initialImplication) { implication, extensionId in
            if let transactionExtension = transactionExtensions[extensionId] {
                let implicit = try transactionExtension.implicit(
                    using: encodingFactory,
                    metadata: metadata,
                    context: runtimeJsonContext
                )
                
                let explicit = try transactionExtension.explicit(
                    for: implication,
                    encodingFactory: encodingFactory,
                    metadata: metadata,
                    context: runtimeJsonContext
                )
                
                return implication.adding(explicit: explicit, implicit: implicit)
            } else {
                // TODO: Implement default encoding
                return implication
            }
        }
    }
}

extension GeneralTransactionBuilder: GeneralTransactionBuilderProtocol {
    public func with(batchType: ExtrinsicBatch) -> Self {
        self.batchType = batchType

        return self
    }
    
    public func with(runtimeJsonContext: RuntimeJsonContext) -> Self {
        self.runtimeJsonContext = runtimeJsonContext
        
        return self
    }

    public func adding<T: RuntimeCallable>(call: T) throws -> Self {
        let json = try call.toScaleCompatibleJSON(with: runtimeJsonContext?.toRawContext())
        calls.append(json)

        return self
    }
    
    public func adding(transactionExtension: TransactionExtending) -> Self {
        transactionExtensions[transactionExtension.extensionId] = transactionExtension
        
        return self
    }

    public func build(
        using encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol
    ) throws -> Data {
        let implication = try prepareImplication(using: encodingFactory, metadata: metadata)
        
        let explicits = implication.explicits.reduce(
            into: ExtrinsicExtra()
        ) { accum, explicit in
            accum[explicit.extensionId] = explicit.value
        }

        let transaction = GenericTransaction(
            version: version,
            call: implication.call,
            explicits: explicits
        )
        
        let encoder = try encodingFactory.createEncoder()
        
        try encoder.append(transaction, ofType: GenericType.extrinsic.name, with: runtimeJsonContext?.toRawContext())
        
        return try encoder.encode()
    }
}
