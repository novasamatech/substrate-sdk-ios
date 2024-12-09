import Foundation
import BigInt

public enum ExtrinsicNodeError: Error {
    case invalidParams
    case invalidVersion
}

public class ExtrinsicNode: Node {
    public var typeName: String { GenericType.extrinsic.name }

    public init() {}
    
    private func appendSigned(_ signed: Extrinsic.Signed, encoder: DynamicScaleEncoding) throws {
        let version: UInt8 = ExtrinsicConstants.legacyExtrinsicFormatVersion | ExtrinsicConstants.signedExtrinsicType
        try encoder.append(encodable: version)
        try encoder.append(signed.signature, ofType: GenericType.extrinsicSignature.name)
        try encoder.append(json: signed.call, type: KnownType.call.name)
    }
    
    private func appendGeneral(_ general: Extrinsic.General, encoder: DynamicScaleEncoding) throws {
        let version: UInt8 = ExtrinsicConstants.extrinsicFormatVersion | ExtrinsicConstants.generalExtrinsicType
        try encoder.append(encodable: version)
        try encoder.append(encodable: general.extensionVersion)
        try encoder.append(general.explicits, ofType: GenericType.extrinsicExtra.name)
        try encoder.append(json: general.call, type: KnownType.call.name)
    }

    private func appendBare(_ bare: Extrinsic.Bare, encoder: DynamicScaleEncoding) throws {
        try encoder.append(encodable: bare.extrinsicVersion)
        try encoder.append(json: bare.call, type: KnownType.call.name)
    }
    
    private func decodeSigned(from decoder: DynamicScaleDecoding) throws -> Extrinsic.Signed {
        let signature: ExtrinsicSignature = try decoder.read(of: GenericType.extrinsicSignature.name)
        let call = try decoder.read(type: KnownType.call.name)
        
        return Extrinsic.Signed(signature: signature, call: call)
    }
    
    private func decodeGeneral(from decoder: DynamicScaleDecoding) throws -> Extrinsic.General {
        let extensionVersion: UInt8 = try decoder.read()
        let explicits: ExtrinsicExtra = try decoder.read(of: GenericType.extrinsicExtra.name)
        let call = try decoder.read(type: KnownType.call.name)
        
        return Extrinsic.General(
            extensionVersion: extensionVersion,
            call: call,
            explicits: explicits
        )
    }
    
    public func accept(encoder: DynamicScaleEncoding, value: JSON) throws {
        let extrinsic = try value.map(to: Extrinsic.self)

        let subEncoder = encoder.newEncoder()

        switch extrinsic {
        case let .bare(bare):
            try appendBare(bare, encoder: subEncoder)
        case let .signed(signed):
            try appendSigned(signed, encoder: subEncoder)
        case let .generalTransaction(general):
            try appendGeneral(general, encoder: subEncoder)
        }
        
        let encoded = try subEncoder.encode()

        try encoder.append(encodable: encoded)
    }

    public func accept(decoder: DynamicScaleDecoding) throws -> JSON {
        // read and ignore extrinsic length
        let _: BigUInt = try decoder.read()
        let versionWithType: UInt8 = try decoder.read()
        let version = versionWithType & ExtrinsicConstants.extrinsicVersionMask
        let type = versionWithType & ExtrinsicConstants.extrinsicTypeMask
        
        switch (version, type) {
        case (_, ExtrinsicConstants.bareExtrinsicType):
            if version >= ExtrinsicConstants.legacyExtrinsicFormatVersion,
               version <= ExtrinsicConstants.extrinsicFormatVersion {
                let call = try decoder.read(type: KnownType.call.name)
                
                let bare = Extrinsic.Bare(extrinsicVersion: version, call: call)
                return try Extrinsic.bare(bare).toScaleCompatibleJSON()
            } else {
                throw ExtrinsicNodeError.invalidVersion
            }
        case (ExtrinsicConstants.legacyExtrinsicFormatVersion, ExtrinsicConstants.signedExtrinsicType):
            let signed = try decodeSigned(from: decoder)
            
            return try Extrinsic.signed(signed).toScaleCompatibleJSON()
        case (ExtrinsicConstants.extrinsicFormatVersion, ExtrinsicConstants.generalExtrinsicType):
            let general = try decodeGeneral(from: decoder)
            
            return try Extrinsic.generalTransaction(general).toScaleCompatibleJSON()
        case (_, _):
            throw ExtrinsicNodeError.invalidVersion
        }
    }
}
