import Foundation
import SubstrateSdk

public enum Phase: Decodable {
    static let extrinsicField = "ApplyExtrinsic"
    static let finalizationField = "Finalization"
    static let initializationField = "Initialization"

    case applyExtrinsic(index: UInt32)
    case finalization
    case initialization

    public var isInitialization: Bool {
        switch self {
        case .initialization:
            return true
        case .applyExtrinsic, .finalization:
            return false
        }
    }

    public var isFinalization: Bool {
        switch self {
        case .finalization:
            return true
        case .applyExtrinsic, .initialization:
            return false
        }
    }

    public var isExtrinsicApplication: Bool {
        switch self {
        case .applyExtrinsic:
            return true
        case .finalization, .initialization:
            return false
        }
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let type = try container.decode(String.self)

        switch type {
        case Phase.extrinsicField:
            let index = try container.decode(StringScaleMapper<UInt32>.self).value
            self = .applyExtrinsic(index: index)
        case Phase.finalizationField:
            self = .finalization
        case Phase.initializationField:
            self = .initialization
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unexpected phase"
            )
        }
    }
}
