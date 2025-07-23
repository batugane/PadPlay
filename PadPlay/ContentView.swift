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
    @State private var isRecording: Bool = false
    @State private var isPlaying: Bool = false
    @State private var recordStartTime: Date? = nil
    @State private var recordElapsed: Int = 0
    @State private var recordTimer: Timer? = nil
    @State private var errorMessage: String? = nil
    @State private var playbackElapsed: Int = 0
    @State private var playbackTimer: Timer? = nil
    @State private var showHelp: Bool = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Subtle background
            LinearGradient(gradient: Gradient(colors: [Color(NSColor.systemBlue).opacity(0.08), Color(NSColor.windowBackgroundColor)]), startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            VStack(spacing: 24) {
                // Friendly header
                VStack(spacing: 4) {
                    Text("🎹 PadPlay")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .padding(.top, 12)
                    Text("Turn your trackpad into a musical instrument!")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                // Octave controls
                HStack(spacing: 16) {
                    Button("- Octave") { grid = grid.decrementOctave() }
                        .disabled(grid.baseOctave <= NoteGridModel.baselineOctave)
                    Text("Octaves: \(grid.baseOctave)-\(grid.baseOctave + grid.rows - 1)")
                    Button("+ Octave") { grid = grid.incrementOctave() }
                }
                // Base note controls
                HStack(spacing: 16) {
                    Button("- Note") { grid = grid.decrementBaseNote() }
                        .disabled(grid.noteMapping.first?.first ?? 0 <= NoteGridModel.baselineNote)
                    Text("Base Note: \(baseNoteDisplay())")
                    Button("+ Note") { grid = grid.incrementBaseNote() }
                }
                // Full-window touch area and grid
                GeometryReader { geo in
                    ZStack {
                        // Visual grid overlay
                        let cellWidth = geo.size.width / CGFloat(grid.columns)
                        let cellHeight = geo.size.height / CGFloat(grid.rows)
                        ForEach(0..<grid.rows, id: \ .self) { row in
                            ForEach(0..<grid.columns, id: \ .self) { col in
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                                    .frame(width: cellWidth - 2, height: cellHeight - 2)
                                    .position(x: cellWidth * (CGFloat(col) + 0.5), y: cellHeight * (CGFloat(row) + 0.5))
                                    .shadow(color: Color.black.opacity(0.07), radius: 3, x: 0, y: 2)
                                if let note = grid.noteFor(row: row, column: col) {
                                    Text(noteName(midi: note))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .position(x: cellWidth * (CGFloat(col) + 0.5), y: cellHeight * (CGFloat(row) + 0.5))
                                }
                            }
                        }
                        // Sparkling blue touch effects
                        ForEach(Array(currentTouches.enumerated()), id: \.offset) { idx, touch in
                            let (pos, _) = touch
                            SparkleCircle(position: CGPoint(x: geo.size.width * pos.x, y: geo.size.height * (1.0 - pos.y)))
                        }
                        // Touch handling overlay (fills the area)
                        TrackpadViewRepresentable(grid: grid, currentNotes: $currentNotes, currentTouches: $currentTouches)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .background(Color.clear)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                // Controls for recording and playback only
                HStack(spacing: 20) {
                    Button(action: {
                        if isRecording {
                            AudioEngine.shared.stopRecording()
                            isRecording = false
                            recordTimer?.invalidate()
                            recordTimer = nil
                        } else {
                            do {
                                try AudioEngine.shared.startRecording()
                                isRecording = true
                                recordStartTime = Date()
                                recordElapsed = 0
                                recordTimer?.invalidate()
                                recordTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                                    if let start = recordStartTime {
                                        recordElapsed = Int(Date().timeIntervalSince(start))
                                    }
                                }
                            } catch {
                                errorMessage = "Failed to start recording: \(error.localizedDescription)"
                            }
                        }
                    }) {
                        HStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                            Text(isRecording ? "Stop Recording" : "Record")
                        }
                    }
                    .foregroundColor(.red)
                    .disabled(isPlaying)
                    if isRecording {
                        Text(String(format: "%02d:%02d", recordElapsed / 60, recordElapsed % 60))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.red)
                    }
                    Button(isPlaying ? "Stop Playback" : "Playback") {
                        if isPlaying {
                            AudioEngine.shared.stopPlayback()
                            isPlaying = false
                            playbackTimer?.invalidate()
                            playbackTimer = nil
                        } else {
                            isPlaying = true
                            playbackElapsed = 0
                            playbackTimer?.invalidate()
                            playbackTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                                playbackElapsed += 1
                            }
                            AudioEngine.shared.playbackRecording {
                                isPlaying = false
                                playbackTimer?.invalidate()
                                playbackTimer = nil
                            }
                        }
                    }
                    .disabled(isRecording || !AudioEngine.shared.hasRecording())
                    if isPlaying {
                        Text(String(format: "%02d:%02d", playbackElapsed / 60, playbackElapsed % 60))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.blue)
                    }
                }
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding(.top, 4)
                }
                Spacer()
            }
            .padding(.bottom, 16)
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
                            .shadow(color: Color.blue.opacity(0.3), radius: 6, x: 0, y: 2)
                    }
                }
            }
            .padding([.top, .leading], 12)
        }
        .background(FullscreenDetector(isFullscreen: $isFullscreen))
        // Move help button to top right overlay
        .overlay(
            Button(action: { showHelp = true }) {
                Image(systemName: "questionmark.circle")
                    .font(.title2)
            }
            .buttonStyle(PlainButtonStyle())
            .padding([.top, .trailing], 16),
            alignment: .topTrailing
        )
        // Help sheet
        .sheet(isPresented: $showHelp) {
            VStack(alignment: .leading, spacing: 16) {
                Text("PadPlay Help & Shortcuts")
                    .font(.title2)
                    .padding(.bottom, 8)
                Text("Keyboard Shortcuts:")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 4) {
                    Text("↑ / ↓ : Change octave")
                    Text("← / → : Change base note")
                    Text("R : Start/stop recording")
                    Text("Space : Start/stop playback")
                    Text("Esc : Stop playback/recording")
                }
                Text("Usage:")
                    .font(.headline)
                Text("Use your trackpad to play notes. The horizontal position selects the note, the vertical position selects the octave. Use the controls or keyboard shortcuts to record, playback, and export your performance.")
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                Spacer()
                HStack {
                    Spacer()
                    Button("Close") { showHelp = false }
                        .keyboardShortcut(.defaultAction)
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding(32)
            .frame(width: 400, height: 350, alignment: .bottomTrailing)
        }
        .onAppear {
            updateCursor()
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
                } else if event.charactersIgnoringModifiers?.lowercased() == "r" {
                    if isRecording {
                        AudioEngine.shared.stopRecording()
                        isRecording = false
                        recordTimer?.invalidate()
                        recordTimer = nil
                    } else if !isPlaying {
                        do {
                            try AudioEngine.shared.startRecording()
                            isRecording = true
                            recordStartTime = Date()
                            recordElapsed = 0
                            recordTimer?.invalidate()
                            recordTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                                if let start = recordStartTime {
                                    recordElapsed = Int(Date().timeIntervalSince(start))
                                }
                            }
                        } catch {
                            errorMessage = "Failed to start recording: \(error.localizedDescription)"
                        }
                    }
                    return nil
                } else if event.keyCode == 49 { // Space
                    if isPlaying {
                        AudioEngine.shared.stopPlayback()
                        isPlaying = false
                        playbackTimer?.invalidate()
                        playbackTimer = nil
                    } else if !isRecording && AudioEngine.shared.hasRecording() {
                        isPlaying = true
                        playbackElapsed = 0
                        playbackTimer?.invalidate()
                        playbackTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                            playbackElapsed += 1
                        }
                        AudioEngine.shared.playbackRecording {
                            isPlaying = false
                            playbackTimer?.invalidate()
                            playbackTimer = nil
                        }
                    }
                    return nil
                } else if event.keyCode == 53 { // Esc
                    if isPlaying {
                        AudioEngine.shared.stopPlayback()
                        isPlaying = false
                        playbackTimer?.invalidate()
                        playbackTimer = nil
                    }
                    if isRecording {
                        AudioEngine.shared.stopRecording()
                        isRecording = false
                        recordTimer?.invalidate()
                        recordTimer = nil
                    }
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
            recordTimer?.invalidate()
            recordTimer = nil
            playbackTimer?.invalidate()
            playbackTimer = nil
        }
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

// Sparkling blue touch effect
struct SparkleCircle: View {
    var position: CGPoint
    @State private var animate = false
    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.cyan.opacity(0.5)]), startPoint: .top, endPoint: .bottom))
                .frame(width: animate ? 38 : 28, height: animate ? 38 : 28)
                .shadow(color: Color.blue.opacity(0.4), radius: animate ? 18 : 8)
                .scaleEffect(animate ? 1.15 : 1.0)
                .opacity(animate ? 0.7 : 1.0)
                .animation(Animation.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: animate)
                .onAppear { animate = true }
            ForEach(0..<6) { i in
                Circle()
                    .fill(Color.cyan.opacity(0.5))
                    .frame(width: 6, height: 6)
                    .offset(x: (animate ? 18 : 12) * cos(CGFloat(i) * .pi / 3),
                            y: (animate ? 18 : 12) * sin(CGFloat(i) * .pi / 3))
                    .opacity(animate ? 0.5 : 0.3)
                    .animation(Animation.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: animate)
            }
        }
        .position(position)
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
