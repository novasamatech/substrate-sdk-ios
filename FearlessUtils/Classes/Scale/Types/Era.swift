import Foundation

enum Era {
    case immortal
    case mortal(period: UInt64, phase: UInt64)
}

enum EraCodingError: Error {
    case invalidPeriod
    case phaseAndPeriodMismatch
}

extension Era: ScaleCodable {
    init(scaleDecoder: ScaleDecoding) throws {
        let firstByte = try UInt8(scaleDecoder: scaleDecoder)

        guard firstByte > 0 else {
            self = .immortal
            return
        }

        let secondByte = try UInt8(scaleDecoder: scaleDecoder)

        let encoded = UInt64(firstByte) + (UInt64(secondByte) << 8)
        let period = 2 << (encoded % (1 << 4))
        let quantizeFactor = max(period >> 12, 1)
        let phase = (encoded >> 4) * quantizeFactor

        guard period >= 4 else {
            throw EraCodingError.invalidPeriod
        }

        guard phase < period else {
            throw EraCodingError.phaseAndPeriodMismatch
        }

        self = .mortal(period: period, phase: phase)
    }

    func encode(scaleEncoder: ScaleEncoding) throws {
        switch self {
        case .immortal:
            try UInt8(0).encode(scaleEncoder: scaleEncoder)
        case .mortal(let period, let phase):
            guard period >= 4 else {
                throw EraCodingError.invalidPeriod
            }

            guard phase < period else {
                throw EraCodingError.phaseAndPeriodMismatch
            }

            let quantizeFactor = max(period >> 12, 1)

            var periodExponent: UInt64 = 0
            var currentPeriod = period

            while currentPeriod > 2 {
                periodExponent += 1
                currentPeriod = currentPeriod >> 1
            }

            var encoded = ((phase / quantizeFactor) << 4) | (periodExponent & 15)
            let bytes = Data(bytes: &encoded, count: MemoryLayout<Int64>.size).prefix(2)
            scaleEncoder.appendRaw(data: bytes)
        }
    }
}
