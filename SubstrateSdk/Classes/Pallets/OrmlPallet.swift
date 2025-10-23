import Foundation

public enum OrmlPallet {
    public static var ormlTotalIssuance: StorageCodingPath {
        StorageCodingPath(moduleName: "Tokens", itemName: "TotalIssuance")
    }

    public static var ormlTokenAccount: StorageCodingPath {
        StorageCodingPath(moduleName: "Tokens", itemName: "Accounts")
    }
}
