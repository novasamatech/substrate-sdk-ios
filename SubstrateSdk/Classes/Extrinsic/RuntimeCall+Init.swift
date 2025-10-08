import Foundation

public extension RuntimeCall {
    var path: CallCodingPath {
        CallCodingPath(moduleName: moduleName, callName: callName)
    }
}
