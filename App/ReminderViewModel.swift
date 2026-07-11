import EventKit
import Foundation

final class ReminderViewModel: ObservableObject {
    @Published var reminders: [EKReminder] = []
    @Published var errorMessage: String?

    private let store = EKEventStore()

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storeChanged),
            name: .EKEventStoreChanged,
            object: store
        )
        requestAccess()
    }

    @objc private func storeChanged() {
        fetch()
    }

    private func requestAccess() {
        let handler: (Bool, Error?) -> Void = { [weak self] granted, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                if granted {
                    self.fetch()
                } else {
                    self.errorMessage = "Accès refusé. Réglages Système > Confidentialité et sécurité > Rappels."
                }
            }
        }
        if #available(macOS 14.0, *) {
            store.requestFullAccessToReminders(completion: handler)
        } else {
            store.requestAccess(to: .reminder, completion: handler)
        }
    }

    func fetch() {
        let predicate = store.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: nil,
            calendars: nil
        )
        store.fetchReminders(matching: predicate) { [weak self] result in
            let calendar = Calendar.current
            let sorted = (result ?? []).sorted { a, b in
                let dateA = a.dueDateComponents.flatMap { calendar.date(from: $0) }
                let dateB = b.dueDateComponents.flatMap { calendar.date(from: $0) }
                switch (dateA, dateB) {
                case let (x?, y?):
                    return x < y
                case (nil, .some):
                    return false
                case (.some, nil):
                    return true
                default:
                    return (a.title ?? "") < (b.title ?? "")
                }
            }
            DispatchQueue.main.async {
                self?.reminders = sorted
            }
        }
    }

    func add(text: String) {
        do {
            try ReminderStore.createReminder(text: text, store: store)
            errorMessage = nil
            fetch()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func complete(_ reminder: EKReminder) {
        reminder.isCompleted = true
        do {
            try store.save(reminder, commit: true)
            errorMessage = nil
            fetch()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
