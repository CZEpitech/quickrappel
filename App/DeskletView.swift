import AppKit
import EventKit
import SwiftUI

struct DeskletView: View {
    @ObservedObject private var model = ReminderViewModel.shared
    @ObservedObject private var panel = PanelController.shared
    @ObservedObject private var lang = Lang.shared
    @ObservedObject private var game = GameState.shared
    @State private var text = ""
    @State private var tab: PanelTab = .active
    @FocusState private var focused: Bool

    enum PanelTab {
        case active
        case history
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            stats
            tabs
            if let message = model.errorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(3)
            }
            if tab == .active {
                list
                input
            } else {
                history
            }
        }
        .padding(16)
        .frame(width: 340, height: 440, alignment: .top)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(.ultraThinMaterial))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.12))
        )
        .simultaneousGesture(TapGesture().onEnded {
            NSApp.activate(ignoringOtherApps: true)
        })
        .contextMenu {
            Button(
                panel.locked
                    ? lang.t("Déverrouiller la position", "Unlock position")
                    : lang.t("Verrouiller la position", "Lock position")
            ) {
                panel.locked.toggle()
            }
            Button(action: { panel.overlay.toggle() }) {
                if panel.overlay { Image(systemName: "checkmark") }
                Text(lang.t("Toujours au premier plan", "Always on top"))
            }
            Menu(lang.t("Langue", "Language")) {
                Button(action: { lang.code = "fr" }) {
                    if lang.isFrench { Image(systemName: "checkmark") }
                    Text("Français")
                }
                Button(action: { lang.code = "en" }) {
                    if !lang.isFrench { Image(systemName: "checkmark") }
                    Text("English")
                }
            }
            Divider()
            Button(lang.t("Quitter QuickRappel", "Quit QuickRappel")) {
                NSApp.terminate(nil)
            }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "checklist")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(.orange)
            Text(lang.t("Rappels", "Reminders"))
                .font(.system(size: 15, weight: .bold))
            Spacer()
            Button(action: { model.undo() }) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(model.canUndo ? Color.orange : Color.secondary.opacity(0.4))
            .disabled(!model.canUndo)
            .help(lang.t("Annuler la dernière action (Cmd+Z)", "Undo last action (Cmd+Z)"))
            Text("\(model.reminders.count)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var stats: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.yellow)
                    .symbolEffect(.bounce, value: game.level)
                Text(lang.t("Nv", "Lv") + " \(game.level)")
                    .font(.system(size: 11, weight: .bold))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.1))
                    Capsule()
                        .fill(LinearGradient(colors: [.orange, .yellow], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(4, geo.size.width * game.levelProgress))
                        .animation(.spring(duration: 0.4), value: game.levelProgress)
                }
            }
            .frame(height: 6)
            HStack(spacing: 3) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(game.displayStreak > 0 ? .orange : Color.secondary.opacity(0.5))
                    .symbolEffect(.bounce, value: game.displayStreak)
                Text("\(game.displayStreak)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(game.displayStreak > 0 ? .primary : .secondary)
            }
            .help(lang.t("Jours consécutifs avec au moins une tâche faite", "Consecutive days with at least one task done"))
            HStack(spacing: 3) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(game.doneToday > 0 ? .green : Color.secondary.opacity(0.5))
                    .symbolEffect(.bounce, value: game.doneToday)
                Text("\(game.doneToday)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(game.doneToday > 0 ? .primary : .secondary)
            }
            .help(lang.t("Tâches faites aujourd'hui", "Tasks done today"))
        }
    }

    private var tabs: some View {
        Picker("", selection: $tab) {
            Text(lang.t("Tâches", "Tasks")).tag(PanelTab.active)
            Text(lang.t("Historique", "History")).tag(PanelTab.history)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private var history: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                if model.completed.isEmpty {
                    Text(lang.t("Aucune tâche complétée.", "No completed tasks."))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
                ForEach(model.completed, id: \.calendarItemIdentifier) { reminder in
                    HistoryRow(reminder: reminder) {
                        model.restore(reminder)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: .infinity)
    }

    private var list: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 4) {
                if model.reminders.isEmpty {
                    Text(lang.t("Rien à faire.", "Nothing to do."))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
                ForEach(model.reminders, id: \.calendarItemIdentifier) { reminder in
                    ReminderRow(reminder: reminder, inProgress: model.isInProgress(reminder)) {
                        model.statusTapped(reminder)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxHeight: .infinity)
    }

    private var input: some View {
        HStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(.orange)
            TextField(lang.t("Nouveau rappel...", "New reminder..."), text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($focused)
                .onSubmit(submit)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(.white.opacity(0.07)))
    }

    private func submit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        model.add(text: trimmed)
        text = ""
    }
}

struct HistoryRow: View {
    let reminder: EKReminder
    let onRestore: () -> Void

    @ObservedObject private var lang = Lang.shared

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Button(action: onRestore) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.green)
            }
            .buttonStyle(.plain)
            .help(lang.t("Remettre dans les tâches", "Put back into tasks"))
            Text(reminder.title ?? "")
                .font(.system(size: 13))
                .strikethrough()
                .foregroundStyle(.secondary)
                .lineLimit(2)
            Spacer(minLength: 4)
            if let date = reminder.completionDate {
                Text(completionLabel(date))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func completionLabel(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: lang.localeIdentifier)
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.dateFormat = "d MMM"
        }
        return formatter.string(from: date)
    }
}

struct ReminderRow: View {
    let reminder: EKReminder
    let inProgress: Bool
    let onTap: () -> Void

    @ObservedObject private var lang = Lang.shared

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Button(action: onTap) {
                Image(systemName: inProgress ? "circle.lefthalf.filled" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(inProgress ? Color.orange : Color.secondary)
            }
            .buttonStyle(.plain)
            .help(
                inProgress
                    ? lang.t("En cours - cliquer pour terminer", "In progress - click to complete")
                    : lang.t("Cliquer pour passer en cours", "Click to mark in progress")
            )
            Text(reminder.title ?? "")
                .font(.system(size: 13, weight: inProgress ? .semibold : .regular))
                .lineLimit(2)
            if reminder.hasRecurrenceRules {
                Image(systemName: "repeat")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            if let due = dueLabel {
                Text(due.text)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(due.color)
            }
        }
        .padding(.vertical, 4)
    }

    private var dueLabel: (text: String, color: Color)? {
        let calendar = Calendar.current
        guard
            let components = reminder.dueDateComponents,
            let date = calendar.date(from: components)
        else {
            return nil
        }
        let hasTime = components.hour != nil
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: lang.localeIdentifier)
        if calendar.isDateInToday(date) {
            if hasTime {
                formatter.dateFormat = "HH:mm"
                return (formatter.string(from: date), date < Date() ? .red : .secondary)
            }
            return (lang.t("auj.", "today"), .secondary)
        }
        if date < calendar.startOfDay(for: Date()) {
            formatter.dateFormat = "d MMM"
            return (formatter.string(from: date), .red)
        }
        if calendar.isDateInTomorrow(date) {
            return (lang.t("demain", "tomorrow"), .secondary)
        }
        formatter.dateFormat = "d MMM"
        return (formatter.string(from: date), .secondary)
    }
}
