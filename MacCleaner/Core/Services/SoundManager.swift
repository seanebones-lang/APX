//
//  SoundManager.swift
//  MacCleaner
//

import AVFoundation
import SwiftUI

class SoundManager: ObservableObject {
    static let shared = SoundManager()
    
    @Published var isEnabled: Bool = true
    @Published var volume: Float = 0.7
    
    private var audioPlayers: [SoundEffect: AVAudioPlayer] = [:]
    
    private init() {
        loadPreferences()
    }
    
    enum SoundEffect: String, CaseIterable {
        case scanStart = "scan_start"
        case scanProgress = "scan_progress"
        case scanComplete = "scan_complete"
        case cleanStart = "clean_start"
        case cleanProgress = "clean_progress"
        case cleanComplete = "clean_complete"
        case buttonClick = "button_click"
        case toggle = "toggle"
        case error = "error"
        case success = "success"
        case whoosh = "whoosh"
        case poof = "poof"
    }
    
    func preloadSounds() {
        for sound in SoundEffect.allCases {
            if let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "mp3") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    player.volume = volume
                    audioPlayers[sound] = player
                } catch {
                    print("Failed to load sound: \(sound.rawValue)")
                }
            }
        }
    }
    
    func play(_ sound: SoundEffect, loop: Bool = false) {
        guard isEnabled else { return }
        
        if let player = audioPlayers[sound] {
            player.currentTime = 0
            player.numberOfLoops = loop ? -1 : 0
            player.volume = volume
            player.play()
        }
    }
    
    func stop(_ sound: SoundEffect) {
        audioPlayers[sound]?.stop()
    }
    
    func stopAll() {
        audioPlayers.values.forEach { $0.stop() }
    }
    
    private func loadPreferences() {
        isEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        volume = UserDefaults.standard.object(forKey: "soundVolume") as? Float ?? 0.7
    }
    
    func savePreferences() {
        UserDefaults.standard.set(isEnabled, forKey: "soundEnabled")
        UserDefaults.standard.set(volume, forKey: "soundVolume")
    }
}

