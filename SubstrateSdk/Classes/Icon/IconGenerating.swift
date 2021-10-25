import Foundation
import IrohaCrypto

public protocol DrawableIcon {
    func drawInContext(_ context: CGContext, fillColor: UIColor, size: CGSize)
}

public protocol IconGenerating {
    func generateFromAccountId(_ accountId: Data) throws -> DrawableIcon
}

public extension IconGenerating {
    func generateFromAddress(_ address: String) throws -> DrawableIcon {
        let addressFactory = SS58AddressFactory()

        let typeValue = try addressFactory.type(fromAddress: address)

        let chainType = typeValue.uint16Value

        let accountId = try addressFactory.accountId(fromAddress: address, type: chainType)

        return try generateFromAccountId(accountId)
    }
}
