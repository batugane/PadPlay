import Foundation

/// Represents a grid mapping of the trackpad to musical notes.
public struct NoteGridModel {
    public let rows: Int
    public let columns: Int
    public var noteMapping: [[UInt8]] // MIDI note numbers (for one octave)
    public var baseOctave: Int // The lowest octave (e.g., 3 for C3)
    
    /// Initialize with a default scale (e.g., C major) and octaves 3, 4, 5
    public static func defaultGrid(rows: Int = 3, columns: Int = 8, baseOctave: Int = 3) -> NoteGridModel {
        // Example: C major scale, repeated
        let baseNotes: [UInt8] = [0, 2, 4, 5, 7, 9, 11, 12] // C-B in semitones, relative to C
        var mapping: [[UInt8]] = []
        for _ in 0..<rows {
            mapping.append(baseNotes)
        }
        return NoteGridModel(rows: rows, columns: columns, noteMapping: mapping, baseOctave: baseOctave)
    }
    /// Get the note for a given grid position
    public func noteFor(row: Int, column: Int) -> UInt8? {
        guard row >= 0, row < rows, column >= 0, column < columns else { return nil }
        let octave = baseOctave + row
        let base = Int(noteMapping[row][column])
        let midi = 12 * octave + base
        let clamped = max(0, min(midi, 127))
        return UInt8(clamped)
    }
    /// Increase the base octave (shift all up)
    public func incrementOctave() -> NoteGridModel {
        NoteGridModel(rows: rows, columns: columns, noteMapping: noteMapping, baseOctave: baseOctave + 1)
    }
    /// Decrease the base octave (shift all down)
    public func decrementOctave() -> NoteGridModel {
        NoteGridModel(rows: rows, columns: columns, noteMapping: noteMapping, baseOctave: max(0, baseOctave - 1))
    }
    /// Increase the base note (shift all notes up by 1 semitone)
    public func incrementBaseNote() -> NoteGridModel {
        let newMapping = noteMapping.map { $0.map { min($0 + 1, 127) } }
        return NoteGridModel(rows: rows, columns: columns, noteMapping: newMapping, baseOctave: baseOctave)
    }
    /// Decrease the base note (shift all notes down by 1 semitone)
    public func decrementBaseNote() -> NoteGridModel {
        let newMapping = noteMapping.map { $0.map { max($0 - 1, 0) } }
        return NoteGridModel(rows: rows, columns: columns, noteMapping: newMapping, baseOctave: baseOctave)
    }
} 