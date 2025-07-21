import Foundation
import AVFoundation
import AppKit

/// Handles audio synthesis and playback for PadPlay.
public class AudioEngine {
    public static let shared = AudioEngine()
    private let engine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()
    private var isSetup = false
    private var audioFile: AVAudioFile?
    private var recordingBuffer: AVAudioPCMBuffer?
    private var recordingFile: AVAudioFile?
    private var recordingURL: URL?
    private var player: AVAudioPlayerNode?
    private var isRecording = false
    private var isPlaying = false
    
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
    /// Start recording audio output to a temporary WAV file
    public func startRecording() throws {
        guard !isRecording else { return }
        let format = engine.mainMixerNode.outputFormat(forBus: 0)
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("PadPlayRecording.wav")
        if FileManager.default.fileExists(atPath: tempURL.path) {
            try? FileManager.default.removeItem(at: tempURL)
        }
        recordingFile = try AVAudioFile(forWriting: tempURL, settings: format.settings)
        recordingURL = tempURL
        engine.mainMixerNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] (buffer, time) in
            do {
                try self?.recordingFile?.write(from: buffer)
            } catch {
                print("Error writing buffer: \(error)")
            }
        }
        isRecording = true
    }
    /// Stop recording and save to file
    public func stopRecording() {
        guard isRecording else { return }
        engine.mainMixerNode.removeTap(onBus: 0)
        recordingFile = nil
        isRecording = false
    }
    /// Play back the last recording
    public func playbackRecording(completion: (() -> Void)? = nil) {
        guard let url = recordingURL else { return }
        do {
            let file = try AVAudioFile(forReading: url)
            let format = file.processingFormat
            let player = AVAudioPlayerNode()
            self.player = player
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
            player.scheduleFile(file, at: nil) {
                DispatchQueue.main.async {
                    self.engine.detach(player)
                    self.player = nil
                    self.isPlaying = false
                    completion?()
                }
            }
            try engine.start()
            player.play()
            isPlaying = true
        } catch {
            print("Playback error: \(error)")
        }
    }
    /// Stop playback
    public func stopPlayback() {
        player?.stop()
        if let player = player {
            engine.detach(player)
        }
        player = nil
        isPlaying = false
    }
    /// Export the last recording to a user-selected location
    public func exportRecording() {
        guard let url = recordingURL, FileManager.default.fileExists(atPath: url.path) else {
            print("No recording to export.")
            return
        }
        let panel = NSSavePanel()
        if #available(macOS 12.0, *) {
            panel.allowedContentTypes = [.wav]
        } else {
            panel.allowedFileTypes = ["wav"]
        }
        panel.nameFieldStringValue = "PadPlayRecording.wav"
        panel.begin { result in
            if result == .OK, let dest = panel.url {
                do {
                    try FileManager.default.copyItem(at: url, to: dest)
                } catch {
                    print("Export error: \(error)")
                }
            } else if result != .OK {
                print("Save panel was not displayed or was cancelled.")
            }
        }
    }
    /// Returns true if a recording is available
    public func hasRecording() -> Bool {
        guard let url = recordingURL else { return false }
        return FileManager.default.fileExists(atPath: url.path)
    }
} 