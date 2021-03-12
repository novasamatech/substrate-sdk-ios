import Foundation
import BigInt
import IrohaCrypto

public struct JunctionResult {
    public let chaincodes: [Chaincode]
    public let password: String?

    public init(chaincodes: [Chaincode], password: String?) {
        self.chaincodes = chaincodes
        self.password = password
    }
}

public protocol JunctionFactoryProtocol {
    func parse(path: String) throws -> JunctionResult
}

public enum JunctionFactoryError: Error {
    case emptyPath
    case emptyPassphrase
    case multiplePassphrase
    case emptyJunction
    case invalidStart
}

public struct JunctionFactory: JunctionFactoryProtocol {
    static let passwordSeparator = "///"
    static let hardSeparator = "//"
    static let softSeparator = "/"
    static let chaincodeLength = 32

    public init() {}

    public func parse(path: String) throws -> JunctionResult {
        guard path.hasPrefix(Self.softSeparator) else {
            throw JunctionFactoryError.invalidStart
        }

        let passwordIncludedComponents = path.components(separatedBy: Self.passwordSeparator)

        guard let junctionsPath = passwordIncludedComponents.first else {
            throw JunctionFactoryError.emptyPath
        }

        guard passwordIncludedComponents.count <= 2 else {
            throw JunctionFactoryError.multiplePassphrase
        }

        let password: String?

        if passwordIncludedComponents.count == 2 {
            password = passwordIncludedComponents.last
        } else {
            password = nil
        }

        if let existingPassword = password, existingPassword.isEmpty {
            throw JunctionFactoryError.emptyPassphrase
        }

        let chaincodes = try parseChaincodesFromJunctionPath(junctionsPath)

        return JunctionResult(chaincodes: chaincodes, password: password)
    }

    private func parseChaincodesFromJunctionPath(_ junctionsPath: String) throws -> [Chaincode] {
        return try junctionsPath
                .components(separatedBy: Self.hardSeparator)
                .map { component in

                    var chaincodes: [Chaincode] = []

                    let subcomponents = component.components(separatedBy: Self.softSeparator)

                    guard let hardJunction = subcomponents.first else {
                        throw JunctionFactoryError.emptyJunction
                    }

                    if !hardJunction.isEmpty {
                        let hardJunctionData = try createChaincodeFromJunction(hardJunction)
                        let hardChaincode = Chaincode(data: hardJunctionData, type: .hard)
                        chaincodes.append(hardChaincode)
                    }

                    let softJunctions: [Chaincode] = try subcomponents[1...].map { softJunction in
                        let data = try createChaincodeFromJunction(softJunction)
                        return Chaincode(data: data, type: .soft)
                    }

                    chaincodes.append(contentsOf: softJunctions)

                    return chaincodes
                }.reduce([Chaincode]()) { (result, chaincodes) in
                    return result + chaincodes
                }
    }

    private func createChaincodeFromJunction(_ junction: String) throws -> Data {
        var serialized = try serialize(junction: junction)

        if serialized.count < Self.chaincodeLength {
            serialized += Data(repeating: 0, count: Self.chaincodeLength - serialized.count)
        }

        if serialized.count > Self.chaincodeLength {
            serialized = try serialized.blake2b32()
        }

        return serialized
    }

    private func serialize(junction: String) throws -> Data {
        if let number = BigUInt(junction) {
            return Data(number.serialize().reversed())
        }

        if let data = try? Data(hexString: junction) {
            return data
        }

        let encoder = ScaleEncoder()
        try junction.encode(scaleEncoder: encoder)

        return encoder.encode()
    }
}
