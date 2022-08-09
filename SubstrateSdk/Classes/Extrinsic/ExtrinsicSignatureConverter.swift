import Foundation
import BigInt

public class ExtrinsicSignatureConverter {
    static let payloadHashingTreshold = 256

    /**
     *  Cuts prefix bytes of the input payload which represent length of the call in compact format
     */
    public static func convertParitySignerSignaturePayloadToRegular(_ payload: Data) throws -> Data {
        let decoder = try ScaleDecoder(data: payload)
        _ = try BigUInt(scaleDecoder: decoder)

        let extrinsicPayload = payload.suffix(decoder.remained)

        return try convertExtrinsicPayloadToRegular(extrinsicPayload)
    }

    public static func convertExtrinsicPayloadToRegular(_ payload: Data) throws -> Data {
        payload.count > Self.payloadHashingTreshold ? (try payload.blake2b32()) : payload
    }
}
