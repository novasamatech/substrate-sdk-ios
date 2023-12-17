public enum ProxyType: String, Codable {
    case any = "Any"
    case nonTransfer = "NonTransfer"
    case governance = "Governance"
    case staking = "Staking"
    case identityJudgement = "IdentityJudgement"
    case cancelProxy = "CancelProxy"
    case auction = "Auction"
    case nominationPools = "NominationPools"
}
