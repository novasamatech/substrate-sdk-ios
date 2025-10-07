import Foundation
import SubstrateSdk
import BigInt

public enum Substrate {
    public enum Result<T: Decodable, E: Decodable>: Decodable {
        case success(T)
        case failure(E)

        public init(from decoder: any Decoder) throws {
            var container = try decoder.unkeyedContainer()

            let type = try container.decode(String.self)

            switch type {
            case "Ok":
                let value = try container.decode(T.self)
                self = .success(value)
            case "Err":
                let value = try container.decode(E.self)
                self = .failure(value)
            default:
                throw DecodingError.dataCorrupted(
                    .init(
                        codingPath: container.codingPath,
                        debugDescription: "Unsupported case \(type)"
                    )
                )
            }
        }

        var isOk: Bool {
            switch self {
            case .success:
                return true
            case .failure:
                return false
            }
        }

        @discardableResult
        func ensureOkOrError(_ closure: (E) -> Error) throws -> T {
            switch self {
            case let .success(model):
                return model
            case let .failure(error):
                throw closure(error)
            }
        }
    }
}

public extension Substrate {
    typealias WeightV1 = StringScaleMapper<UInt64>

    struct WeightV1P5: Codable, Equatable {
        @StringCodable var refTime: BigUInt
    }

    struct WeightV2: Codable, Equatable {
        @StringCodable var refTime: BigUInt
        @StringCodable var proofSize: BigUInt
    }

    typealias Weight = WeightV2

    struct BlockWeights: Decodable {
        @Substrate.WeightDecodable var maxBlock: Weight
        let perClass: PerDispatchClass<WeightsPerClass>
    }

    struct PerDispatchClass<T: Decodable>: Decodable {
        let normal: T
        let operational: T
        let mandatory: T
    }

    struct WeightsPerClass: Decodable {
        @OptionalWeightDecodable var maxExtrinsic: Weight?
        @OptionalWeightDecodable var maxTotal: Weight?
    }

    typealias PerDispatchClassWithWeight = PerDispatchClass<Weight>
}

public extension Substrate {
    @propertyWrapper
    struct WeightDecodable: Decodable {
        public let wrappedValue: Weight

        public init(wrappedValue: Weight) {
            self.wrappedValue = wrappedValue
        }

        public init(from decoder: Decoder) throws {
            let json = try JSON(from: decoder)

            // we need to take both camel and snake cases as we are using wrapper both for runtime and JSON PRC

            if let dict = json.dictValue {
                let refTimeJSON = dict["refTime"] ?? dict["ref_time"]

                guard let refTime = refTimeJSON?.toBigUInt() else {
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(
                            codingPath: decoder.codingPath,
                            debugDescription: "Could not decode ref time: \(dict)"
                        )
                    )
                }

                let proofSizeJSON = dict["proofSize"] ?? dict["proof_size"]

                if let proofSizeJSON {
                    guard let proofSize = proofSizeJSON.toBigUInt() else {
                        throw DecodingError.dataCorrupted(
                            DecodingError.Context(
                                codingPath: decoder.codingPath,
                                debugDescription: "Could not decode proof size: \(dict)"
                            )
                        )
                    }

                    wrappedValue = Weight(refTime: refTime, proofSize: proofSize)
                } else {
                    wrappedValue = Weight(refTime: refTime, proofSize: 0)
                }

            } else if let weight = json.toBigUInt() {
                wrappedValue = Weight(refTime: weight, proofSize: 0)
            } else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath,
                        debugDescription: "Unexpected weight type"
                    )
                )
            }
        }
    }

    @propertyWrapper
    struct OptionalWeightDecodable: Decodable {
        public let wrappedValue: Weight?

        public init(wrappedValue: Weight?) {
            self.wrappedValue = wrappedValue
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()

            if container.decodeNil() {
                wrappedValue = nil
            } else {
                wrappedValue = try container.decode(WeightDecodable.self).wrappedValue
            }
        }
    }
}

private extension JSON {
    func toBigUInt() -> BigUInt? {
        if let stringVal = stringValue {
            return BigUInt(stringVal)
        } else if let intVal = unsignedIntValue {
            return BigUInt(intVal)
        } else {
            return nil
        }
    }
}
