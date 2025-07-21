//
//  ContentView.swift
//  PadPlay
//
//  Created by Batuhan Duras on 21.07.2025.
//

import SwiftUI
import AppKit

struct ContentView: View {
    @State private var grid = NoteGridModel.defaultGrid()
    @State private var currentNotes: Set<UInt8> = []
    @State private var currentTouches: [(CGPoint, UInt8)] = []
    @State private var isFullscreen: Bool = false
    @State private var keyMonitor: Any? = nil
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 20) {
                Text("PadPlay: Trackpad Musical Instrument")
                    .font(.title)
                    .padding(.top)
                // Octave controls
                HStack(spacing: 16) {
                    Button("- Octave") { grid = grid.decrementOctave() }
                    Text("Octaves: \(grid.baseOctave)-\(grid.baseOctave + grid.rows - 1)")
                    Button("+ Octave") { grid = grid.incrementOctave() }
                }
                // Base note controls
                HStack(spacing: 16) {
                    Button("- Note") { grid = grid.decrementBaseNote() }
                    Text("Base Note: \(baseNoteDisplay())")
                    Button("+ Note") { grid = grid.incrementBaseNote() }
                }
                // Trackpad and grid
                ZStack {
                    // Trackpad interaction area
                    TrackpadViewRepresentable(grid: grid, currentNotes: $currentNotes, currentTouches: $currentTouches)
                        .frame(width: 400, height: 300)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.blue, lineWidth: 2))
                        .padding()
                        .onAppear {
                            updateCursor()
                            // Add key event monitor for arrow up/down/left/right
                            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                                if event.keyCode == 126 { // Arrow up
                                    grid = grid.incrementOctave()
                                    return nil
                                } else if event.keyCode == 125 { // Arrow down
                                    grid = grid.decrementOctave()
                                    return nil
                                } else if event.keyCode == 124 { // Arrow right
                                    grid = grid.incrementBaseNote()
                                    return nil
                                } else if event.keyCode == 123 { // Arrow left
                                    grid = grid.decrementBaseNote()
                                    return nil
                                }
                                return event
                            }
                        }
                        .onDisappear {
                            updateCursor()
                            if let monitor = keyMonitor {
                                NSEvent.removeMonitor(monitor)
                                keyMonitor = nil
                            }
                        }
                        .onChange(of: isFullscreen) { _,_ in updateCursor() }
                    // Visual grid overlay
                    GeometryReader { geo in
                        let cellWidth = geo.size.width / CGFloat(grid.columns)
                        let cellHeight = geo.size.height / CGFloat(grid.rows)
                        ForEach(0..<grid.rows, id: \.self) { row in
                            ForEach(0..<grid.columns, id: \.self) { col in
                                Rectangle()
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    .frame(width: cellWidth, height: cellHeight)
                                    .position(x: cellWidth * (CGFloat(col) + 0.5), y: cellHeight * (CGFloat(row) + 0.5))
                                if let note = grid.noteFor(row: row, column: col) {
                                    Text(noteName(midi: note))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .position(x: cellWidth * (CGFloat(col) + 0.5), y: cellHeight * (CGFloat(row) + 0.5))
                                }
                            }
                        }
                        // Draw finger positions as circles
                        ForEach(Array(currentTouches.enumerated()), id: \.offset) { idx, touch in
                            let (pos, _) = touch
                            Circle()
                                .fill(Color.red.opacity(0.5))
                                .frame(width: 28, height: 28)
                                .position(x: geo.size.width * pos.x, y: geo.size.height * (1.0 - pos.y))
                        }
                    }
                    .allowsHitTesting(false)
                }
                // Controls for instrument, scale, recording, etc.
                HStack(spacing: 20) {
                    Button("Instrument") { /* Show instrument picker */ }
                    Button("Scale") { /* Show scale picker */ }
                    Button("Record") { /* Start/stop recording */ }
                    Button("Playback") { /* Play last recording */ }
                }
                // Real-time feedback and customization controls will go here
                Spacer()
            }
            .padding()
            // Current notes display in top left, not over grid
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Notes:")
                    .font(.caption)
                HStack {
                    ForEach(Array(currentNotes).sorted(), id: \.self) { note in
                        Text(noteName(midi: note))
                            .padding(4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            .padding([.top, .leading], 12)
        }
        .background(FullscreenDetector(isFullscreen: $isFullscreen))
    }
    // Helper to convert MIDI note to name
    func noteName(midi: UInt8) -> String {
        let notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let n = Int(midi)
        let octave = (n / 12) - 1
        let name = notes[n % 12]
        return "\(name)\(octave)"
    }
    // Helper to display the current base note as MIDI and note name
    func baseNoteDisplay() -> String {
        // Use the first note in the first row as the base
        if let base = grid.noteMapping.first?.first {
            return "\(base) (\(noteName(midi: base)))"
        }
        return "-"
    }
    // Hide cursor in fullscreen, show otherwise
    func updateCursor() {
        if isFullscreen {
            NSCursor.hide()
        } else {
            NSCursor.unhide()
        }
    }
}

// Helper view to detect fullscreen
struct FullscreenDetector: NSViewRepresentable {
    @Binding var isFullscreen: Bool
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                isFullscreen = window.styleMask.contains(.fullScreen)
            }
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        if let window = nsView.window {
            isFullscreen = window.styleMask.contains(.fullScreen)
        }
    }
}

#Preview {
    ContentView()
}
