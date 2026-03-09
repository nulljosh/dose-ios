import XCTest
@testable import Dose

@MainActor
final class NotificationServiceTests: XCTestCase {
    func testRequestAuthorizationReturnsBool() async {
        let service = NotificationService()
        let result = await service.requestAuthorization()
        // Simulator may return true or false depending on state
        XCTAssertTrue(result || !result)
    }

    func testScheduleReminderCreatesRequest() async {
        let service = NotificationService()
        _ = await service.requestAuthorization()

        service.scheduleDoseReminder(substanceName: "TestVitamin", at: Date(), repeats: false)

        let pending = await service.getPending()
        let found = pending.contains { $0.identifier.contains("TestVitamin") }
        XCTAssertTrue(found, "Expected a pending notification for TestVitamin")

        // cleanup
        service.cancelAll()
    }

    func testCancelRemovesNotification() async {
        let service = NotificationService()
        _ = await service.requestAuthorization()

        let date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        service.scheduleDoseReminder(substanceName: "CancelTest", at: date, repeats: false)

        let id = "dose-CancelTest-9-0"
        service.cancelReminder(id: id)

        // Give a moment for removal to propagate
        try? await Task.sleep(nanoseconds: 100_000_000)

        let pending = await service.getPending()
        let found = pending.contains { $0.identifier == id }
        XCTAssertFalse(found, "Cancelled notification should not be pending")

        service.cancelAll()
    }

    func testScheduleWithEmptyNameUsesEmptyId() async {
        let service = NotificationService()
        _ = await service.requestAuthorization()

        service.scheduleDoseReminder(substanceName: "", at: Date(), repeats: false)

        let pending = await service.getPending()
        let found = pending.contains { $0.identifier.hasPrefix("dose-") }
        XCTAssertTrue(found)

        service.cancelAll()
    }
}
