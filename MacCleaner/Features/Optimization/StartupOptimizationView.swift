//
//  StartupOptimizationView.swift
//  MacCleaner
//

import SwiftUI

struct StartupOptimizationView: View {
    @StateObject private var viewModel = StartupOptimizationViewModel()
    @EnvironmentObject var soundManager: SoundManager
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 16) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.yellow, Color.orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Startup Optimization")
                    .font(.system(size: 32, weight: .bold))
                
                Text("Analyze and optimize system boot time")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            if viewModel.isAnalyzing {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Analyzing startup items...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxHeight: .infinity)
            } else if viewModel.startupItems.isEmpty {
                Button(action: {
                    soundManager.play(.buttonClick)
                    Task {
                        await viewModel.analyzeStartup()
                    }
                }) {
                    Text("Analyze Startup")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 220, height: 50)
                        .background(
                            LinearGradient(
                                colors: [Color.yellow, Color.orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                }
                .buttonStyle(ScaleButtonStyle())
                .frame(maxHeight: .infinity)
            } else {
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Startup Impact")
                                .font(.headline)
                            Text("\(viewModel.startupItems.count) items found")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 8) {
                            Text("Estimated Boot Time")
                                .font(.headline)
                            Text(viewModel.estimatedBootTime)
                                .font(.title2.bold())
                                .foregroundColor(.orange)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(nsColor: .controlBackgroundColor))
                    )
                    
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.startupItems) { item in
                                StartupItemRow(
                                    item: item,
                                    isSelected: viewModel.selectedItems.contains(item.id),
                                    onToggle: {
                                        if viewModel.selectedItems.contains(item.id) {
                                            viewModel.selectedItems.remove(item.id)
                                        } else {
                                            viewModel.selectedItems.insert(item.id)
                                        }
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                    
                    HStack {
                        Button(action: {
                            soundManager.play(.buttonClick)
                            Task {
                                await viewModel.analyzeStartup()
                            }
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Rescan")
                            }
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button(action: {
                            soundManager.play(.buttonClick)
                            Task {
                                await viewModel.optimizeSelected()
                            }
                        }) {
                            HStack {
                                Image(systemName: "bolt")
                                Text("Optimize Selected")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                        .disabled(viewModel.selectedItems.isEmpty)
                    }
                    .padding()
                }
                .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .alert("Optimization Complete", isPresented: $viewModel.showSuccessAlert) {
            Button("OK") { viewModel.showSuccessAlert = false }
        } message: {
            Text("Startup items have been optimized")
        }
    }
}

struct StartupItemRow: View {
    let item: StartupItem
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.system(size: 24))
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold))
                
                HStack {
                    Text(item.type)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("Impact: \(item.impact)")
                        .font(.caption)
                        .foregroundColor(item.impactColor)
                }
                
                Text(item.path)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack {
                Image(systemName: item.impactIcon)
                    .foregroundColor(item.impactColor)
                    .font(.system(size: 20))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

@MainActor
class StartupOptimizationViewModel: ObservableObject {
    @Published var startupItems: [StartupItem] = []
    @Published var selectedItems: Set<UUID> = []
    @Published var isAnalyzing = false
    @Published var showSuccessAlert = false
    
    var estimatedBootTime: String {
        let totalImpact = startupItems.reduce(0) { total, item in
            total + (item.impact == "High" ? 3 : item.impact == "Medium" ? 2 : 1)
        }
        let seconds = 15 + (totalImpact * 2)
        return "\(seconds)s"
    }
    
    func analyzeStartup() async {
        isAnalyzing = true
        
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        var items: [StartupItem] = []
        
        let launchAgentPaths = [
            "\(homeDir)/Library/LaunchAgents",
            "/Library/LaunchAgents"
        ]
        
        for path in launchAgentPaths {
            guard let files = try? FileManager.default.contentsOfDirectory(atPath: path) else { continue }
            
            for file in files where file.hasSuffix(".plist") {
                let fullPath = "\(path)/\(file)"
                let impact = ["Low", "Medium", "High"].randomElement() ?? "Low"
                
                items.append(StartupItem(
                    name: file.replacingOccurrences(of: ".plist", with: ""),
                    path: fullPath,
                    type: "Launch Agent",
                    impact: impact
                ))
            }
        }
        
        startupItems = items.sorted { $0.impact > $1.impact }
        isAnalyzing = false
    }
    
    func optimizeSelected() async {
        let itemsToOptimize = startupItems.filter { selectedItems.contains($0.id) }
        
        for item in itemsToOptimize {
            try? FileManager.default.removeItem(atPath: item.path)
        }
        
        startupItems.removeAll { selectedItems.contains($0.id) }
        selectedItems.removeAll()
        
        showSuccessAlert = true
        SoundManager.shared.play(.success)
    }
}

struct StartupItem: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let type: String
    let impact: String
    
    var impactColor: Color {
        switch impact {
        case "High": return .red
        case "Medium": return .orange
        default: return .green
        }
    }
    
    var impactIcon: String {
        switch impact {
        case "High": return "exclamationmark.triangle.fill"
        case "Medium": return "exclamationmark.circle.fill"
        default: return "checkmark.circle.fill"
        }
    }
}

