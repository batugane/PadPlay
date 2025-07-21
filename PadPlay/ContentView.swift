//
//  ContentView.swift
//  PadPlay
//
//  Created by Batuhan Duras on 21.07.2025.
//

import SwiftUI

struct ContentView: View {
    let grid = NoteGridModel.defaultGrid()
    var body: some View {
        VStack(spacing: 20) {
            Text("PadPlay: Trackpad Musical Instrument")
                .font(.title)
                .padding(.top)
            ZStack {
                // Trackpad interaction area
                TrackpadViewRepresentable()
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
}

#Preview {
    ContentView()
}
