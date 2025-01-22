import Foundation

///
/// Transaction extensions provide functionality similar to signed extensions, but with greater flexibility and modularity.
/// They form a pipeline that defines the origin, which can be modified during pipeline execution. Each transaction extension
/// includes **explicit** and **implicit** parameters:
///
/// - **Explicit Parameters**:
///   - These are passed directly as part of the extrinsic during execution.
///   - Examples:
///     - `Nonce` (for `CheckNonce` extension): Prevents replay attacks by ensuring uniqueness.
///     - `Mortality` (for `CheckMortality` extension): Specifies the lifespan of the extrinsic.
///     - `Signature` (for `VerifySignature` extension): Verifies the signed origin of the transaction.
///
/// - **Implicit Parameters**:
///   - These are derived during the execution pipeline and used for forming payloads required for signatures or other proofs.
///   - Examples:
///     - `Genesis Hash` (for `CheckGenesis` extension): Validates the blockchain's genesis block.
///     - `Metadata Hash` (for `CheckMetadataHash` extension): Ensures compatibility with the runtime.
///
/// ## Explicit Parameters
/// Explicit parameters extend the execution logic on-chain by being passed as part of the extrinsic. For example:
/// - Defining a `Nonce` allows for validation that prevents extrinsic replay attacks.
/// - A `Mortality` parameter ensures that transactions are only valid for a specific block range.
///
/// ## Implicit Parameters
/// Implicit parameters are used within the transaction extension pipeline to support functionalities like signature validation.
/// For example:
/// - The `VerifySignature` extension is used to define a signed origin. It functions similarly to signatures in legacy extrinsics
///   but forms the signing payload using a combination of:
///   - Extension version
///   - Call
///   - Explicit parameters from subsequent transaction extensions
///   - Implicit parameters from subsequent transaction extensions
///
/// ## On-Chain Validation
/// During on-chain validation, transaction extensions can derive implicit parameters from on-chain data to verify signatures
/// or other proofs.
///   The payload format is: `extension version | call | next extension explicits | next extension implicits`
///
public protocol TransactionExtending {
    var txExtensionId: String { get }

    func implicit(
        using encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol,
        context: RuntimeJsonContext?
    ) throws -> Data?

    func explicit(
        for implication: TransactionExtension.Implication,
        encodingFactory: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol,
        context: RuntimeJsonContext?
    ) throws -> TransactionExtension.Explicit?
}

public protocol OnlyExplicitTransactionExtending: TransactionExtending {}

public extension OnlyExplicitTransactionExtending {
    func implicit(
        using _: DynamicScaleEncodingFactoryProtocol,
        metadata _: RuntimeMetadataProtocol,
        context _: RuntimeJsonContext?
    ) throws -> Data? {
        nil
    }
}

public extension OnlyExplicitTransactionExtending where Self: Codable {
    func explicit(
        for _: TransactionExtension.Implication,
        encodingFactory _: DynamicScaleEncodingFactoryProtocol,
        metadata: RuntimeMetadataProtocol,
        context: RuntimeJsonContext?
    ) throws -> TransactionExtension.Explicit? {
        let value = try toScaleCompatibleJSON(with: context?.toRawContext())

        return try TransactionExtension.Explicit(
            from: value,
            txExtensionId: txExtensionId,
            metadata: metadata
        )
    }
}

public protocol OnlyImplicitTransactionExtending: TransactionExtending {}

public extension OnlyImplicitTransactionExtending {
    func explicit(
        for _: TransactionExtension.Implication,
        encodingFactory _: DynamicScaleEncodingFactoryProtocol,
        metadata _: RuntimeMetadataProtocol,
        context _: RuntimeJsonContext?
    ) throws -> TransactionExtension.Explicit? {
        nil
    }
}

public protocol TransactionExtensionCoding: AnyObject {
    var txExtensionId: String { get }

    func decodeIncludedInExtrinsic(to extraStore: inout ExtrinsicExtra, decoder: DynamicScaleDecoding) throws
    func encodeIncludedInExtrinsic(from extra: ExtrinsicExtra, encoder: DynamicScaleEncoding) throws
}
