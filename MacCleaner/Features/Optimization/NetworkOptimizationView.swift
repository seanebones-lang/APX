//
//  NetworkOptimizationView.swift
//  MacCleaner
//

import SwiftUI

struct NetworkOptimizationView: View {
    @StateObject private var viewModel = NetworkOptimizationViewModel()
    @EnvironmentObject var soundManager: SoundManager
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Image(systemName: "network")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.cyan, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Network Optimization")
                    .font(.system(size: 32, weight: .bold))
                
                Text("Optimize DNS settings and network performance")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            VStack(spacing: 16) {
                NetworkTaskRow(
                    title: "Flush DNS Cache",
                    description: "Clear DNS cache to resolve connection issues",
                    icon: "arrow.clockwise",
                    isRunning: viewModel.isFlushingDNS,
                    onRun: {
                        soundManager.play(.buttonClick)
                        Task { await viewModel.flushDNS() }
                    }
                )
                
                NetworkTaskRow(
                    title: "Use Cloudflare DNS",
                    description: "Switch to Cloudflare DNS (1.1.1.1) for faster browsing",
                    icon: "cloud",
                    isRunning: viewModel.isChangingDNS,
                    onRun: {
                        soundManager.play(.buttonClick)
                        Task { await viewModel.setCloudfareDNS() }
                    }
                )
                
                NetworkTaskRow(
                    title: "Use Google DNS",
                    description: "Switch to Google DNS (8.8.8.8) for reliable performance",
                    icon: "globe",
                    isRunning: viewModel.isChangingDNS,
                    onRun: {
                        soundManager.play(.buttonClick)
                        Task { await viewModel.setGoogleDNS() }
                    }
                )
                
                NetworkTaskRow(
                    title: "Reset Network Settings",
                    description: "Reset all network settings to defaults",
                    icon: "arrow.counterclockwise",
                    isRunning: viewModel.isResetting,
                    onRun: {
                        soundManager.play(.buttonClick)
                        Task { await viewModel.resetNetworkSettings() }
                    }
                )
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .alert("Success", isPresented: $viewModel.showSuccessAlert) {
            Button("OK") { viewModel.showSuccessAlert = false }
        } message: {
            Text(viewModel.alertMessage)
        }
        .alert("Error", isPresented: $viewModel.showErrorAlert) {
            Button("OK") { viewModel.showErrorAlert = false }
        } message: {
            Text(viewModel.alertMessage)
        }
    }
}

struct NetworkTaskRow: View {
    let title: String
    let description: String
    let icon: String
    let isRunning: Bool
    let onRun: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.cyan)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isRunning {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Button(action: onRun) {
                    Text("Run")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.cyan)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

@MainActor
class NetworkOptimizationViewModel: ObservableObject {
    @Published var isFlushingDNS = false
    @Published var isChangingDNS = false
    @Published var isResetting = false
    @Published var showSuccessAlert = false
    @Published var showErrorAlert = false
    @Published var alertMessage = ""
    
    func flushDNS() async {
        isFlushingDNS = true
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/dscacheutil")
        task.arguments = ["-flushcache"]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                let task2 = Process()
                task2.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
                task2.arguments = ["-HUP", "mDNSResponder"]
                try? task2.run()
                task2.waitUntilExit()
                
                alertMessage = "DNS cache flushed successfully"
                showSuccessAlert = true
                SoundManager.shared.play(.success)
            } else {
                throw NSError(domain: "NetworkError", code: -1)
            }
        } catch {
            alertMessage = "Failed to flush DNS cache. Administrator privileges may be required."
            showErrorAlert = true
            SoundManager.shared.play(.error)
        }
        isFlushingDNS = false
    }
    
    func setCloudfareDNS() async {
        isChangingDNS = true
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        task.arguments = ["-setdnsservers", "Wi-Fi", "1.1.1.1", "1.0.0.1"]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                alertMessage = "DNS changed to Cloudflare (1.1.1.1)"
                showSuccessAlert = true
                SoundManager.shared.play(.success)
            } else {
                throw NSError(domain: "NetworkError", code: -1)
            }
        } catch {
            alertMessage = "Failed to change DNS. Administrator privileges required."
            showErrorAlert = true
            SoundManager.shared.play(.error)
        }
        isChangingDNS = false
    }
    
    func setGoogleDNS() async {
        isChangingDNS = true
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        task.arguments = ["-setdnsservers", "Wi-Fi", "8.8.8.8", "8.8.4.4"]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                alertMessage = "DNS changed to Google (8.8.8.8)"
                showSuccessAlert = true
                SoundManager.shared.play(.success)
            } else {
                throw NSError(domain: "NetworkError", code: -1)
            }
        } catch {
            alertMessage = "Failed to change DNS. Administrator privileges required."
            showErrorAlert = true
            SoundManager.shared.play(.error)
        }
        isChangingDNS = false
    }
    
    func resetNetworkSettings() async {
        isResetting = true
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/sbin/networksetup")
        task.arguments = ["-setdnsservers", "Wi-Fi", "Empty"]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                alertMessage = "Network settings reset to defaults"
                showSuccessAlert = true
                SoundManager.shared.play(.success)
            } else {
                throw NSError(domain: "NetworkError", code: -1)
            }
        } catch {
            alertMessage = "Failed to reset network settings. Administrator privileges required."
            showErrorAlert = true
            SoundManager.shared.play(.error)
        }
        isResetting = false
    }
}

