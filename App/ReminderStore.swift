import EventKit
import Foundation

enum ReminderStore {
    private static let weekdayMap: [String: EKWeekday] = [
        "lundi": .monday,
        "mardi": .tuesday,
        "mercredi": .wednesday,
        "jeudi": .thursday,
        "vendredi": .friday,
        "samedi": .saturday,
        "dimanche": .sunday
    ]

    @discardableResult
    static func createReminder(text: String, store: EKEventStore) throws -> EKReminder {
        let reminder = EKReminder(eventStore: store)
        let recurring = text.hasPrefix("!")
        var body = recurring
            ? String(text.dropFirst()).trimmingCharacters(in: .whitespacesAndNewlines)
            : text
        var weekdays: [EKWeekday] = []

        if recurring {
            let parts = body.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            if let first = parts.first {
                let tokens = String(first)
                    .lowercased()
                    .folding(options: .diacriticInsensitive, locale: Locale(identifier: "fr_FR"))
                    .split(separator: ",")
                let mapped = tokens.compactMap { weekdayMap[String($0)] }
                if !mapped.isEmpty && mapped.count == tokens.count {
                    weekdays = mapped
                    body = parts.count > 1
                        ? String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
                        : ""
                }
            }
        }

        var title = body
        var detectedDate: Date?
        if let (date, range) = detectDate(in: body) {
            detectedDate = date
            title.removeSubrange(range)
            title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            if title.isEmpty {
                title = body
            }
        }
        if title.isEmpty {
            title = "Rappel"
        }
        reminder.title = title

        let calendar = Calendar.current
        if let firstWeekday = weekdays.first {
            var base = nextDate(for: firstWeekday)
            if let detected = detectedDate {
                let time = calendar.dateComponents([.hour, .minute], from: detected)
                if let hour = time.hour {
                    base = calendar.date(
                        bySettingHour: hour,
                        minute: time.minute ?? 0,
                        second: 0,
                        of: base
                    ) ?? base
                    reminder.dueDateComponents = calendar.dateComponents(
                        [.year, .month, .day, .hour, .minute],
                        from: base
                    )
                    reminder.addAlarm(EKAlarm(absoluteDate: base))
                } else {
                    reminder.dueDateComponents = calendar.dateComponents([.year, .month, .day], from: base)
                }
            } else {
                reminder.dueDateComponents = calendar.dateComponents([.year, .month, .day], from: base)
            }
        } else if let detected = detectedDate {
            reminder.dueDateComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: detected
            )
            reminder.addAlarm(EKAlarm(absoluteDate: detected))
        } else {
            reminder.dueDateComponents = calendar.dateComponents([.year, .month, .day], from: Date())
        }

        if recurring {
            if weekdays.isEmpty {
                reminder.addRecurrenceRule(
                    EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: nil)
                )
            } else {
                reminder.addRecurrenceRule(
                    EKRecurrenceRule(
                        recurrenceWith: .weekly,
                        interval: 1,
                        daysOfTheWeek: weekdays.map { EKRecurrenceDayOfWeek($0) },
                        daysOfTheMonth: nil,
                        monthsOfTheYear: nil,
                        weeksOfTheYear: nil,
                        daysOfTheYear: nil,
                        setPositions: nil,
                        end: nil
                    )
                )
            }
        }

        reminder.calendar = store.defaultCalendarForNewReminders()
        try store.save(reminder, commit: true)
        return reminder
    }

    private static func nextDate(for weekday: EKWeekday) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let currentWeekday = calendar.component(.weekday, from: today)
        let offset = (weekday.rawValue - currentWeekday + 7) % 7
        return calendar.date(byAdding: .day, value: offset, to: today) ?? today
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
