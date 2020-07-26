import Foundation

public enum ChaincodeType {
    case soft
    case hard
}

public struct Chaincode {
    let data: Data
    let type: ChaincodeType
}
