struct ProxyCall: Codable {
    let real: MultiAddress
    let forceProxyType: ProxyType
    let call: JSON
    
    enum CodingKeys: String, CodingKey {
        case real
        case forceProxyType = "force_proxy_type"
        case call
    }
    
    func runtimeCall() -> RuntimeCall<Self> {
        RuntimeCall(moduleName: "Proxy", callName: "proxy", args: self)
    }
}
