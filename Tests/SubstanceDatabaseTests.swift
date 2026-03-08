import XCTest
@testable import Dose

final class SubstanceDatabaseTests: XCTestCase {
    func testSearchReturnsResultsForCaffeine() {
        let results = SubstanceDatabase.search("caffeine")
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.contains { $0.id == "caffeine" })
    }

    func testSearchReturnsEmptyForGibberish() {
        let results = SubstanceDatabase.search("qzxvnotarealsubstance123")
        XCTAssertTrue(results.isEmpty)
    }

    func testByCategoryVitaminContainsOnlyVitaminCategory() {
        let vitamins = SubstanceDatabase.byCategory(.vitamin)
        XCTAssertFalse(vitamins.isEmpty)
        XCTAssertTrue(vitamins.allSatisfy { $0.category == .vitamin })
    }

    func testFindCaffeineReturnsCorrectSubstance() {
        let substance = SubstanceDatabase.find(id: "caffeine")
        XCTAssertNotNil(substance)
        XCTAssertEqual(substance?.name, "Caffeine")
    }

    func testFindNonexistentReturnsNil() {
        XCTAssertNil(SubstanceDatabase.find(id: "not-a-real-id"))
    }

    func testAllSubstancesCountIsAtLeast200() {
        XCTAssertGreaterThanOrEqual(SubstanceDatabase.allSubstances.count, 200)
    }

    func testAllCategoriesHaveAtLeastOneSubstance() {
        for category in SubstanceDatabase.categories {
            XCTAssertFalse(
                SubstanceDatabase.byCategory(category).isEmpty,
                "Expected category \(category.rawValue) to have at least one substance"
            )
        }
    }
}
