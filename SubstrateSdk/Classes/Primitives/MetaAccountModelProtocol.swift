import Foundation

public protocol MetaAccountModelProtocol {
    func fetchAccount(for chain: ChainProtocol) throws -> AccountProtocol
    func hasAccount(in chain: ChainProtocol) -> Bool
}
