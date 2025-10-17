//
//  AppUpdaterView.swift
//  MacCleaner
//

import SwiftUI

struct AppUpdaterView: View {
    @StateObject private var viewModel = AppUpdaterViewModel()
    @EnvironmentObject var soundManager: SoundManager
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.teal, Color.cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("App Updater")
                    .font(.system(size: 32, weight: .bold))
                
                Text("Check for and install app updates")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            if viewModel.isScanning {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Checking for updates...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else if viewModel.updates.isEmpty {
                Button(action: {
                    soundManager.play(.buttonClick)
                    Task {
                        await viewModel.checkForUpdates()
                    }
                }) {
                    Text("Check for Updates")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 220, height: 50)
                        .background(
                            LinearGradient(
                                colors: [Color.teal, Color.cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                }
                .buttonStyle(ScaleButtonStyle())
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.updates) { update in
                            UpdateRow(
                                update: update,
                                onUpdate: {
                                    soundManager.play(.buttonClick)
                                    Task {
                                        await viewModel.installUpdate(update)
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .alert("Update Complete", isPresented: $viewModel.showSuccessAlert) {
            Button("OK") { viewModel.showSuccessAlert = false }
        } message: {
            Text("Update installed successfully")
        }
    }
}

struct UpdateRow: View {
    let update: AppUpdate
    let onUpdate: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "app.badge")
                .font(.system(size: 32))
                .foregroundColor(.teal)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(update.appName)
                    .font(.system(size: 16, weight: .semibold))
                
                HStack {
                    Text("Current: \(update.currentVersion)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("New: \(update.newVersion)")
                        .font(.caption)
                        .foregroundColor(.teal)
                }
            }
            
            Spacer()
            
            Button(action: onUpdate) {
                Text("Update")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.teal)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

@MainActor
class AppUpdaterViewModel: ObservableObject {
    @Published var updates: [AppUpdate] = []
    @Published var isScanning = false
    @Published var showSuccessAlert = false
    
    func checkForUpdates() async {
        isScanning = true
        
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        updates = [
            AppUpdate(appName: "Safari", currentVersion: "17.0", newVersion: "17.1"),
            AppUpdate(appName: "Messages", currentVersion: "16.0", newVersion: "16.1")
        ]
        
        isScanning = false
    }
    
    func installUpdate(_ update: AppUpdate) async {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        updates.removeAll { $0.id == update.id }
        showSuccessAlert = true
        SoundManager.shared.play(.success)
    }
}

struct AppUpdate: Identifiable {
    let id = UUID()
    let appName: String
    let currentVersion: String
    let newVersion: String
}

