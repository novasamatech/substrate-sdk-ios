import Foundation
import MetadataShortenerApi
import SubstrateSdk
import Operation_iOS
import Foundation_iOS

public protocol MetadataHashOperationFactoryProtocol {
    func createCheckMetadataHashWrapper(
        for chain: ChainProtocol,
        connection: JSONRPCEngine,
        runtimeProvider: RuntimeCodingServiceProtocol
    ) -> CompoundOperationWrapper<Data?>
}

public final class MetadataHashOperationFactory {
    let operationQueue: OperationQueue
    let metadataRepositoryFactory: RuntimeMetadataRepositoryFactoryProtocol

    let cache: InMemoryCache<ChainId, Data>

    public init(
        metadataRepositoryFactory: RuntimeMetadataRepositoryFactoryProtocol,
        operationQueue: OperationQueue
    ) {
        self.metadataRepositoryFactory = metadataRepositoryFactory
        self.operationQueue = operationQueue
        cache = InMemoryCache()
    }

    private func createRuntimeVersionOperation(
        for connection: JSONRPCEngine
    ) -> BaseOperation<RuntimeVersionFull> {
        JSONRPCOperation<[String], RuntimeVersionFull>(
            engine: connection,
            method: RPCMethod.getRuntimeVersion,
            timeout: 3600
        )
    }

    private func createFetchMetadataHashWrapper(
        for chain: ChainProtocol,
        connection: JSONRPCEngine
    ) -> CompoundOperationWrapper<Data?> {
        let rawMetadataOperation = metadataRepositoryFactory.createRepository().fetchOperation(
            by: { chain.chainId },
            options: RepositoryFetchOptions()
        )

        let runtimeVersionOperation = createRuntimeVersionOperation(for: connection)

        let generateAndCacheOperation = ClosureOperation<Data?> {
            guard let rawMetadata = try rawMetadataOperation.extractNoCancellableResultData() else {
                throw CommonMetadataShortenerError.metadataMissing
            }

            let runtimeVersion = try runtimeVersionOperation.extractNoCancellableResultData()

            guard rawMetadata.version == runtimeVersion.specVersion else {
                throw CommonMetadataShortenerError.invalidMetadata(
                    localVersion: rawMetadata.version,
                    remoteVersion: runtimeVersion.specVersion
                )
            }

            guard let utilityAsset = chain.utilityAsset() else {
                throw CommonMetadataShortenerError.missingNativeAsset
            }

            guard utilityAsset.decimalPrecision <= UInt8.max, utilityAsset.decimalPrecision >= 0 else {
                throw CommonMetadataShortenerError.invalidDecimals
            }

            let decimals = UInt8(utilityAsset.decimalPrecision)

            let params = MetadataHashParams(
                metadata: rawMetadata.metadata,
                specVersion: runtimeVersion.specVersion,
                specName: runtimeVersion.specName,
                decimals: decimals,
                base58Prefix: chain.base58Prefix,
                tokenSymbol: utilityAsset.symbol
            )

            let newHash = try MetadataShortenerApi().generateMetadataHash(for: params)
            self.cache.store(value: newHash, for: chain.chainId)

            return newHash
        }

        generateAndCacheOperation.addDependency(runtimeVersionOperation)
        generateAndCacheOperation.addDependency(rawMetadataOperation)

        return CompoundOperationWrapper(
            targetOperation: generateAndCacheOperation,
            dependencies: [rawMetadataOperation, runtimeVersionOperation]
        )
    }
}

extension MetadataHashOperationFactory: MetadataHashOperationFactoryProtocol {
    public func createCheckMetadataHashWrapper(
        for chain: ChainProtocol,
        connection: JSONRPCEngine,
        runtimeProvider: RuntimeCodingServiceProtocol
    ) -> CompoundOperationWrapper<Data?> {
        guard !chain.disabledCheckMetadataHash else {
            return CompoundOperationWrapper.createWithResult(nil)
        }

        if let existingHash = cache.fetchValue(for: chain.chainId) {
            return CompoundOperationWrapper.createWithResult(existingHash)
        }

        let codingFactoryOperation = runtimeProvider.fetchCoderFactoryOperation()

        let wrapper: CompoundOperationWrapper<Data?> = OperationCombiningService.compoundOptionalWrapper(
            operationManager: OperationManager(operationQueue: operationQueue)
        ) {
            let codingFactory = try codingFactoryOperation.extractNoCancellableResultData()

            guard codingFactory.supportsMetadataHash() else {
                return nil
            }

            return self.createFetchMetadataHashWrapper(
                for: chain,
                connection: connection
            )
        }

        wrapper.addDependency(operations: [codingFactoryOperation])

        return wrapper.insertingHead(operations: [codingFactoryOperation])
    }
}
