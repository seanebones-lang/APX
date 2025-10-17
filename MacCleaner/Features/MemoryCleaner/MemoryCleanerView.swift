//
//  MemoryCleanerView.swift
//  MacCleaner
//

import SwiftUI

struct MemoryCleanerView: View {
    @StateObject private var viewModel = MemoryCleanerViewModel()
    @EnvironmentObject var soundManager: SoundManager
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Image(systemName: "memorychip.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.mint, Color.teal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Memory Cleaner")
                    .font(.system(size: 32, weight: .bold))
                
                Text("Free up RAM and improve performance")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            VStack(spacing: 20) {
                HStack(spacing: 40) {
                    MemoryStatCard(
                        title: "Total Memory",
                        value: viewModel.formattedTotalMemory,
                        icon: "memorychip",
                        color: .blue
                    )
                    
                    MemoryStatCard(
                        title: "Used Memory",
                        value: viewModel.formattedUsedMemory,
                        icon: "chart.bar.fill",
                        color: .orange
                    )
                    
                    MemoryStatCard(
                        title: "Free Memory",
                        value: viewModel.formattedFreeMemory,
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                }
                .padding(.horizontal, 40)
                
                Button(action: {
                    soundManager.play(.buttonClick)
                    Task {
                        await viewModel.freeMemory()
                    }
                }) {
                    HStack {
                        if viewModel.isCleaning {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "memorychip")
                        }
                        Text(viewModel.isCleaning ? "Freeing Memory..." : "Free Memory")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 250, height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.mint, Color.teal],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(28)
                    .shadow(color: .black.opacity(0.2), radius: 15, y: 8)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(viewModel.isCleaning)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .onAppear {
            viewModel.updateMemoryStats()
        }
        .alert("Success", isPresented: $viewModel.showSuccessAlert) {
            Button("OK") { viewModel.showSuccessAlert = false }
        } message: {
            Text("Memory freed successfully")
        }
    }
}

struct MemoryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
    }
}

@MainActor
class MemoryCleanerViewModel: ObservableObject {
    @Published var totalMemory: Int64 = 0
    @Published var usedMemory: Int64 = 0
    @Published var freeMemory: Int64 = 0
    @Published var isCleaning = false
    @Published var showSuccessAlert = false
    
    var formattedTotalMemory: String {
        ByteCountFormatter.string(fromByteCount: totalMemory, countStyle: .memory)
    }
    
    var formattedUsedMemory: String {
        ByteCountFormatter.string(fromByteCount: usedMemory, countStyle: .memory)
    }
    
    var formattedFreeMemory: String {
        ByteCountFormatter.string(fromByteCount: freeMemory, countStyle: .memory)
    }
    
    func updateMemoryStats() {
        var size: UInt64 = 0
        var sizeLen = MemoryLayout.size(ofValue: size)
        sysctlbyname("hw.memsize", &size, &sizeLen, nil, 0)
        totalMemory = Int64(size)
        
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let _ = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        usedMemory = Int64(info.resident_size)
        freeMemory = totalMemory - usedMemory
    }
    
    func freeMemory() async {
        isCleaning = true
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/purge")
        
        do {
            try task.run()
            task.waitUntilExit()
            
            try await Task.sleep(nanoseconds: 2_000_000_000)
            
            updateMemoryStats()
            showSuccessAlert = true
            SoundManager.shared.play(.success)
        } catch {
            SoundManager.shared.play(.error)
        }
        
        isCleaning = false
    }
}

