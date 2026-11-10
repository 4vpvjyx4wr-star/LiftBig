import AVFoundation
import CoreHaptics
import Flutter
import Foundation

/// Playback session that ducks other audio for the rest alarm, then hands the
/// volume back. A silent loop keeps the process alive while rest is running
/// so the tone can play in the background. This is not a Clock.app alarm and
/// it does not take exclusive focus.
final class RestAlarmPlayer: NSObject, AVAudioPlayerDelegate {
    static let shared = RestAlarmPlayer()

    private var silentPlayer: AVAudioPlayer?
    private var alarmPlayer: AVAudioPlayer?
    private var hapticEngine: CHHapticEngine?
    private var playingAlarm = false
    private var sessionActive = false

    static func register(messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(name: "liftbig/rest_alarm", binaryMessenger: messenger)
        channel.setMethodCallHandler { call, result in
            switch call.method {
            case "deviceTimeZone":
                result(TimeZone.current.identifier)
            case "startKeepAlive":
                shared.startKeepAlive(result: result)
            case "stopKeepAlive":
                shared.stopKeepAlive(result: result)
            case "play":
                shared.play(result: result)
            case "haptic":
                shared.playHaptic(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func startKeepAlive(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            if self.playingAlarm {
                result(true)
                return
            }
            do {
                try self.activateSilent()
                result(true)
            } catch {
                result(false)
            }
        }
    }

    private func stopKeepAlive(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            self.deactivate()
            result(true)
        }
    }

    private func play(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            let session = AVAudioSession.sharedInstance()
            do {
                self.silentPlayer?.stop()
                try session.setCategory(.playback, mode: .default, options: [.duckOthers])
                try session.setActive(true)
                self.sessionActive = true
                let data = self.bundledAlarm() ?? Self.alarmWav()
                let player = try AVAudioPlayer(data: data)
                player.delegate = self
                player.prepareToPlay()
                self.alarmPlayer = player
                self.playingAlarm = true
                guard player.play() else {
                    self.deactivate()
                    result(false)
                    return
                }
                result(true)
            } catch {
                self.deactivate()
                result(false)
            }
        }
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard player === alarmPlayer else { return }
        deactivate()
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        guard player === alarmPlayer else { return }
        deactivate()
    }

    private func activateSilent() throws {
        let session = AVAudioSession.sharedInstance()
        // Mix, so the countdown does not dip or stop Music. The alarm ducks later.
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
        sessionActive = true
        if silentPlayer == nil {
            let player = try AVAudioPlayer(data: Self.silentWav())
            player.numberOfLoops = -1
            player.volume = 0.01
            player.prepareToPlay()
            silentPlayer = player
        }
        silentPlayer?.play()
    }

    private func deactivate() {
        silentPlayer?.stop()
        silentPlayer = nil
        alarmPlayer?.stop()
        alarmPlayer = nil
        playingAlarm = false
        guard sessionActive else { return }
        sessionActive = false
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }

    private func bundledAlarm() -> Data? {
        guard let url = Bundle.main.url(forResource: "rest_alarm", withExtension: "wav") else {
            return nil
        }
        return try? Data(contentsOf: url)
    }

    private func playHaptic(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
                result(false)
                return
            }
            do {
                let engine = try self.prepareHaptics()
                let pattern = try CHHapticPattern(events: Self.restHapticEvents(), parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try engine.start()
                try player.start(atTime: CHHapticTimeImmediate)
                result(true)
            } catch {
                self.hapticEngine = nil
                result(false)
            }
        }
    }

    private func prepareHaptics() throws -> CHHapticEngine {
        if let hapticEngine { return hapticEngine }
        let engine = try CHHapticEngine()
        engine.isAutoShutdownEnabled = true
        engine.resetHandler = { [weak self] in
            self?.hapticEngine = nil
        }
        hapticEngine = engine
        return engine
    }

    /// A few seconds of sharp taps over a low rumble.
    private static func restHapticEvents() -> [CHHapticEvent] {
        let taps: [(TimeInterval, Float, Float)] = [
            (0.00, 1.0, 0.8),
            (0.22, 0.85, 0.45),
            (0.48, 1.0, 0.9),
            (0.74, 0.75, 0.5),
            (1.05, 1.0, 0.85),
            (1.32, 0.9, 0.6),
            (1.68, 1.0, 1.0),
            (1.98, 0.8, 0.55),
            (2.30, 1.0, 0.9),
        ]
        var events = taps.map { tap in
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: tap.1),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: tap.2),
                ],
                relativeTime: tap.0
            )
        }
        events.append(
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.55),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25),
                ],
                relativeTime: 0.30,
                duration: 1.9
            )
        )
        return events
    }

    /// Nearly silent loop. The playback category is what keeps the isolate up.
    private static func silentWav() -> Data {
        let sampleRate = 22050
        let count = sampleRate / 2
        var samples = [Int16](repeating: 0, count: count)
        for index in 0..<count {
            let time = Double(index) / Double(sampleRate)
            samples[index] = Int16(sin(2.0 * Double.pi * 40.0 * time) * 40.0)
        }
        return wavData(samples: samples, sampleRate: sampleRate)
    }

    /// Fallback when the bundled file is missing. Matches the shipped tone.
    private static func alarmWav() -> Data {
        let sampleRate = 22050
        let beepSamples = Int(0.18 * Double(sampleRate))
        let gapSamples = Int(0.09 * Double(sampleRate))
        let pulses = 8
        var samples = [Int16]()
        samples.reserveCapacity(pulses * (beepSamples + gapSamples))
        for pulse in 0..<pulses {
            let frequency = pulse % 2 == 0 ? 880.0 : 1174.0
            for index in 0..<beepSamples {
                let time = Double(index) / Double(sampleRate)
                let attack = min(1.0, Double(index) / 200.0)
                let release = min(1.0, Double(beepSamples - index) / 220.0)
                let value = sin(2.0 * Double.pi * frequency * time) * attack * release * 0.9
                samples.append(Int16(max(-1.0, min(1.0, value)) * Double(Int16.max)))
            }
            if pulse + 1 < pulses {
                samples.append(contentsOf: repeatElement(0, count: gapSamples))
            }
        }
        return wavData(samples: samples, sampleRate: sampleRate)
    }

    private static func wavData(samples: [Int16], sampleRate: Int) -> Data {
        let dataSize = samples.count * 2
        var data = Data()
        data.reserveCapacity(44 + dataSize)
        data.append(contentsOf: "RIFF".utf8)
        append32(&data, UInt32(36 + dataSize))
        data.append(contentsOf: "WAVE".utf8)
        data.append(contentsOf: "fmt ".utf8)
        append32(&data, 16)
        append16(&data, 1)
        append16(&data, 1)
        append32(&data, UInt32(sampleRate))
        append32(&data, UInt32(sampleRate * 2))
        append16(&data, 2)
        append16(&data, 16)
        data.append(contentsOf: "data".utf8)
        append32(&data, UInt32(dataSize))
        for sample in samples {
            append16(&data, UInt16(bitPattern: sample))
        }
        return data
    }

    private static func append16(_ data: inout Data, _ value: UInt16) {
        var little = value.littleEndian
        withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
    }

    private static func append32(_ data: inout Data, _ value: UInt32) {
        var little = value.littleEndian
        withUnsafeBytes(of: &little) { data.append(contentsOf: $0) }
    }
}
