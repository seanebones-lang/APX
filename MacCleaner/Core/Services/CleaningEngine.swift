//
//  CleaningEngine.swift
//  MacCleaner
//
//  Core engine that coordinates all scanning and cleaning operations
//

import Foundation
import Combine

@MainActor
class CleaningEngine: ObservableObject {
    static let shared = CleaningEngine()
    
    @Published var scanProgress: Double = 0.0
    @Published var scanStatus: String = ""
    @Published var filesScanned: Int = 0
    @Published var isScanning: Bool = false
    @Published var isCleaning: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    private var scanTask: Task<Void, Never>?
    
    private init() {}
    
    // MARK: - Smart Scan
    
    func performSmartScan() async -> SmartScanResults {
        isScanning = true
        scanProgress = 0.0
        filesScanned = 0
        
        SoundManager.shared.play(.scanStart)
        
        var results = SmartScanResults()
        
        // Scan all modules in parallel
        async let systemJunkResults = scanSystemJunk()
        async let photoResults = scanPhotos()
        async let largeFilesResults = scanLargeFiles()
        async let mailResults = scanMailAttachments()
        async let trashResults = scanTrash()
        async let browserResults = scanBrowserData()
        
        results.systemJunk = await systemJunkResults
        scanProgress = 0.16
        
        results.photoIssues = await photoResults
        scanProgress = 0.33
        
        results.largeFiles = await largeFilesResults
        scanProgress = 0.50
        
        results.mailAttachments = await mailResults
        scanProgress = 0.66
        
        results.trashItems = await trashResults
        scanProgress = 0.83
        
        results.browserData = await browserResults
        scanProgress = 1.0
        
        isScanning = false
        SoundManager.shared.play(.scanComplete)
        
        return results
    }
    
    // MARK: - Individual Module Scans
    
    func scanSystemJunk() async -> [ScanResult] {
        scanStatus = "Scanning System Junk..."
        return await SystemJunkScanner.shared.scan()
    }
    
    func scanPhotos() async -> [ScanResult] {
        scanStatus = "Scanning Photos..."
        return await PhotoScanner.shared.scan()
    }
    
    func scanLargeFiles() async -> [ScanResult] {
        scanStatus = "Scanning Large Files..."
        return await LargeFileScanner.shared.scan()
    }
    
    func scanMailAttachments() async -> [ScanResult] {
        scanStatus = "Scanning Mail Attachments..."
        return await MailScanner.shared.scan()
    }
    
    func scanTrash() async -> [ScanResult] {
        scanStatus = "Scanning Trash Bins..."
        return await TrashScanner.shared.scan()
    }
    
    func scanBrowserData() async -> [ScanResult] {
        scanStatus = "Scanning Browser Data..."
        return await BrowserScanner.shared.scan()
    }
    
    // MARK: - Cleaning
    
    func cleanItems(_ items: [ScanResult], secureDelete: Bool = false) async throws {
        isCleaning = true
        SoundManager.shared.play(.cleanStart)
        
        let total = items.count
        var cleaned = 0
        
        for item in items where item.isSelected {
            try await deleteFile(at: item.path, secure: secureDelete)
            cleaned += 1
            
            // Update progress
            let progress = Double(cleaned) / Double(total)
            await MainActor.run {
                self.scanProgress = progress
            }
            
            // Play tick sound every 10 files
            if cleaned % 10 == 0 {
                SoundManager.shared.play(.cleanProgress)
            }
        }
        
        isCleaning = false
        SoundManager.shared.play(.cleanComplete)
    }
    
    private func deleteFile(at path: String, secure: Bool) async throws {
        if secure {
            // Use helper tool for secure deletion
            try await PrivilegeManager.shared.secureDelete(path: path)
        } else {
            // Regular deletion
            try FileManager.default.trashItem(at: URL(fileURLWithPath: path), resultingItemURL: nil)
        }
    }
    
    // MARK: - Cancel Operations
    
    func cancelAllOperations() {
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
        isCleaning = false
    }
}

