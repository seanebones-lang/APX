//
//  SystemJunkScanner.swift
//  MacCleaner
//
//  Scans for system junk files (caches, logs, temp files, etc.)
//

import Foundation

class SystemJunkScanner {
    static let shared = SystemJunkScanner()
    
    private init() {}
    
    func scan() async -> [ScanResult] {
        var results: [ScanResult] = []
        
        let scanTasks: [() async -> [ScanResult]] = [
            scanSystemCaches,
            scanUserCaches,
            scanSystemLogs,
            scanUserLogs,
            scanTempFiles,
            scanSpotlightCache,
            scanBrokenPreferences,
            scaniOSBackups,
            scaniOSSoftwareUpdates,
            scanXcodeCache
        ]
        
        for task in scanTasks {
            let taskResults = await task()
            results.append(contentsOf: taskResults)
        }
        
        return results
    }
    
    // MARK: - Cache Scanning
    
    private func scanSystemCaches() async -> [ScanResult] {
        let systemCachePaths = [
            "/Library/Caches",
            "/System/Library/Caches"
        ]
        
        return scanDirectories(systemCachePaths, category: "System Cache", requiresPrivileges: true)
    }
    
    private func scanUserCaches() async -> [ScanResult] {
        guard let homeDir = FileManager.default.homeDirectoryForCurrentUser.path as String? else {
            return []
        }
        
        let userCachePaths = [
            "\(homeDir)/Library/Caches"
        ]
        
        return scanDirectories(userCachePaths, category: "User Cache")
    }
    
    // MARK: - Log Scanning
    
    private func scanSystemLogs() async -> [ScanResult] {
        let logPaths = [
            "/var/log",
            "/Library/Logs"
        ]
        
        return scanDirectories(logPaths, category: "System Logs", requiresPrivileges: true)
    }
    
    private func scanUserLogs() async -> [ScanResult] {
        guard let homeDir = FileManager.default.homeDirectoryForCurrentUser.path as String? else {
            return []
        }
        
        let userLogPaths = [
            "\(homeDir)/Library/Logs"
        ]
        
        return scanDirectories(userLogPaths, category: "User Logs")
    }
    
    // MARK: - Temporary Files
    
    private func scanTempFiles() async -> [ScanResult] {
        let tempPaths = [
            "/private/tmp",
            "/private/var/tmp",
            NSTemporaryDirectory()
        ]
        
        return scanDirectories(tempPaths, category: "Temporary Files")
    }
    
    // MARK: - Spotlight Cache
    
    private func scanSpotlightCache() async -> [ScanResult] {
        let spotlightPaths = [
            "/.Spotlight-V100"
        ]
        
        return scanDirectories(spotlightPaths, category: "Spotlight Cache", requiresPrivileges: true)
    }
    
    // MARK: - Broken Preferences
    
    private func scanBrokenPreferences() async -> [ScanResult] {
        guard let homeDir = FileManager.default.homeDirectoryForCurrentUser.path as String? else {
            return []
        }
        
        let prefsPath = "\(homeDir)/Library/Preferences"
        var results: [ScanResult] = []
        
        guard let enumerator = FileManager.default.enumerator(atPath: prefsPath) else {
            return results
        }
        
        for case let file as String in enumerator {
            let fullPath = "\(prefsPath)/\(file)"
            
            // Check if .plist file is corrupted
            if file.hasSuffix(".plist") {
                if isCorruptedPlist(at: fullPath) {
                    if let size = fileSize(at: fullPath) {
                        results.append(ScanResult(
                            path: fullPath,
                            size: size,
                            type: .other,
                            category: "Broken Preferences"
                        ))
                    }
                }
            }
        }
        
        return results
    }
    
    // MARK: - iOS Backups
    
    private func scaniOSBackups() async -> [ScanResult] {
        guard let homeDir = FileManager.default.homeDirectoryForCurrentUser.path as String? else {
            return []
        }
        
        let backupsPath = "\(homeDir)/Library/Application Support/MobileSync/Backup"
        return scanDirectories([backupsPath], category: "iOS Backups")
    }
    
    private func scaniOSSoftwareUpdates() async -> [ScanResult] {
        guard let homeDir = FileManager.default.homeDirectoryForCurrentUser.path as String? else {
            return []
        }
        
        let updatesPath = "\(homeDir)/Library/iTunes/iPhone Software Updates"
        return scanDirectories([updatesPath], category: "iOS Software Updates")
    }
    
    // MARK: - Xcode Cache
    
    private func scanXcodeCache() async -> [ScanResult] {
        guard let homeDir = FileManager.default.homeDirectoryForCurrentUser.path as String? else {
            return []
        }
        
        let xcodePaths = [
            "\(homeDir)/Library/Developer/Xcode/DerivedData",
            "\(homeDir)/Library/Developer/Xcode/Archives",
            "\(homeDir)/Library/Developer/CoreSimulator/Caches"
        ]
        
        return scanDirectories(xcodePaths, category: "Xcode Cache")
    }
    
    // MARK: - Helper Methods
    
    private func scanDirectories(_ paths: [String], category: String, requiresPrivileges: Bool = false) -> [ScanResult] {
        var results: [ScanResult] = []
        let fileManager = FileManager.default
        
        for path in paths {
            guard fileManager.fileExists(atPath: path) else {
                continue
            }
            
            guard let enumerator = fileManager.enumerator(
                at: URL(fileURLWithPath: path),
                includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }
            
            for case let fileURL as URL in enumerator {
                do {
                    let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                    
                    if let isDirectory = resourceValues.isDirectory, !isDirectory {
                        if let fileSize = resourceValues.fileSize, fileSize > 0 {
                            results.append(ScanResult(
                                path: fileURL.path,
                                size: Int64(fileSize),
                                type: .cache,
                                category: category
                            ))
                        }
                    }
                } catch {
                    // Skip files we can't access
                    continue
                }
            }
        }
        
        return results
    }
    
    private func fileSize(at path: String) -> Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path) else {
            return nil
        }
        return attributes[.size] as? Int64
    }
    
    private func isCorruptedPlist(at path: String) -> Bool {
        // Try to load the plist
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return true
        }
        
        let plist = try? PropertyListSerialization.propertyList(from: data, format: nil)
        return plist == nil
    }
}

