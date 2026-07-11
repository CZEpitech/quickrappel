import EventKit
import Foundation

final class ReminderViewModel: ObservableObject {
    static let shared = ReminderViewModel()

    enum UndoAction {
        case completed(reminderID: String)
        case added(reminderID: String)
    }

    @Published var reminders: [EKReminder] = []
    @Published var errorMessage: String?
    @Published var canUndo = false

    private let store = EKEventStore()
    private var undoStack: [UndoAction] = []

    private init() {
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
                    self.errorMessage = Lang.shared.t(
                        "Accès refusé. Réglages Système > Confidentialité et sécurité > Rappels.",
                        "Access denied. System Settings > Privacy & Security > Reminders."
                    )
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
            let reminder = try ReminderStore.createReminder(text: text, store: store)
            pushUndo(.added(reminderID: reminder.calendarItemIdentifier))
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
            pushUndo(.completed(reminderID: reminder.calendarItemIdentifier))
            GameState.shared.taskCompleted()
            errorMessage = nil
            fetch()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func undo() {
        guard let action = undoStack.popLast() else { return }
        canUndo = !undoStack.isEmpty
        switch action {
        case .completed(let reminderID):
            guard let reminder = store.calendarItem(withIdentifier: reminderID) as? EKReminder else { return }
            reminder.isCompleted = false
            do {
                try store.save(reminder, commit: true)
                GameState.shared.taskUncompleted()
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        case .added(let reminderID):
            guard let reminder = store.calendarItem(withIdentifier: reminderID) as? EKReminder else { return }
            do {
                try store.remove(reminder, commit: true)
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        fetch()
    }

    private func pushUndo(_ action: UndoAction) {
        undoStack.append(action)
        if undoStack.count > 20 {
            undoStack.removeFirst()
        }
        canUndo = true
    }
}
