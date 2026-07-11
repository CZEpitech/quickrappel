import AppKit
import EventKit
import SwiftUI

struct DeskletView: View {
    @ObservedObject private var model = ReminderViewModel.shared
    @ObservedObject private var panel = PanelController.shared
    @ObservedObject private var lang = Lang.shared
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if let message = model.errorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(3)
            }
            list
            input
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
                    ReminderRow(reminder: reminder) {
                        model.complete(reminder)
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

struct ReminderRow: View {
    let reminder: EKReminder
    let onComplete: () -> Void

    @ObservedObject private var lang = Lang.shared

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Button(action: onComplete) {
                Image(systemName: "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            Text(reminder.title ?? "")
                .font(.system(size: 13))
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
