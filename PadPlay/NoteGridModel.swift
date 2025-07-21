import Foundation

/// Represents a grid mapping of the trackpad to musical notes.
public struct NoteGridModel {
    public let rows: Int
    public let columns: Int
    public var noteMapping: [[UInt8]] // MIDI note numbers
    
    /// Initialize with a default scale (e.g., C major)
    public static func defaultGrid(rows: Int = 4, columns: Int = 8) -> NoteGridModel {
        // Example: C major scale, repeated
        let baseNotes: [UInt8] = [60, 62, 64, 65, 67, 69, 71, 72] // C4-B4
        var mapping: [[UInt8]] = []
        for _ in 0..<rows {
            mapping.append(baseNotes)
        }
        return NoteGridModel(rows: rows, columns: columns, noteMapping: mapping)
    }
    /// Get the note for a given grid position
    public func noteFor(row: Int, column: Int) -> UInt8? {
        guard row >= 0, row < rows, column >= 0, column < columns else { return nil }
        return noteMapping[row][column]
    }
} 