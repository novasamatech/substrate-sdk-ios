import Foundation
import Operation_iOS
import SubstrateSdk

public protocol NonceOperationFactoryProtocol {
    func createWrapper(
        for accountIdClosure: @escaping () throws -> AccountId
    ) -> CompoundOperationWrapper<UInt32>
}

public final class SubstrateNonceOperationFactory {
    let chain: ChainProtocol
    let connection: JSONRPCEngine
    let timeout: Int

    init(chain: ChainProtocol, connection: JSONRPCEngine, timeout: Int) {
        self.chain = chain
        self.connection = connection
        self.timeout = timeout
    }

    private func createOperation(
        for accountIdClosure: @escaping () throws -> AccountId,
        chain: ChainProtocol
    ) -> BaseOperation<UInt32> {
        let operation = JSONRPCListOperation<UInt32>(
            engine: connection,
            method: RPCMethod.getExtrinsicNonce,
            timeout: timeout
        )

        operation.configurationBlock = {
            do {
                let accountId = try accountIdClosure()
                let address = try chain.address(for: accountId)
                operation.parameters = [address]
            } catch {
                operation.result = .failure(error)
            }
        }

        return operation
    }
}

extension SubstrateNonceOperationFactory: NonceOperationFactoryProtocol {
    public func createWrapper(
        for accountIdClosure: @escaping () throws -> AccountId
    ) -> CompoundOperationWrapper<UInt32> {
        let operation = createOperation(for: accountIdClosure, chain: chain)

        return CompoundOperationWrapper(targetOperation: operation)
    }
}
