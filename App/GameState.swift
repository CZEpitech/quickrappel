import Foundation

final class GameState: ObservableObject {
    static let shared = GameState()

    private static let xpKey = "gameXP"
    private static let streakKey = "gameStreak"
    private static let lastDayKey = "gameLastCompletionDay"
    private static let doneTodayKey = "gameDoneToday"
    private static let doneTodayDayKey = "gameDoneTodayDay"

    static let xpPerTask = 10
    static let xpPerLevel = 100

    @Published private(set) var xp: Int
    @Published private(set) var streak: Int
    @Published private(set) var doneToday: Int

    private var lastCompletionDay: String

    private init() {
        let defaults = UserDefaults.standard
        xp = defaults.integer(forKey: Self.xpKey)
        streak = defaults.integer(forKey: Self.streakKey)
        lastCompletionDay = defaults.string(forKey: Self.lastDayKey) ?? ""
        let storedDay = defaults.string(forKey: Self.doneTodayDayKey) ?? ""
        doneToday = storedDay == Self.dayString(Date()) ? defaults.integer(forKey: Self.doneTodayKey) : 0
    }

    var level: Int {
        xp / Self.xpPerLevel + 1
    }

    var levelProgress: Double {
        Double(xp % Self.xpPerLevel) / Double(Self.xpPerLevel)
    }

    var displayStreak: Int {
        let today = Self.dayString(Date())
        let yesterday = Self.dayString(Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        return (lastCompletionDay == today || lastCompletionDay == yesterday) ? streak : 0
    }

    func taskCompleted() {
        let today = Self.dayString(Date())
        let yesterday = Self.dayString(Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date())
        if doneTodayIsStale() {
            doneToday = 0
        }
        xp += Self.xpPerTask
        doneToday += 1
        if lastCompletionDay != today {
            streak = lastCompletionDay == yesterday ? streak + 1 : 1
            lastCompletionDay = today
        }
        persist()
    }

    func taskUncompleted() {
        if doneTodayIsStale() {
            doneToday = 0
        }
        xp = max(0, xp - Self.xpPerTask)
        doneToday = max(0, doneToday - 1)
        persist()
    }

    private func doneTodayIsStale() -> Bool {
        UserDefaults.standard.string(forKey: Self.doneTodayDayKey) != Self.dayString(Date())
    }

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(xp, forKey: Self.xpKey)
        defaults.set(streak, forKey: Self.streakKey)
        defaults.set(lastCompletionDay, forKey: Self.lastDayKey)
        defaults.set(doneToday, forKey: Self.doneTodayKey)
        defaults.set(Self.dayString(Date()), forKey: Self.doneTodayDayKey)
    }

    private static func dayString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
