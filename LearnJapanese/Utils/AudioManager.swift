//
//  AudioManager.swift
//  LearnJapanese
//
//  Created by Trung Hiếu on 2025/06/15.
//

// Utils/AudioManager.swift
import AVFoundation
import SwiftUI

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    @Published var isSoundEnabled = true
    @Published var soundVolume: Float = 0.7
    
    // Sound effects mapping
    enum SoundEffect: String, CaseIterable {
        case buttonTap = "button_tap"
        case correctAnswer = "correct_answer"
        case incorrectAnswer = "incorrect_answer"
        case quizComplete = "quiz_complete"
        case timeUp = "time_up"
        case timerTick = "timer_tick"
        
        var fileName: String {
            switch self {
            case .buttonTap: return "button_tap.mp3"
            case .correctAnswer: return "correct_answer.wav"
            case .incorrectAnswer: return "incorrect_answer.wav"
            case .quizComplete: return "quiz_complete.ogg"
            case .timeUp: return "time_up.wav"
            case .timerTick: return "timer_tick.wav"
            }
        }
    }
    
    private init() {
        setupAudioSession()
        loadSounds()
        loadSettings()
    }
    
    // MARK: - Setup
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .ambient,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ Audio session setup thành công")
        } catch {
            print("❌ Lỗi setup audio session: \(error)")
        }
    }
    
    private func loadSounds() {
        for soundEffect in SoundEffect.allCases {
            loadSound(soundEffect)
        }
    }
    
    private func loadSound(_ soundEffect: SoundEffect) {
        guard let url = Bundle.main.url(forResource: soundEffect.rawValue, withExtension: getFileExtension(soundEffect.fileName)) else {
            print("❌ Không tìm thấy file âm thanh: \(soundEffect.fileName)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.volume = soundVolume
            audioPlayers[soundEffect.rawValue] = player
            print("✅ Loaded sound: \(soundEffect.fileName)")
        } catch {
            print("❌ Lỗi load âm thanh \(soundEffect.fileName): \(error)")
        }
    }
    
    // MARK: - Playback
    func playSound(_ soundEffect: SoundEffect, volume: Float? = nil) {
        guard isSoundEnabled else { return }
        
        guard let player = audioPlayers[soundEffect.rawValue] else {
            print("❌ Không tìm thấy audio player cho: \(soundEffect.rawValue)")
            return
        }
        
        // Set volume
        player.volume = volume ?? soundVolume
        
        // Stop current playback and restart
        player.stop()
        player.currentTime = 0
        player.play()
        
        print("🔊 Playing sound: \(soundEffect.rawValue)")
    }
    
    // MARK: - Special Cases
    func playTimerTickLoop() {
        guard isSoundEnabled else { return }
        
        guard let player = audioPlayers[SoundEffect.timerTick.rawValue] else { return }
        
        player.volume = soundVolume * 0.3 // Giảm âm lượng cho timer tick
        player.numberOfLoops = -1 // Loop vô hạn
        player.play()
    }
    
    func stopTimerTick() {
        guard let player = audioPlayers[SoundEffect.timerTick.rawValue] else { return }
        player.stop()
        player.numberOfLoops = 0
    }
    
    func playCorrectWithDelay(_ delay: TimeInterval = 0.2) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.playSound(.correctAnswer)
        }
    }
    
    func playIncorrectWithDelay(_ delay: TimeInterval = 0.2) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.playSound(.incorrectAnswer)
        }
    }
    
    // MARK: - Settings
    func setSoundEnabled(_ enabled: Bool) {
        isSoundEnabled = enabled
        saveSettings()
        
        if !enabled {
            stopAllSounds()
        }
        
        print("🔊 Sound \(enabled ? "enabled" : "disabled")")
    }
    
    func setSoundVolume(_ volume: Float) {
        soundVolume = max(0.0, min(1.0, volume))
        
        // Update all players volume
        for player in audioPlayers.values {
            player.volume = soundVolume
        }
        
        saveSettings()
        print("🔊 Sound volume set to: \(Int(soundVolume * 100))%")
    }
    
    func stopAllSounds() {
        for player in audioPlayers.values {
            player.stop()
        }
    }
    
    // MARK: - Settings Persistence
    private func loadSettings() {
        isSoundEnabled = UserDefaults.standard.object(forKey: "quiz_sound_enabled") as? Bool ?? true
        soundVolume = UserDefaults.standard.object(forKey: "quiz_sound_volume") as? Float ?? 0.7
        
        print("🔊 Loaded settings - Enabled: \(isSoundEnabled), Volume: \(Int(soundVolume * 100))%")
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(isSoundEnabled, forKey: "quiz_sound_enabled")
        UserDefaults.standard.set(soundVolume, forKey: "quiz_sound_volume")
    }
    
    // MARK: - Helper
    private func getFileExtension(_ fileName: String) -> String {
        return (fileName as NSString).pathExtension
    }
}

// MARK: - QuizViewModel Extension để tích hợp âm thanh
extension QuizViewModel {
    
    func playAnswerSound(isCorrect: Bool) {
        if isCorrect {
            AudioManager.shared.playCorrectWithDelay(0.1)
        } else {
            AudioManager.shared.playIncorrectWithDelay(0.1)
        }
    }
    
    func playQuizCompleteSound() {
        AudioManager.shared.playSound(.quizComplete)
    }
    
    func playTimeUpSound() {
        AudioManager.shared.playSound(.timeUp)
    }
    
    func playButtonTapSound() {
        AudioManager.shared.playSound(.buttonTap, volume: 0.4)
    }
    
    func startTimerTickSound() {
        // Chỉ bật timer tick khi còn <= 10 giây
        if timeRemaining <= 10 {
            AudioManager.shared.playTimerTickLoop()
        }
    }
    
    func stopTimerTickSound() {
        AudioManager.shared.stopTimerTick()
    }
}
