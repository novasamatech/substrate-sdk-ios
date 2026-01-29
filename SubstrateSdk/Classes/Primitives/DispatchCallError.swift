import Foundation

public extension Substrate {
    enum DispatchCallError: Error {
        public struct ModuleRawError {
            public let moduleIndex: UInt8
            public let error: Data
            
            public init(moduleIndex: UInt8, error: Data) {
                self.moduleIndex = moduleIndex
                self.error = error
            }
        }

        public struct ModuleDisplayError {
            public let moduleName: String
            public let errorName: String
            
            public init(moduleName: String, errorName: String) {
                self.moduleName = moduleName
                self.errorName = errorName
            }
        }

        public struct ModuleError {
            public let raw: ModuleRawError
            public let display: ModuleDisplayError
            
            public init(raw: ModuleRawError, display: ModuleDisplayError) {
                self.raw = raw
                self.display = display
            }
        }

        public struct Other {
            public let module: String
            public let reason: String?
            
            public init(module: String, reason: String?) {
                self.module = module
                self.reason = reason
            }
        }

        case module(ModuleError)
        case other(Other)
    }
}
