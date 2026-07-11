import EventKit
import Foundation

enum ReminderStoreError: LocalizedError {
    case accessDenied

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Accès refusé. Réglages Système > Confidentialité et sécurité > Rappels > autoriser QuickRappel."
        }
    }
}

enum ReminderStore {
    static func save(text: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let store = EKEventStore()
        let handler: (Bool, Error?) -> Void = { granted, _ in
            guard granted else {
                completion(.failure(ReminderStoreError.accessDenied))
                return
            }
            do {
                try createReminder(text: text, store: store)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
        if #available(macOS 14.0, *) {
            store.requestFullAccessToReminders(completion: handler)
        } else {
            store.requestAccess(to: .reminder, completion: handler)
        }
    }

    private static func createReminder(text: String, store: EKEventStore) throws {
        let reminder = EKReminder(eventStore: store)
        var title = text
        if let (date, range) = detectDate(in: text) {
            title.removeSubrange(range)
            title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            if title.isEmpty {
                title = text
            }
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: date
            )
            reminder.addAlarm(EKAlarm(absoluteDate: date))
        }
        reminder.title = title
        reminder.calendar = store.defaultCalendarForNewReminders()
        try store.save(reminder, commit: true)
    }

    private static func detectDate(in text: String) -> (Date, Range<String.Index>)? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        let matches = detector.matches(in: text, options: [], range: range)
        guard
            let match = matches.first,
            let date = match.date,
            date > Date(),
            let swiftRange = Range(match.range, in: text)
        else {
            return nil
        }
        return (date, swiftRange)
    }
}
