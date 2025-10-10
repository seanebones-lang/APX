//
//  ErrorLogScanner.swift
//  MacCleaner
//
//  Scans for error logs, crash reports, and diagnostic files
//

import Foundation

class ErrorLogScanner {
    static let shared = ErrorLogScanner()
    
    private init() {}
    
    func scan() async -> [ScanResult] {
        var results: [ScanResult] = []
        
        // Scan all error log locations
        results.append(contentsOf: await scanCrashReports())
        results.append(contentsOf: await scanDiagnosticReports())
        results.append(contentsOf: await scanHangReports())
        results.append(contentsOf: await scanSystemLogs())
        results.append(contentsOf: await scanInstallLogs())
        results.append(contentsOf: await scanPanicLogs())
        
        return results
    }
    
    // MARK: - Crash Reports
    
    private func scanCrashReports() async -> [ScanResult] {
        guard let homeDir = FileManager.default.homeDirectoryForCurrentUser.path as String? else {
            return []
        }
        
        let crashPaths = [
            "\(homeDir)/Library/Logs/DiagnosticReports",
            "/Library/Logs/DiagnosticReports",
            "\(homeDir)/Library/Logs/CrashReporter"
        ]
        
        return scanLogDirectories(crashPaths, category: "Crash Reports", fileExtensions: [".crash", ".ips", ".panic"])
    }
    
    // MARK: - Diagnostic Reports
    
    private func scanDiagnosticReports() async -> [ScanResult] {
        guard let homeDir = FileManager.default.homeDirectoryForCurrentUser.path as String? else {
            return []
        }
        
        let diagnosticPaths = [
            "\(homeDir)/Library/Logs/DiagnosticReports",
            "/var/log/DiagnosticReports"
        ]
        
        return scanLogDirectories(diagnosticPaths, category: "Diagnostic Reports", fileExtensions: [".diag", ".diagnostics"])
    }
    
    // MARK: - Hang Reports
    
    private func scanHangReports() async -> [ScanResult] {
        guard let homeDir = FileManager.default.homeDirectoryForCurrentUser.path as String? else {
            return []
        }
        
        let hangPath = "\(homeDir)/Library/Logs/DiagnosticReports"
        
        var results: [ScanResult] = []
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: hangPath) else {
            return results
        }
        
        guard let files = try? fileManager.contentsOfDirectory(atPath: hangPath) else {
            return results
        }
        
        for file in files {
            // Look for hang reports (contain "hang" in filename)
            if file.lowercased().contains("hang") || file.hasSuffix(".hang") {
                let fullPath = "\(hangPath)/\(file)"
                if let size = fileSize(at: fullPath) {
                    results.append(ScanResult(
                        path: fullPath,
                        size: size,
                        type: .log,
                        category: "Hang Reports"
                    ))
                }
            }
        }
        
        return results
    }
    
    // MARK: - System Logs
    
    private func scanSystemLogs() async -> [ScanResult] {
        let systemLogPaths = [
            "/var/log/system.log",
            "/var/log/install.log",
            "/var/log/asl"
        ]
        
        return scanLogDirectories(systemLogPaths, category: "System Error Logs", fileExtensions: [".log", ".asl"])
    }
    
    // MARK: - Install Logs
    
    private func scanInstallLogs() async -> [ScanResult] {
        guard let homeDir = FileManager.default.homeDirectoryForCurrentUser.path as String? else {
            return []
        }
        
        let installLogPaths = [
            "/var/log/install.log",
            "\(homeDir)/Library/Logs/Install.log"
        ]
        
        var results: [ScanResult] = []
        
        for path in installLogPaths {
            if FileManager.default.fileExists(atPath: path) {
                if let size = fileSize(at: path), size > 10 * 1024 * 1024 { // > 10MB
                    results.append(ScanResult(
                        path: path,
                        size: size,
                        type: .log,
                        category: "Install Logs"
                    ))
                }
            }
        }
        
        return results
    }
    
    // MARK: - Panic Logs
    
    private func scanPanicLogs() async -> [ScanResult] {
        let panicPath = "/Library/Logs/DiagnosticReports"
        
        var results: [ScanResult] = []
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: panicPath) else {
            return results
        }
        
        guard let files = try? fileManager.contentsOfDirectory(atPath: panicPath) else {
            return results
        }
        
        for file in files {
            // Look for panic logs
            if file.lowercased().contains("panic") || file.hasSuffix(".panic") {
                let fullPath = "\(panicPath)/\(file)"
                if let size = fileSize(at: fullPath) {
                    results.append(ScanResult(
                        path: fullPath,
                        size: size,
                        type: .log,
                        category: "Kernel Panic Logs"
                    ))
                }
            }
        }
        
        return results
    }
    
    // MARK: - Helper Methods
    
    private func scanLogDirectories(_ paths: [String], category: String, fileExtensions: [String] = [".log", ".crash", ".ips"]) -> [ScanResult] {
        var results: [ScanResult] = []
        let fileManager = FileManager.default
        
        for path in paths {
            guard fileManager.fileExists(atPath: path) else {
                continue
            }
            
            var isDirectory: ObjCBool = false
            fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
            
            if isDirectory.boolValue {
                // Scan directory
                guard let enumerator = fileManager.enumerator(
                    at: URL(fileURLWithPath: path),
                    includingPropertiesForKeys: [.fileSizeKey, .creationDateKey],
                    options: [.skipsHiddenFiles]
                ) else {
                    continue
                }
                
                for case let fileURL as URL in enumerator {
                    let ext = fileURL.pathExtension.lowercased()
                    
                    // Check if it's an error log file
                    if fileExtensions.contains(".\(ext)") || isErrorLog(at: fileURL.path) {
                        if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                            results.append(ScanResult(
                                path: fileURL.path,
                                size: Int64(size),
                                type: .log,
                                category: category
                            ))
                        }
                    }
                }
            } else {
                // Single file
                if let size = fileSize(at: path) {
                    results.append(ScanResult(
                        path: path,
                        size: size,
                        type: .log,
                        category: category
                    ))
                }
            }
        }
        
        return results
    }
    
    private func isErrorLog(at path: String) -> Bool {
        let filename = (path as NSString).lastPathComponent.lowercased()
        
        // Check for error indicators in filename
        let errorKeywords = ["error", "crash", "hang", "panic", "diagnostic", "spin", "watchdog"]
        
        for keyword in errorKeywords {
            if filename.contains(keyword) {
                return true
            }
        }
        
        // Check file size - if very old and large, likely accumulated errors
        if let attributes = try? FileManager.default.attributesOfItem(atPath: path),
           let size = attributes[.size] as? Int64,
           let modDate = attributes[.modificationDate] as? Date {
            
            let daysSinceModified = Date().timeIntervalSince(modDate) / (24 * 60 * 60)
            
            // If file is old (>30 days) and large (>50MB), consider it for cleanup
            if daysSinceModified > 30 && size > 50 * 1024 * 1024 {
                return true
            }
        }
        
        return false
    }
    
    private func fileSize(at path: String) -> Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path) else {
            return nil
        }
        return attributes[.size] as? Int64
    }
    
    // MARK: - Advanced: Parse Error Logs for Statistics
    
    func analyzeErrorLogs(at paths: [String]) async -> ErrorLogAnalysis {
        var analysis = ErrorLogAnalysis()
        
        for path in paths {
            guard let content = try? String(contentsOfFile: path, encoding: .utf8) else {
                continue
            }
            
            // Count different types of errors
            analysis.totalCrashes += content.components(separatedBy: "Exception Type:").count - 1
            analysis.totalHangs += content.components(separatedBy: "hang").count - 1
            analysis.totalPanics += content.components(separatedBy: "panic").count - 1
            
            // Find most common error applications
            let lines = content.components(separatedBy: .newlines)
            for line in lines {
                if line.contains("Process:") {
                    let components = line.components(separatedBy: "Process:")
                    if components.count > 1 {
                        let appName = components[1].trimmingCharacters(in: .whitespaces).components(separatedBy: " ").first ?? ""
                        analysis.affectedApps[appName, default: 0] += 1
                    }
                }
            }
        }
        
        return analysis
    }
}

struct ErrorLogAnalysis {
    var totalCrashes: Int = 0
    var totalHangs: Int = 0
    var totalPanics: Int = 0
    var affectedApps: [String: Int] = [:]
    
    var topCrashingApps: [(String, Int)] {
        affectedApps.sorted { $0.value > $1.value }.prefix(5).map { ($0.key, $0.value) }
    }
}

