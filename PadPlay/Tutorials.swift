import Foundation

/// Provides tutorial content and onboarding steps for new users.
struct Tutorials {
    static func onboardingSteps() -> [String] {
        return [
            "Welcome to PadPlay!",
            "Touch the trackpad to play notes.",
            "Use multiple fingers to play chords.",
            "Change instruments and scales using the controls.",
            "Record and playback your performances.",
            "Customize the grid and note mapping in settings.",
            "Access accessibility features from the menu."
        ]
    }
    static func helpText(for feature: String) -> String {
        switch feature {
        case "trackpad": return "Touch different areas of the trackpad to play different notes."
        case "recording": return "Press Record to capture your performance."
        case "customization": return "Open settings to change the grid, scale, or instrument."
        default: return "See the user guide for more information."
        }
    }
} 