import SwiftUI
import UserNotifications

struct RemindersView: View {
    @Bindable var notificationService: NotificationService
    @State private var pending: [UNNotificationRequest] = []
    @State private var showingAddSheet = false

    var body: some View {
        NavigationStack {
            List {
                if pending.isEmpty {
                    Text("No reminders scheduled.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(pending, id: \.identifier) { request in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(request.content.body.replacingOccurrences(of: "Time to take ", with: "").replacingOccurrences(of: ".", with: ""))
                                    .font(.headline)
                                Text(timeLabel(for: request))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let trigger = request.trigger as? UNCalendarNotificationTrigger, trigger.repeats {
                                Text("Repeats")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .onDelete(perform: delete)
                }
            }
            .navigationTitle("Reminders")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddReminderSheet { name, date, repeats in
                    notificationService.scheduleDoseReminder(substanceName: name, at: date, repeats: repeats)
                    Task { await refreshPending() }
                } onPreset: { name, hour, minute in
                    var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
                    components.hour = hour
                    components.minute = minute
                    let date = Calendar.current.date(from: components) ?? Date()
                    notificationService.scheduleDoseReminder(substanceName: name, at: date, repeats: true)
                    Task { await refreshPending() }
                }
            }
            .task {
                _ = await notificationService.requestAuthorization()
                await refreshPending()
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        let ids = offsets.map { pending[$0].identifier }
        for id in ids {
            notificationService.cancelReminder(id: id)
        }
        pending.remove(atOffsets: offsets)
    }

    @MainActor
    private func refreshPending() async {
        let requests = await notificationService.getPending()
        pending = requests.sorted { lhs, rhs in
            timeSortKey(lhs) < timeSortKey(rhs)
        }
    }

    private func timeSortKey(_ request: UNNotificationRequest) -> String {
        guard let trigger = request.trigger as? UNCalendarNotificationTrigger else { return "99:99" }
        let hour = trigger.dateComponents.hour ?? 99
        let minute = trigger.dateComponents.minute ?? 99
        return String(format: "%02d:%02d", hour, minute)
    }

    private func timeLabel(for request: UNNotificationRequest) -> String {
        guard let trigger = request.trigger as? UNCalendarNotificationTrigger,
              let hour = trigger.dateComponents.hour,
              let minute = trigger.dateComponents.minute else {
            return "Time unavailable"
        }
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }
}

private struct AddReminderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var substanceName = ""
    @State private var time = Date()
    @State private var repeats = true

    let onSave: (String, Date, Bool) -> Void
    let onPreset: (String, Int, Int) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Reminder") {
                    TextField("Substance name", text: $substanceName)
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    Toggle("Repeat daily", isOn: $repeats)
                }

                Section("Quick Presets") {
                    Button("Morning vitamins 8:00 AM") {
                        onPreset("Morning vitamins", 8, 0)
                        dismiss()
                    }
                    Button("Evening supplements 9:00 PM") {
                        onPreset("Evening supplements", 21, 0)
                        dismiss()
                    }
                }
            }
            .navigationTitle("Add Reminder")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = substanceName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed, time, repeats)
                        dismiss()
                    }
                }
            }
        }
    }
}
