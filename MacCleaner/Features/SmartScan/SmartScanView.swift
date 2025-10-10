//
//  SmartScanView.swift
//  MacCleaner
//
//  The hero feature - Smart Scan with beautiful animations
//

import SwiftUI

struct SmartScanView: View {
    @StateObject private var viewModel = SmartScanViewModel()
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var soundManager: SoundManager
    
    var body: some View {
        ZStack {
            // Background
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()
            
            if let results = viewModel.scanResults {
                // Results View
                ResultsView(results: results, onClean: {
                    Task {
                        await viewModel.cleanSelected()
                    }
                })
            } else {
                // Scan View
                ScanView(viewModel: viewModel)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.scanResults != nil)
    }
}

struct ScanView: View {
    @ObservedObject var viewModel: SmartScanViewModel
    @EnvironmentObject var soundManager: SoundManager
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Title
            if !viewModel.isScanning {
                VStack(spacing: 12) {
                    Text("Smart Scan")
                        .font(.system(size: 36, weight: .bold))
                    
                    Text("Scan your Mac for junk files and free up space")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .transition(.opacity.combined(with: .scale))
            }
            
            // Circular Progress Indicator
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 280, height: 280)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: viewModel.progress)
                    .stroke(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 280, height: 280)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.progress)
                
                // Center content
                VStack(spacing: 12) {
                    if viewModel.isScanning {
                        // Animated scanning icon
                        AnimatedScanIcon()
                        
                        Text("\(Int(viewModel.progress * 100))%")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.purple, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text(viewModel.statusText)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(width: 200)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 64))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.purple, Color.blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Ready to Scan")
                            .font(.title3.bold())
                    }
                }
            }
            
            // Action Button
            Button(action: {
                if viewModel.isScanning {
                    viewModel.cancelScan()
                } else {
                    soundManager.play(.buttonClick)
                    Task {
                        await viewModel.startScan()
                    }
                }
            }) {
                Text(viewModel.isScanning ? "Cancel" : "Start Scan")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 200, height: 50)
                    .background(
                        LinearGradient(
                            colors: viewModel.isScanning ? [Color.red, Color.orange] : [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(25)
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
            }
            .buttonStyle(ScaleButtonStyle())
            
            Spacer()
        }
        .padding()
    }
}

struct ResultsView: View {
    let results: SmartScanResults
    let onClean: () -> Void
    @EnvironmentObject var soundManager: SoundManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header with total
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.green)
                        .symbolEffect(.bounce)
                    
                    Text("Scan Complete!")
                        .font(.system(size: 32, weight: .bold))
                    
                    VStack(spacing: 8) {
                        Text(results.formattedSize)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.orange, Color.red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        
                        Text("can be freed")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(results.totalItems) items found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Result cards
                VStack(spacing: 16) {
                    if !results.systemJunk.isEmpty {
                        ResultCard(
                            title: "System Junk",
                            items: results.systemJunk,
                            icon: "paintbrush.fill",
                            color: .blue
                        )
                    }
                    
                    if !results.photoIssues.isEmpty {
                        ResultCard(
                            title: "Photo Issues",
                            items: results.photoIssues,
                            icon: "camera.fill",
                            color: .pink
                        )
                    }
                    
                    if !results.largeFiles.isEmpty {
                        ResultCard(
                            title: "Large Files",
                            items: results.largeFiles,
                            icon: "doc.fill.badge.magnifyingglass",
                            color: .orange
                        )
                    }
                    
                    if !results.mailAttachments.isEmpty {
                        ResultCard(
                            title: "Mail Attachments",
                            items: results.mailAttachments,
                            icon: "envelope.fill",
                            color: .cyan
                        )
                    }
                    
                    if !results.trashItems.isEmpty {
                        ResultCard(
                            title: "Trash Items",
                            items: results.trashItems,
                            icon: "trash.fill",
                            color: .gray
                        )
                    }
                    
                    if !results.browserData.isEmpty {
                        ResultCard(
                            title: "Browser Data",
                            items: results.browserData,
                            icon: "safari.fill",
                            color: .blue
                        )
                    }
                }
                
                // Clean button
                Button(action: {
                    soundManager.play(.buttonClick)
                    onClean()
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Clean Selected")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: 300, minHeight: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.purple, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(28)
                    .shadow(color: .black.opacity(0.2), radius: 15, y: 8)
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.vertical, 20)
            }
            .padding()
        }
    }
}

struct ResultCard: View {
    let title: String
    let items: [ScanResult]
    let icon: String
    let color: Color
    
    var totalSize: Int64 {
        items.reduce(0) { $0 + $1.size }
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("\(items.count) items • \(formattedSize)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
            )
        }
        .padding(.horizontal)
    }
}

struct AnimatedScanIcon: View {
    @State private var isAnimating = false
    
    var body: some View {
        Image(systemName: "magnifyingglass")
            .font(.system(size: 48))
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.purple, Color.blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .rotationEffect(.degrees(isAnimating ? 360 : 0))
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

@MainActor
class SmartScanViewModel: ObservableObject {
    @Published var isScanning: Bool = false
    @Published var progress: Double = 0.0
    @Published var statusText: String = ""
    @Published var scanResults: SmartScanResults?
    
    private let engine = CleaningEngine.shared
    
    func startScan() async {
        isScanning = true
        progress = 0.0
        scanResults = nil
        
        // Observe engine progress
        let task = Task {
            for await _ in Timer.publish(every: 0.1, on: .main, in: .common).autoconnect().values {
                self.progress = engine.scanProgress
                self.statusText = engine.scanStatus
                
                if !engine.isScanning {
                    break
                }
            }
        }
        
        // Perform scan
        let results = await engine.performSmartScan()
        
        task.cancel()
        
        isScanning = false
        progress = 1.0
        scanResults = results
    }
    
    func cancelScan() {
        engine.cancelAllOperations()
        isScanning = false
        progress = 0.0
        statusText = ""
    }
    
    func cleanSelected() async {
        guard let results = scanResults else { return }
        
        var allItems: [ScanResult] = []
        allItems.append(contentsOf: results.systemJunk)
        allItems.append(contentsOf: results.photoIssues)
        allItems.append(contentsOf: results.largeFiles)
        allItems.append(contentsOf: results.mailAttachments)
        allItems.append(contentsOf: results.trashItems)
        allItems.append(contentsOf: results.browserData)
        
        do {
            try await engine.cleanItems(allItems)
            scanResults = nil
        } catch {
            print("Cleaning failed: \(error)")
        }
    }
}

