import Foundation
import Operation_iOS
import SubstrateSdk

public extension StorageRequestFactory {
    static func createDefault(with operationQueue: OperationQueue) -> StorageRequestFactory {
        StorageRequestFactory(
            remoteFactory: StorageKeyFactory(),
            operationManager: OperationManager(operationQueue: operationQueue)
        )
    }
}
