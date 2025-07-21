import SwiftUI
import AppKit

/// A SwiftUI wrapper for a custom NSView that handles trackpad touch events and reports notes and finger positions.
struct TrackpadViewRepresentable: NSViewRepresentable {
    var grid: NoteGridModel
    @Binding var currentNotes: Set<UInt8>
    @Binding var currentTouches: [(CGPoint, UInt8)]
    
    func makeCoordinator() -> Coordinator {
        Coordinator(currentNotes: $currentNotes, currentTouches: $currentTouches)
    }
    func makeNSView(context: Context) -> TrackpadView {
        let view = TrackpadView(grid: grid)
        view.delegate = context.coordinator
        return view
    }
    func updateNSView(_ nsView: TrackpadView, context: Context) {
        nsView.grid = grid
    }
    
    class Coordinator: NSObject, TrackpadViewDelegate {
        @Binding var currentNotes: Set<UInt8>
        @Binding var currentTouches: [(CGPoint, UInt8)]
        init(currentNotes: Binding<Set<UInt8>>, currentTouches: Binding<[(CGPoint, UInt8)]>) {
            _currentNotes = currentNotes
            _currentTouches = currentTouches
        }
        func trackpadView(_ view: TrackpadView, didUpdateActiveNotes notes: Set<UInt8>, touches: [(CGPoint, UInt8)]) {
            currentNotes = notes
            currentTouches = touches
        }
    }
}

protocol TrackpadViewDelegate: AnyObject {
    func trackpadView(_ view: TrackpadView, didUpdateActiveNotes notes: Set<UInt8>, touches: [(CGPoint, UInt8)])
}

/// The underlying NSView that will handle NSEvent and NSTouch for trackpad input.
class TrackpadView: NSView {
    var grid: NoteGridModel
    var activeTouches: [AnyHashable: (row: Int, col: Int, note: UInt8, pos: CGPoint)] = [:]
    weak var delegate: TrackpadViewDelegate?
    
    init(grid: NoteGridModel) {
        self.grid = grid
        super.init(frame: .zero)
        self.wantsRestingTouches = true
        self.allowedTouchTypes = [.indirect] // Trackpad only
    }
    required init?(coder: NSCoder) {
        self.grid = NoteGridModel.defaultGrid()
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
        for touch in touches {
            let loc = touch.normalizedPosition // (0,0) bottom-left, (1,1) top-right
            let row = min(grid.rows-1, max(0, Int((1.0 - loc.y) * CGFloat(grid.rows))))
            let col = min(grid.columns-1, max(0, Int(loc.x * CGFloat(grid.columns))))
            if let midiNote = grid.noteFor(row: row, column: col) {
                let key = AnyHashable(touch.identity as! NSObject)
                if isEnding {
                    AudioEngine.shared.stopNote(midiNote: midiNote)
                    activeTouches.removeValue(forKey: key)
                } else {
                    if activeTouches[key]?.note != midiNote {
                        // Stop previous note if moved
                        if let prev = activeTouches[key]?.note {
                            AudioEngine.shared.stopNote(midiNote: prev)
                        }
                        AudioEngine.shared.playNote(midiNote: midiNote, velocity: 100)
                        activeTouches[key] = (row, col, midiNote, loc)
                    } else {
                        // Update position if moved
                        activeTouches[key]?.pos = loc
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
        // If no active touches, stop all notes
        if activeTouches.isEmpty {
            // Stop all possible notes in the grid (all octaves)
            var allNotes = Set<UInt8>()
            for row in 0..<grid.rows {
                for col in 0..<grid.columns {
                    if let note = grid.noteFor(row: row, column: col) {
                        allNotes.insert(note)
                    }
                }
            }
            for note in allNotes {
                AudioEngine.shared.stopNote(midiNote: note)
            }
        }
        // Notify delegate of currently played notes and finger positions
        let currentNotes = Set(activeTouches.values.map { $0.note })
        let currentTouches = activeTouches.values.map { ($0.pos, $0.note) }
        delegate?.trackpadView(self, didUpdateActiveNotes: currentNotes, touches: currentTouches)
    }
} 