import Foundation

final class Lang: ObservableObject {
    static let shared = Lang()

    private static let storageKey = "appLanguage"

    @Published var code: String {
        didSet { UserDefaults.standard.set(code, forKey: Self.storageKey) }
    }

    private init() {
        if let saved = UserDefaults.standard.string(forKey: Self.storageKey) {
            code = saved
        } else {
            code = Locale.preferredLanguages.first?.hasPrefix("fr") == true ? "fr" : "en"
        }
    }

    var isFrench: Bool { code == "fr" }

    var localeIdentifier: String { isFrench ? "fr_FR" : "en_US" }

    func t(_ french: String, _ english: String) -> String {
        isFrench ? french : english
    }
}
