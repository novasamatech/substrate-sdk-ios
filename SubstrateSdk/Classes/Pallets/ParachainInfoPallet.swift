import Foundation

public enum ParachainInfoPallet {
    public static var parachainId: StorageCodingPath {
        StorageCodingPath(moduleName: "ParachainInfo", itemName: "ParachainId")
    }
}
