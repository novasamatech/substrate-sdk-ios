import Foundation

public struct AccountIdKey: JSONListConvertible, Hashable {
    public let accountId: AccountId

    public init(accountId: AccountId) {
        self.accountId = accountId
    }

    public init(jsonList: [JSON], context: [CodingUserInfoKey: Any]?) throws {
        let expectedFieldsCount = 1
        let actualFieldsCount = jsonList.count
        guard expectedFieldsCount == actualFieldsCount else {
            throw JSONListConvertibleError.unexpectedNumberOfItems(
                expected: expectedFieldsCount,
                actual: actualFieldsCount
            )
        }

        accountId = try jsonList[0].map(to: BytesCodable.self, with: context).wrappedValue
    }
}
