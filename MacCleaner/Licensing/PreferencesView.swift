//
//  PreferencesView.swift
//  MacCleaner
//

import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var soundManager: SoundManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Preferences")
                .font(.title2.bold())
                .padding(.top)
            
            Form {
                Section("Sound") {
                    Toggle("Enable Sounds", isOn: $soundManager.isEnabled)
                    
                    HStack {
                        Text("Volume")
                        Slider(value: $soundManager.volume, in: 0...1)
                    }
                }
                
                Section("Menu Bar") {
                    Toggle("Show Menu Bar Monitor", isOn: .constant(false))
                }
            }
            .formStyle(.grouped)
            
            Button("Done") {
                soundManager.savePreferences()
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding(.bottom)
        }
        .frame(width: 400, height: 300)
    }
}

