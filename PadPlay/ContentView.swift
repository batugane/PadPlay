//
//  ContentView.swift
//  PadPlay
//
//  Created by Batuhan Duras on 21.07.2025.
//

import SwiftUI

struct ContentView: View {
    let grid = NoteGridModel.defaultGrid()
    @State private var currentNotes: Set<UInt8> = []
    @State private var currentTouches: [(CGPoint, UInt8)] = []
    var possibleNotes: [UInt8] {
        Array(Set(grid.noteMapping.flatMap { $0 })).sorted()
    }
    var body: some View {
        VStack(spacing: 20) {
            Text("PadPlay: Trackpad Musical Instrument")
                .font(.title)
                .padding(.top)
            // Display current and possible notes
            VStack(spacing: 4) {
                HStack {
                    Text("Current Notes:")
                    ForEach(Array(currentNotes).sorted(), id: \.self) { note in
                        Text("\(noteName(midi: note))")
                            .padding(4)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
                HStack {
                    Text("Possible Notes:")
                    ForEach(possibleNotes, id: \.self) { note in
                        Text("\(noteName(midi: note))")
                            .padding(2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(2)
                    }
                }
            }
            ZStack {
                // Trackpad interaction area
                TrackpadViewRepresentable(currentNotes: $currentNotes, currentTouches: $currentTouches)
                    .frame(width: 400, height: 300)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.blue, lineWidth: 2))
                    .padding()
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
                        }
                    }
                    // Draw finger positions as circles
                    ForEach(Array(currentTouches.enumerated()), id: \.offset) { idx, touch in
                        let (pos, note) = touch
                        Circle()
                            .fill(Color.red.opacity(0.5))
                            .frame(width: 28, height: 28)
                            .position(x: geo.size.width * pos.x, y: geo.size.height * (1.0 - pos.y))
                            .overlay(Text(noteName(midi: note)).font(.caption2).foregroundColor(.white))
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
    }
    // Helper to convert MIDI note to name
    func noteName(midi: UInt8) -> String {
        let notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
        let n = Int(midi)
        let octave = (n / 12) - 1
        let name = notes[n % 12]
        return "\(name)\(octave)"
    }
}

#Preview {
    ContentView()
}
