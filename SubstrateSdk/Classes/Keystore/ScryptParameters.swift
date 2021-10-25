import Foundation

enum ScryptParametersError: Error {
    case invalidDataLength
    case invalidSalt
}

struct ScryptParameters {
    static let saltLength = 32
    static let encodedLength = 44
    static let saltRange = 0..<Self.saltLength
    static let scryptNRange = Self.saltLength..<(Self.saltLength+4)
    static let scryptPRange = (Self.saltLength+4)..<(Self.saltLength+8)
    static let scryptRRange = (Self.saltLength+8)..<(Self.saltLength+12)

    let salt: Data
    let scryptN: UInt32
    let scryptP: UInt32
    let scryptR: UInt32

    init(salt: Data, scryptN: UInt32, scryptP: UInt32, scryptR: UInt32) throws {
        guard salt.count == Self.saltLength else {
            throw ScryptParametersError.invalidSalt
        }

        self.salt = salt
        self.scryptN = scryptN
        self.scryptP = scryptP
        self.scryptR = scryptR
    }

    init(scryptN: UInt32 = 32768, scryptP: UInt32 = 1, scryptR: UInt32 = 8) throws {
        let data = try Data.generateRandomBytes(of: Self.saltLength)
        try self.init(salt: data, scryptN: scryptN, scryptP: scryptP, scryptR: scryptR)
    }

    init(data: Data) throws {
        guard data.count >= Self.encodedLength  else {
            throw ScryptParametersError.invalidDataLength
        }

        self.salt = Data(data[Self.saltRange])

        let valueN: UInt32 = data[Self.scryptNRange].withUnsafeBytes { $0.pointee }
        self.scryptN = valueN.littleEndian

        let valueP: UInt32 = data[Self.scryptPRange].withUnsafeBytes { $0.pointee }
        self.scryptP = valueP.littleEndian

        let valueR: UInt32 = data[Self.scryptRRange].withUnsafeBytes { $0.pointee }
        self.scryptR = valueR.littleEndian
    }

    func encode() -> Data {
        var data = Data(repeating: 0, count: Self.encodedLength)
        data.replaceSubrange(Self.saltRange, with: salt)

        var scryptN = self.scryptN
        data.replaceSubrange(Self.scryptNRange, with: Data(bytes: &scryptN, count: MemoryLayout<UInt32>.size))

        var scryptP = self.scryptP
        data.replaceSubrange(Self.scryptPRange, with: Data(bytes: &scryptP, count: MemoryLayout<UInt32>.size))

        var scryptR = self.scryptR
        data.replaceSubrange(Self.scryptRRange, with: Data(bytes: &scryptR, count: MemoryLayout<UInt32>.size))

        return data
    }
}
