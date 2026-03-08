import XCTest
@testable import Dose

final class InteractionEngineTests: XCTestCase {
    func testClassifySeverityKeywords() {
        XCTAssertEqual(InteractionEngine.classify("fatal interaction"), .major)
        XCTAssertEqual(InteractionEngine.classify("potentiates effect"), .moderate)
        XCTAssertEqual(InteractionEngine.classify("some note"), .minor)
    }

    func testCheckSertralineAndPsilocybinReturnsInteractions() {
        guard let sertraline = SubstanceDatabase.find(id: "sertraline"),
              let psilocybin = SubstanceDatabase.find(id: "psilocybin") else {
            return XCTFail("Expected built-in substances to exist")
        }

        let results = InteractionEngine.check(sertraline, psilocybin)
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.contains { $0.description.contains("Psilocybin (blunted effects)") })
    }

    func testCheckNoKnownInteractionReturnsEmpty() {
        guard let caffeine = SubstanceDatabase.find(id: "caffeine"),
              let vitaminC = SubstanceDatabase.find(id: "vitamin-c") else {
            return XCTFail("Expected built-in substances to exist")
        }

        let results = InteractionEngine.check(caffeine, vitaminC)
        XCTAssertTrue(results.isEmpty)
    }

    func testCheckIsBidirectional() {
        guard let sertraline = SubstanceDatabase.find(id: "sertraline"),
              let psilocybin = SubstanceDatabase.find(id: "psilocybin") else {
            return XCTFail("Expected built-in substances to exist")
        }

        let forward = InteractionEngine.check(sertraline, psilocybin)
        let reverse = InteractionEngine.check(psilocybin, sertraline)

        let forwardSet = Set(forward.map { "\($0.severity.rawValue)|\($0.description)" })
        let reverseSet = Set(reverse.map { "\($0.severity.rawValue)|\($0.description)" })
        XCTAssertEqual(forwardSet, reverseSet)
    }
}
