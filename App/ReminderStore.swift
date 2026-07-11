import EventKit
import Foundation

enum ReminderStore {
    @discardableResult
    static func createReminder(text: String, store: EKEventStore) throws -> EKReminder {
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
        } else {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day],
                from: Date()
            )
        }
        reminder.title = title
        reminder.calendar = store.defaultCalendarForNewReminders()
        try store.save(reminder, commit: true)
        return reminder
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
