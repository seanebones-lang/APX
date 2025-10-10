//
//  TrashScanner.swift
//  MacCleaner
//

import Foundation

class TrashScanner {
    static let shared = TrashScanner()
    
    private init() {}
    
    func scan() async -> [ScanResult] {
        var results: [ScanResult] = []
        
        // System Trash
        results.append(contentsOf: scanSystemTrash())
        
        // Photos Trash
        results.append(contentsOf: scanPhotosTrash())
        
        // Mail Trash
        results.append(contentsOf: scanMailTrash())
        
        return results
    }
    
    private func scanSystemTrash() -> [ScanResult] {
        guard let homeDir = FileManager.default.homeDirectoryForCurrentUser.path as String? else {
            return []
        }
        
        let trashPath = "\(homeDir)/.Trash"
        return scanDirectory(trashPath, category: "System Trash")
    }
    
    private func scanPhotosTrash() -> [ScanResult] {
        guard let homeDir = FileManager.default.homeDirectoryForCurrentUser.path as String? else {
            return []
        }
        
        let photosLibraryPath = "\(homeDir)/Pictures/Photos Library.photoslibrary"
        let trashPath = "\(photosLibraryPath)/Trash"
        
        guard FileManager.default.fileExists(atPath: trashPath) else {
            return []
        }
        
        return scanDirectory(trashPath, category: "Photos Trash")
    }
    
    private func scanMailTrash() -> [ScanResult] {
        guard let homeDir = FileManager.default.homeDirectoryForCurrentUser.path as String? else {
            return []
        }
        
        let mailPath = "\(homeDir)/Library/Mail"
        var results: [ScanResult] = []
        
        guard let enumerator = FileManager.default.enumerator(atPath: mailPath) else {
            return results
        }
        
        for case let file as String in enumerator {
            if file.contains("/Deleted Messages.mbox/") {
                let fullPath = "\(mailPath)/\(file)"
                if let size = fileSize(at: fullPath) {
                    results.append(ScanResult(
                        path: fullPath,
                        size: size,
                        type: .trash,
                        category: "Mail Trash"
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
            options: []
        ) else {
            return results
        }
        
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                results.append(ScanResult(
                    path: fileURL.path,
                    size: Int64(size),
                    type: .trash,
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

