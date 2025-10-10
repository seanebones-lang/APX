//
//  LargeFileScanner.swift
//  MacCleaner
//

import Foundation

class LargeFileScanner {
    static let shared = LargeFileScanner()
    
    private let minimumFileSize: Int64 = 100 * 1024 * 1024 // 100 MB
    
    private init() {}
    
    func scan(minimumSize: Int64? = nil, directories: [String]? = nil) async -> [ScanResult] {
        let minSize = minimumSize ?? minimumFileSize
        let searchDirs = directories ?? getDefaultSearchDirectories()
        
        var results: [ScanResult] = []
        
        for directory in searchDirs {
            results.append(contentsOf: await scanDirectory(directory, minimumSize: minSize))
        }
        
        return results.sorted { $0.size > $1.size }
    }
    
    private func getDefaultSearchDirectories() -> [String] {
        guard let homeDir = FileManager.default.homeDirectoryForCurrentUser.path as String? else {
            return []
        }
        
        return [
            "\(homeDir)/Downloads",
            "\(homeDir)/Documents",
            "\(homeDir)/Desktop",
            "\(homeDir)/Movies",
            "\(homeDir)/Pictures"
        ]
    }
    
    private func scanDirectory(_ path: String, minimumSize: Int64) async -> [ScanResult] {
        var results: [ScanResult] = []
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: path) else {
            return results
        }
        
        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return results
        }
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey])
                
                if let isDirectory = resourceValues.isDirectory, !isDirectory {
                    if let fileSize = resourceValues.fileSize, Int64(fileSize) >= minimumSize {
                        let fileType = determineFileType(fileURL.pathExtension)
                        
                        results.append(ScanResult(
                            path: fileURL.path,
                            size: Int64(fileSize),
                            type: fileType,
                            category: "Large Files"
                        ))
                    }
                }
            } catch {
                continue
            }
        }
        
        return results
    }
    
    private func determineFileType(_ ext: String) -> FileType {
        let extension = ext.lowercased()
        
        let videoExts = ["mp4", "mov", "avi", "mkv", "m4v", "wmv", "flv"]
        let imageExts = ["jpg", "jpeg", "png", "heic", "gif", "raw", "cr2", "nef"]
        let archiveExts = ["zip", "rar", "7z", "tar", "gz", "dmg", "pkg"]
        let documentExts = ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx"]
        
        if videoExts.contains(extension) {
            return .video
        } else if imageExts.contains(extension) {
            return .image
        } else if archiveExts.contains(extension) {
            return .archive
        } else if documentExts.contains(extension) {
            return .document
        } else {
            return .other
        }
    }
}

