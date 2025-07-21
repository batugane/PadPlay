import Foundation
import AVFoundation

/// Handles audio synthesis and playback for PadPlay.
public class AudioEngine {
    public static let shared = AudioEngine()
    private let engine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()
    private var isSetup = false
    private var audioFile: AVAudioFile?
    private var recordingBuffer: AVAudioPCMBuffer?
    
    private init() {
        setupEngine()
    }
    
    private func setupEngine() {
        guard !isSetup else { return }
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        do {
            try engine.start()
            isSetup = true
        } catch {
            print("Audio engine failed to start: \(error)")
        }
    }
    /// Play a MIDI note (0-127) with velocity (0-127)
    public func playNote(midiNote: UInt8, velocity: UInt8 = 100) {
        sampler.startNote(midiNote, withVelocity: velocity, onChannel: 0)
    }
    /// Stop a MIDI note
    public func stopNote(midiNote: UInt8) {
        sampler.stopNote(midiNote, onChannel: 0)
    }
    /// Start recording audio output
    public func startRecording() {
        // TODO: Implement audio recording
    }
    /// Stop recording and save to file
    public func stopRecording() {
        // TODO: Implement stop and save
    }
    /// Play back the last recording
    public func playbackRecording() {
        // TODO: Implement playback
    }
} 