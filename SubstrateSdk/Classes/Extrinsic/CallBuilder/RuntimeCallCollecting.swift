import Foundation

public protocol RuntimeCallCollecting {
    var callPath: CallCodingPath { get }

    func addingToExtrinsic(builder: ExtrinsicBuilderProtocol) throws -> ExtrinsicBuilderProtocol
    func addingToCall(builder: RuntimeCallBuilding, toEnd: Bool) throws -> RuntimeCallBuilding
}

public struct RuntimeCallCollector<T: Codable> {
    public let call: RuntimeCall<T>
    
    public init(call: RuntimeCall<T>) {
        self.call = call
    }
}

extension RuntimeCallCollector: RuntimeCallCollecting {
    public var callPath: CallCodingPath {
        CallCodingPath(moduleName: call.moduleName, callName: call.callName)
    }

    public func addingToExtrinsic(builder: ExtrinsicBuilderProtocol) throws -> ExtrinsicBuilderProtocol {
        try builder.adding(call: call)
    }

    public func addingToCall(builder: RuntimeCallBuilding, toEnd: Bool) throws -> RuntimeCallBuilding {
        if toEnd {
            try builder.addingLast(call)
        } else {
            try builder.addingFirst(call)
        }
    }
}
