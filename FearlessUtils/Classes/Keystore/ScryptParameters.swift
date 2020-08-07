import Foundation

enum ScryptParametersError: Error {
    case invalidDataLength
}

struct ScryptParameters {
    static let encodedLength = 44

    let salt: Data
    let scryptN: UInt32
    let scryptP: UInt32
    let scryptR: UInt32

    init(data: Data) throws {
        guard data.count >= Self.encodedLength  else {
            throw ScryptParametersError.invalidDataLength
        }

        self.salt = Data(data[0..<32])

        let valueN: UInt32 = data[32..<36].withUnsafeBytes { $0.pointee }
        self.scryptN = valueN.littleEndian

        let valueP: UInt32 = data[36..<40].withUnsafeBytes { $0.pointee }
        self.scryptP = valueP.littleEndian

        let valueR: UInt32 = data[40..<44].withUnsafeBytes { $0.pointee }
        self.scryptR = valueR.littleEndian
    }
}
