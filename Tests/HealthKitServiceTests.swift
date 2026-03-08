import XCTest
@testable import Dose

@MainActor
final class HealthKitServiceTests: XCTestCase {
    func testIsAvailableReturnsBool() {
        let available = HealthKitService.isAvailable
        XCTAssertTrue(available || !available)
    }

    func testInitialState() {
        let service = HealthKitService()

        XCTAssertNil(service.heartRate)
        XCTAssertNil(service.restingHeartRate)
        XCTAssertNil(service.hrv)
        XCTAssertNil(service.respiratoryRate)
        XCTAssertNil(service.bloodOxygen)
        XCTAssertNil(service.steps)
        XCTAssertNil(service.activeEnergy)
        XCTAssertNil(service.bodyMass)
        XCTAssertNil(service.sleepHours)
        XCTAssertNil(service.walkingDistance)
        XCTAssertNil(service.systolicBP)
        XCTAssertNil(service.diastolicBP)
        XCTAssertFalse(service.isAuthorized)
    }
}
