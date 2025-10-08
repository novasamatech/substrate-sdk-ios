import Foundation
import Operation_iOS
import SubstrateSdk

public protocol RuntimeMetadataItemProviding {
    func createFetchWrapper(for chainId: ChainId) -> CompoundOperationWrapper<RuntimeMetadataItemProtocol?>
}
