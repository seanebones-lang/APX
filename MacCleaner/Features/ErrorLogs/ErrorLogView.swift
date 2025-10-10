//
//  ErrorLogView.swift
//  MacCleaner
//
//  View for Error Log Scanner with analytics
//

import SwiftUI

struct ErrorLogView: View {
    @StateObject private var viewModel = ErrorLogViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.red)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Error Logs")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("Clean crash reports, diagnostic files, and error logs")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !viewModel.isScanning && !viewModel.results.isEmpty {
                    Button("Analyze Errors") {
                        Task {
                            await viewModel.analyzeErrors()
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(30)
            
            Divider()
            
            // Content
            if viewModel.isScanning {
                VStack(spacing: 20) {
                    Spacer()
                    
                    ProgressView()
                        .scaleEffect(1.5)
                    
                    Text("Scanning error logs...")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            } else if viewModel.results.isEmpty {
                VStack(spacing: 24) {
                    Spacer()
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.red.opacity(0.3))
                    
                    Text("No error logs scanned yet")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Button("Scan for Error Logs") {
                        Task {
                            await viewModel.scan()
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(color: .red))
                    
                    Spacer()
                }
            } else {
                VStack(spacing: 0) {
                    // Analysis Section
                    if let analysis = viewModel.analysis {
                        AnalysisView(analysis: analysis)
                            .padding(20)
                        
                        Divider()
                    }
                    
                    // Summary
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(viewModel.results.count) error logs found")
                                .font(.title2.bold())
                            
                            Text(viewModel.formattedSize)
                                .font(.title.bold())
                                .foregroundColor(.red)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Button("Analyze") {
                                Task {
                                    await viewModel.analyzeErrors()
                                }
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Clean Logs") {
                                Task {
                                    try? await viewModel.clean()
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle(color: .red))
                        }
                    }
                    .padding(20)
                    
                    Divider()
                    
                    // Results list with categories
                    List {
                        ForEach(viewModel.categorizedResults.keys.sorted(), id: \.self) { category in
                            Section(header: Text(category).font(.headline)) {
                                ForEach(viewModel.categorizedResults[category] ?? []) { result in
                                    ErrorLogRow(result: result)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct ErrorLogRow: View {
    let result: ScanResult
    
    var body: some View {
        HStack {
            Image(systemName: iconForCategory(result.category))
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(result.filename)
                    .font(.system(size: 14))
                
                HStack(spacing: 8) {
                    Text(result.directory)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    if let modDate = result.modifiedDate {
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(timeAgo(from: modDate))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            Text(result.formattedSize)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func iconForCategory(_ category: String) -> String {
        switch category {
        case "Crash Reports": return "exclamationmark.octagon.fill"
        case "Hang Reports": return "clock.badge.exclamationmark.fill"
        case "Kernel Panic Logs": return "bolt.trianglebadge.exclamationmark.fill"
        case "Diagnostic Reports": return "stethoscope"
        default: return "doc.text.fill"
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let days = Int(interval / (24 * 60 * 60))
        
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "Yesterday"
        } else if days < 7 {
            return "\(days) days ago"
        } else if days < 30 {
            return "\(days / 7) weeks ago"
        } else {
            return "\(days / 30) months ago"
        }
    }
}

struct AnalysisView: View {
    let analysis: ErrorLogAnalysis
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Error Analysis")
                .font(.headline)
            
            HStack(spacing: 30) {
                StatCard(title: "Crashes", value: "\(analysis.totalCrashes)", color: .red)
                StatCard(title: "Hangs", value: "\(analysis.totalHangs)", color: .orange)
                StatCard(title: "Panics", value: "\(analysis.totalPanics)", color: .purple)
            }
            
            if !analysis.topCrashingApps.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Most Affected Apps")
                        .font(.subheadline.bold())
                    
                    ForEach(analysis.topCrashingApps, id: \.0) { app, count in
                        HStack {
                            Text(app)
                                .font(.caption)
                            Spacer()
                            Text("\(count) errors")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                )
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

@MainActor
class ErrorLogViewModel: ObservableObject {
    @Published var isScanning: Bool = false
    @Published var results: [ScanResult] = []
    @Published var analysis: ErrorLogAnalysis?
    
    var totalSize: Int64 {
        results.reduce(0) { $0 + $1.size }
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
    
    var categorizedResults: [String: [ScanResult]] {
        Dictionary(grouping: results) { $0.category }
    }
    
    func scan() async {
        isScanning = true
        results = await ErrorLogScanner.shared.scan()
        isScanning = false
    }
    
    func analyzeErrors() async {
        let paths = results.map { $0.path }
        analysis = await ErrorLogScanner.shared.analyzeErrorLogs(at: paths)
    }
    
    func clean() async throws {
        try await CleaningEngine.shared.cleanItems(results)
        results = []
        analysis = nil
    }
}

