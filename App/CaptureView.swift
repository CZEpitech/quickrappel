import SwiftUI

struct CaptureView: View {
    let onDone: () -> Void

    @State private var text = ""
    @State private var status: String?
    @State private var saving = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Image(systemName: "checklist")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.orange)
                TextField("Nouveau rappel...", text: $text)
                    .textFieldStyle(.plain)
                    .font(.system(size: 20, weight: .medium))
                    .focused($focused)
                    .disabled(saving)
                    .onSubmit(save)
            }
            Text(status ?? "Entrée pour enregistrer, Échap pour annuler. Les dates sont détectées (ex: demain 14h).")
                .font(.caption)
                .foregroundStyle(status == nil ? .secondary : Color.red)
                .lineLimit(2)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 14)
        .frame(width: 480)
        .onAppear { focused = true }
        .onExitCommand { onDone() }
    }

    private func save() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            onDone()
            return
        }
        saving = true
        status = "Enregistrement..."
        ReminderStore.save(text: trimmed) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    onDone()
                case .failure(let error):
                    saving = false
                    status = error.localizedDescription
                }
            }
        }
    }
}
