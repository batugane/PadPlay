import SwiftUI
import AppKit

/// A SwiftUI wrapper for a custom NSView that handles trackpad touch events.
struct TrackpadViewRepresentable: NSViewRepresentable {
    func makeNSView(context: Context) -> TrackpadView {
        let view = TrackpadView()
        // Configure view if needed
        return view
    }
    func updateNSView(_ nsView: TrackpadView, context: Context) {}
}

/// The underlying NSView that will handle NSEvent and NSTouch for trackpad input.
class TrackpadView: NSView {
    let grid = NoteGridModel.defaultGrid()
    var activeTouches: [AnyHashable: (row: Int, col: Int, note: UInt8)] = [:]
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsRestingTouches = true
        self.allowedTouchTypes = [.indirect] // Trackpad only
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsRestingTouches = true
        self.allowedTouchTypes = [.indirect]
    }
    override func touchesBegan(with event: NSEvent) {
        super.touchesBegan(with: event)
        handleTouches(event: event, isEnding: false)
    }
    override func touchesMoved(with event: NSEvent) {
        super.touchesMoved(with: event)
        handleTouches(event: event, isEnding: false)
    }
    override func touchesEnded(with event: NSEvent) {
        super.touchesEnded(with: event)
        handleTouches(event: event, isEnding: true)
    }
    override func touchesCancelled(with event: NSEvent) {
        super.touchesCancelled(with: event)
        handleTouches(event: event, isEnding: true)
    }
    /// Map touch locations to grid positions and play/stop notes
    private func handleTouches(event: NSEvent, isEnding: Bool) {
        let touches = event.touches(matching: .touching, in: self)
        let bounds = self.bounds
        for touch in touches {
            let loc = touch.normalizedPosition // (0,0) bottom-left, (1,1) top-right
            let row = min(grid.rows-1, max(0, Int((1.0 - loc.y) * CGFloat(grid.rows))))
            let col = min(grid.columns-1, max(0, Int(loc.x * CGFloat(grid.columns))))
            if let note = grid.noteFor(row: row, column: col) {
                let key = AnyHashable(touch.identity as! NSObject)
                if isEnding {
                    AudioEngine.shared.stopNote(midiNote: note)
                    activeTouches.removeValue(forKey: key)
                } else {
                    if activeTouches[key]?.note != note {
                        // Stop previous note if moved
                        if let prev = activeTouches[key]?.note {
                            AudioEngine.shared.stopNote(midiNote: prev)
                        }
                        // NSTouch on macOS does not have force; use default velocity
                        AudioEngine.shared.playNote(midiNote: note, velocity: 100)
                        activeTouches[key] = (row, col, note)
                    }
                }
            }
        }
        // Stop notes for touches that ended
        if isEnding {
            let endedTouches = event.touches(matching: .ended, in: self)
            for touch in endedTouches {
                let key = AnyHashable(touch.identity as! NSObject)
                if let prev = activeTouches[key]?.note {
                    AudioEngine.shared.stopNote(midiNote: prev)
                    activeTouches.removeValue(forKey: key)
                }
            }
        }
    }
} 