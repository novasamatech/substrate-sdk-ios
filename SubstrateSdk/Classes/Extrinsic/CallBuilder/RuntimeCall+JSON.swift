import Foundation

public extension RuntimeCall where T == JSON {
    func toDisplayRepresentation() -> JSON {
        JSON.dictionaryValue([
            "module": JSON.stringValue(moduleName),
            "function": JSON.stringValue(callName),
            "args": args
        ])
    }
}
