import Foundation

public final class StorageKeySuffixMapper<T: Decodable>: Mapping {
    public typealias InputType = Data
    public typealias OutputType = T?

    let coderFactoryClosure: () throws -> RuntimeCoderFactoryProtocol
    let suffixLength: Int
    let type: String

    public init(
        type: String,
        suffixLength: Int,
        coderFactoryClosure: @escaping () throws -> RuntimeCoderFactoryProtocol
    ) {
        self.coderFactoryClosure = coderFactoryClosure
        self.suffixLength = suffixLength
        self.type = type
    }

    public func map(input: Data) -> T? {
        do {
            let coderFactory = try coderFactoryClosure()
            let suffix = Data(input.suffix(suffixLength))
            let decoder = try coderFactory.createDecoder(from: suffix)
            let result: T = try decoder.read(of: type)
            return result
        } catch {
            return nil
        }
    }
}
