import Foundation

enum RandomDataError: Error {
    case generatorFailed
}

public extension Data {
    static func random(of size: Int) -> Data? {
        var bytes = [UInt8](repeating: 0, count: size)
        let status = SecRandomCopyBytes(kSecRandomDefault, size, &bytes)

        if status == errSecSuccess {
            return Data(bytes)
        } else {
            return nil
        }
    }
    
    static func randomOrError(of size: Int) throws -> Data {
        guard let data = random(of: size) else {
            throw RandomDataError.generatorFailed
        }
        
        return data
    }
}
