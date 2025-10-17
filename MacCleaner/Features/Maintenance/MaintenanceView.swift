//
//  MaintenanceView.swift
//  MacCleaner
//

import SwiftUI

struct MaintenanceView: View {
    @StateObject private var viewModel = MaintenanceViewModel()
    @EnvironmentObject var soundManager: SoundManager
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.green, Color.teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Maintenance")
                    .font(.system(size: 32, weight: .bold))
                
                Text("Run system maintenance tasks")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            VStack(spacing: 16) {
                MaintenanceTaskRow(
                    title: "Repair Disk Permissions",
                    description: "Fix file and folder permissions",
                    icon: "lock.shield",
                    isRunning: viewModel.isRunningRepair,
                    onRun: {
                        soundManager.play(.buttonClick)
                        Task { await viewModel.repairPermissions() }
                    }
                )
                
                MaintenanceTaskRow(
                    title: "Rebuild Spotlight Index",
                    description: "Rebuild the Spotlight search index",
                    icon: "magnifyingglass",
                    isRunning: viewModel.isRebuildingSpotlight,
                    onRun: {
                        soundManager.play(.buttonClick)
                        Task { await viewModel.rebuildSpotlight() }
                    }
                )
                
                MaintenanceTaskRow(
                    title: "Run Maintenance Scripts",
                    description: "Execute periodic maintenance scripts",
                    icon: "terminal",
                    isRunning: viewModel.isRunningScripts,
                    onRun: {
                        soundManager.play(.buttonClick)
                        Task { await viewModel.runMaintenanceScripts() }
                    }
                )
                
                MaintenanceTaskRow(
                    title: "Clear DNS Cache",
                    description: "Flush DNS cache and reset network settings",
                    icon: "network",
                    isRunning: viewModel.isClearingDNS,
                    onRun: {
                        soundManager.play(.buttonClick)
                        Task { await viewModel.clearDNSCache() }
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

struct MaintenanceTaskRow: View {
    let title: String
    let description: String
    let icon: String
    let isRunning: Bool
    let onRun: () -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.green)
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
                        .background(Color.green)
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
class MaintenanceViewModel: ObservableObject {
    @Published var isRunningRepair = false
    @Published var isRebuildingSpotlight = false
    @Published var isRunningScripts = false
    @Published var isClearingDNS = false
    @Published var showSuccessAlert = false
    @Published var showErrorAlert = false
    @Published var alertMessage = ""
    
    func repairPermissions() async {
        isRunningRepair = true
        do {
            try await PrivilegeManager.shared.repairPermissions()
            alertMessage = "Disk permissions repaired successfully"
            showSuccessAlert = true
            SoundManager.shared.play(.success)
        } catch {
            alertMessage = "Failed to repair permissions: \(error.localizedDescription)"
            showErrorAlert = true
            SoundManager.shared.play(.error)
        }
        isRunningRepair = false
    }
    
    func rebuildSpotlight() async {
        isRebuildingSpotlight = true
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/mdutil")
        task.arguments = ["-E", "/"]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                alertMessage = "Spotlight index rebuild initiated"
                showSuccessAlert = true
                SoundManager.shared.play(.success)
            } else {
                throw NSError(domain: "MaintenanceError", code: -1)
            }
        } catch {
            alertMessage = "Failed to rebuild Spotlight index"
            showErrorAlert = true
            SoundManager.shared.play(.error)
        }
        isRebuildingSpotlight = false
    }
    
    func runMaintenanceScripts() async {
        isRunningScripts = true
        do {
            try await withTimeout(seconds: 60) {
                let scripts = ["daily", "weekly", "monthly"]
                for script in scripts {
                    let task = Process()
                    task.executableURL = URL(fileURLWithPath: "/usr/sbin/periodic")
                    task.arguments = [script]
                    try task.run()
                    task.waitUntilExit()
                }
            }
            
            alertMessage = "Maintenance scripts completed"
            showSuccessAlert = true
            SoundManager.shared.play(.success)
        } catch {
            alertMessage = "Failed to run maintenance scripts"
            showErrorAlert = true
            SoundManager.shared.play(.error)
        }
        isRunningScripts = false
    }
    
    func clearDNSCache() async {
        isClearingDNS = true
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/dscacheutil")
        task.arguments = ["-flushcache"]
        
        do {
            try task.run()
            task.waitUntilExit()
            
            if task.terminationStatus == 0 {
                alertMessage = "DNS cache cleared successfully"
                showSuccessAlert = true
                SoundManager.shared.play(.success)
            } else {
                throw NSError(domain: "MaintenanceError", code: -1)
            }
        } catch {
            alertMessage = "Failed to clear DNS cache"
            showErrorAlert = true
            SoundManager.shared.play(.error)
        }
        isClearingDNS = false
    }
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw NSError(domain: "TimeoutError", code: -1)
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

