import Foundation
import Observation
import UserNotifications

@Observable
@MainActor
final class NotificationService {
    private let center = UNUserNotificationCenter.current()

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func scheduleDoseReminder(substanceName: String, at date: Date, repeats: Bool) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else { return }

        let id = reminderID(substanceName: substanceName, hour: hour, minute: minute)
        let content = UNMutableNotificationContent()
        content.title = "Dose Reminder"
        content.body = "Time to take \(substanceName)."
        content.sound = .default

        var triggerComponents = DateComponents()
        triggerComponents.hour = hour
        triggerComponents.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: repeats)

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request) { error in
            if let error { print("Notification scheduling failed: \(error.localizedDescription)") }
        }
    }

    func cancelReminder(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }

    func cancelAll() {
        center.removeAllPendingNotificationRequests()
    }

    func getPending() async -> [UNNotificationRequest] {
        await center.pendingNotificationRequests()
    }

    private func reminderID(substanceName: String, hour: Int, minute: Int) -> String {
        let trimmed = substanceName.trimmingCharacters(in: .whitespacesAndNewlines)
        return "dose-\(trimmed)-\(hour)-\(minute)"
    }
}
