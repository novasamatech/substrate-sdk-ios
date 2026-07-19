import Foundation

public struct ViewFunctionQueryResult {
    /// Runtime api to execute view functions
    public static let executeApiName = "RuntimeViewFunction"

    /// Method of the RuntimeViewFunction api accepting the function id and scale encoded inputs
    public static let executeMethodName = "execute_view_function"

    /// 32 bytes id to pass to the RuntimeViewFunction_execute_view_function runtime api
    public let functionId: Data
    public let function: PalletViewFunctionMetadataV16

    public init(functionId: Data, function: PalletViewFunctionMetadataV16) {
        self.functionId = functionId
        self.function = function
    }
}
