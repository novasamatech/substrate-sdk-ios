import Foundation
import SubstrateSdk

public extension RuntimeCall {
    var path: CallCodingPath {
        CallCodingPath(moduleName: moduleName, callName: callName)
    }
}
