//
//  MailScanner.swift
//  MacCleaner
//

import Foundation

class MailScanner {
    static let shared = MailScanner()
    
    private init() {}
    
    func scan() async -> [ScanResult] {
        guard let homeDir = FileManager.default.homeDirectoryForCurrentUser.path as String? else {
            return []
        }
        
        let mailPath = "\(homeDir)/Library/Mail"
        guard FileManager.default.fileExists(atPath: mailPath) else {
            return []
        }
        
        var results: [ScanResult] = []
        
        // Scan Downloads folder in Mail
        let downloadsPath = "\(mailPath)/Downloads"
        results.append(contentsOf: scanDirectory(downloadsPath, category: "Mail Downloads"))
        
        // Scan attachments
        results.append(contentsOf: await scanMailAttachments(in: mailPath))
        
        return results
    }
    
    private func scanMailAttachments(in mailPath: String) async -> [ScanResult] {
        var results: [ScanResult] = []
        
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(atPath: mailPath) else {
            return results
        }
        
        for case let file as String in enumerator {
            if file.contains("/Attachments/") {
                let fullPath = "\(mailPath)/\(file)"
                if let size = fileSize(at: fullPath), size > 1024 * 1024 { // > 1MB
                    results.append(ScanResult(
                        path: fullPath,
                        size: size,
                        type: .other,
                        category: "Mail Attachments"
                    ))
                }
            }
        }
        
        return results
    }
    
    private func scanDirectory(_ path: String, category: String) -> [ScanResult] {
        var results: [ScanResult] = []
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: path) else {
            return results
        }
        
        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return results
        }
        
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                results.append(ScanResult(
                    path: fileURL.path,
                    size: Int64(size),
                    type: .download,
                    category: category
                ))
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
}

