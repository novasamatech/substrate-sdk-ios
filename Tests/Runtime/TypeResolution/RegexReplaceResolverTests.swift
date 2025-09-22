import XCTest
@testable import SubstrateSdk

class RegexReplaceResolverTests: XCTestCase {
    func testModuleRefinement() {
        // given

        let resolver = RegexReplaceResolver.noise()
        let searchingType = "BidKind<T::Account>"
        let expectedType = "BidKind<Account>"

        // when

        let result = resolver.resolve(typeName: searchingType, using: ["Account", "BidKind", expectedType])

        // then

        XCTAssertEqual(expectedType, result)
    }

    func testGenericRefinement() {
        // given

        let resolver = RegexReplaceResolver.noise()
        let searchingType = "BidKind<T>"
        let expectedType = "BidKind"

        // when

        let result = resolver.resolve(typeName: searchingType, using: ["T", "<T>", "Bidkind", expectedType])

        // then

        XCTAssertEqual(expectedType, result)
    }

    func testTraitRefinement() {
        // given

        let resolver = RegexReplaceResolver.noise()
        let searchingType = "BidKind<<T as Trait>::Account>"
        let expectedType = "BidKind<Account>"

        // when

        let result = resolver.resolve(typeName: searchingType, using: ["Account", "BidKind", expectedType, "T", "Trait"])

        // then

        XCTAssertEqual(expectedType, result)
    }

    func testTraitIRefinement() {
        // given

        let resolver = RegexReplaceResolver.noise()
        let searchingType = "Box<<T as Trait<I>>::Proposal>"
        let expectedType = "Box<Proposal>"

        // when

        let result = resolver.resolve(typeName: searchingType, using: ["Box", "Proposal", expectedType, "T", "Trait"])

        // then

        XCTAssertEqual(expectedType, result)
    }

    func testAnotherTraitIRefinement() {
        // given

        let resolver = RegexReplaceResolver.noise()
        let searchingType = "<T as Trait<I>>::Proposal"
        let expectedType = "Proposal"

        // when

        let result = resolver.resolve(typeName: searchingType, using: [expectedType, "T", "Trait"])

        // then

        XCTAssertEqual(expectedType, result)
    }

    func testConfigRefinement() {
        // given

        let resolver = RegexReplaceResolver.noise()
        let searchingType = "BidKind<<T as Config>::Account>"
        let expectedType = "BidKind<Account>"

        // when

        let result = resolver.resolve(typeName: searchingType, using: ["Account", "BidKind", expectedType, "T", "Trait"])

        // then

        XCTAssertEqual(expectedType, result)
    }

    func testNewLineRefinement() {
        // given

        let resolver = RegexReplaceResolver.noise()
        let searchingType = "BidKind<<T as Config>::Account>\n"
        let expectedType = "BidKind<Account>"

        // when

        let result = resolver.resolve(typeName: searchingType, using: ["Account", "BidKind", expectedType, "T", "Trait"])

        // then

        XCTAssertEqual(expectedType, result)
    }

    func testModuleScheduleNameRefinement() {
        performTestModuleNameRefinement("schedule")
        performTestModuleNameRefinement("grandpa")
        performTestModuleNameRefinement("session")
        performTestModuleNameRefinement("slashing")
    }

    func testGenericsFilterWhenHasOneLevel() {
        // given

        let resolver = RegexReplaceResolver.genericsFilter()
        let searchingType = "BidKind<Account>"
        let expectedType = "BidKind"

        // when

        let result = resolver.resolve(typeName: searchingType, using: ["Account", "BidKind<Account>", expectedType, "T", "Trait"])

        // then

        XCTAssertEqual(expectedType, result)
    }

    func testGenericsFilterWhenHasInnerSubtype() {
        // given

        let resolver = RegexReplaceResolver.genericsFilter()
        let searchingType = "BidKind<<T as Config>::Account>"
        let expectedType = "BidKind"

        // when

        let result = resolver.resolve(typeName: searchingType, using: ["Account", "BidKind<Account>", expectedType, "T", "Trait"])

        // then

        XCTAssertEqual(expectedType, result)
    }

    func testGenericsFilterHasNoEffectInMiddle() {
        // given

        let resolver = RegexReplaceResolver.genericsFilter()
        let searchingType = "BidKind<T>::Source"
        let expectedType = "BidKind<T>::Source"

        // when

        let result = resolver.resolve(typeName: searchingType, using: ["Account", "BidKind", "BidKind<Account>", expectedType, "T", "Trait"])

        // then

        XCTAssertEqual(expectedType, result)
    }

    func testMultilineGenericsProperlyProcessed() {
        // given

        let resolver = RegexReplaceResolver.genericsFilter()
        let searchingType = "FundInfo<T::AccountId, BalanceOf<T>, T::BlockNumber, LeasePeriodOf<\nT>>"
        let expectedType = "FundInfo"

        // when

        let result = resolver.resolve(typeName: searchingType, using: ["Account", "BidKind", "FundInfo<T::AccountId, BalanceOf<T>, T::BlockNumber, LeasePeriodOf<T>>", expectedType, "T", "Trait"])

        // then

        XCTAssertEqual(expectedType, result)
    }

    // MARK: Private

    private func performTestModuleNameRefinement(_ name: String) {
        // given

        let resolver = RegexReplaceResolver.noise()
        let searchingType = "Option<\(name)::Period<BlockNumber>>"
        let expectedType = "Option<Period<BlockNumber>>"

        // when

        let result = resolver.resolve(typeName: searchingType, using: ["Period", "BlockNumber", expectedType])

        // then

        XCTAssertEqual(expectedType, result)
    }
}
