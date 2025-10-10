//
//  BrowserScanner.swift
//  MacCleaner
//

import Foundation

class BrowserScanner {
    static let shared = BrowserScanner()
    
    private init() {}
    
    func scan() async -> [ScanResult] {
        var results: [ScanResult] = []
        
        results.append(contentsOf: await scanSafari())
        results.append(contentsOf: await scanChrome())
        results.append(contentsOf: await scanFirefox())
        results.append(contentsOf: await scanEdge())
        results.append(contentsOf: await scanBrave())
        results.append(contentsOf: await scanArc())
        
        return results
    }
    
    private func scanSafari() async -> [ScanResult] {
        guard let homeDir = FileManager.default.homeDirectoryForCurrentUser.path as String? else {
            return []
        }
        
        let safariPath = "\(homeDir)/Library/Safari"
        let cachePaths = [
            "\(homeDir)/Library/Caches/com.apple.Safari",
            "\(safariPath)/LocalStorage",
            "\(safariPath)/Databases"
        ]
        
        return scanBrowserPaths(cachePaths, browserName: "Safari")
    }
    
    private func scanChrome() async -> [ScanResult] {
        guard let homeDir = FileManager.default.homeDirectoryForCurrentUser.path as String? else {
            return []
        }
        
        let chromePath = "\(homeDir)/Library/Application Support/Google/Chrome"
        let cachePaths = [
            "\(homeDir)/Library/Caches/Google/Chrome",
            "\(chromePath)/Default/Cache",
            "\(chromePath)/Default/Code Cache"
        ]
        
        return scanBrowserPaths(cachePaths, browserName: "Chrome")
    }
    
    private func scanFirefox() async -> [ScanResult] {
        guard let homeDir = FileManager.default.homeDirectoryForCurrentUser.path as String? else {
            return []
        }
        
        let firefoxPath = "\(homeDir)/Library/Application Support/Firefox"
        let cachePath = "\(homeDir)/Library/Caches/Firefox"
        
        return scanBrowserPaths([firefoxPath, cachePath], browserName: "Firefox")
    }
    
    private func scanEdge() async -> [ScanResult] {
        guard let homeDir = FileManager.default.homeDirectoryForCurrentUser.path as String? else {
            return []
        }
        
        let edgePath = "\(homeDir)/Library/Application Support/Microsoft Edge"
        let cachePath = "\(homeDir)/Library/Caches/Microsoft Edge"
        
        return scanBrowserPaths([edgePath, cachePath], browserName: "Edge")
    }
    
    private func scanBrave() async -> [ScanResult] {
        guard let homeDir = FileManager.default.homeDirectoryForCurrentUser.path as String? else {
            return []
        }
        
        let bravePath = "\(homeDir)/Library/Application Support/BraveSoftware/Brave-Browser"
        let cachePath = "\(homeDir)/Library/Caches/BraveSoftware/Brave-Browser"
        
        return scanBrowserPaths([bravePath, cachePath], browserName: "Brave")
    }
    
    private func scanArc() async -> [ScanResult] {
        guard let homeDir = FileManager.default.homeDirectoryForCurrentUser.path as String? else {
            return []
        }
        
        let arcPath = "\(homeDir)/Library/Application Support/Arc"
        let cachePath = "\(homeDir)/Library/Caches/Arc"
        
        return scanBrowserPaths([arcPath, cachePath], browserName: "Arc")
    }
    
    private func scanBrowserPaths(_ paths: [String], browserName: String) -> [ScanResult] {
        var results: [ScanResult] = []
        
        for path in paths {
            guard FileManager.default.fileExists(atPath: path) else {
                continue
            }
            
            guard let enumerator = FileManager.default.enumerator(
                at: URL(fileURLWithPath: path),
                includingPropertiesForKeys: [.fileSizeKey],
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }
            
            for case let fileURL as URL in enumerator {
                if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    results.append(ScanResult(
                        path: fileURL.path,
                        size: Int64(size),
                        type: .cache,
                        category: "\(browserName) Cache"
                    ))
                }
            }
        }
        
        return results
    }
}

