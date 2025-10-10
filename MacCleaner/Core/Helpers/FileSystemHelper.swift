//
//  FileSystemHelper.swift
//  MacCleaner
//

import Foundation

class FileSystemHelper {
    static let shared = FileSystemHelper()
    
    private init() {}
    
    // MARK: - File Size Calculations
    
    func calculateDirectorySize(at path: String) -> Int64 {
        let fileManager = FileManager.default
        var totalSize: Int64 = 0
        
        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(size)
            }
        }
        
        return totalSize
    }
    
    // MARK: - File Type Detection
    
    func getFileType(for url: URL) -> FileType {
        let ext = url.pathExtension.lowercased()
        
        let videoExts = ["mp4", "mov", "avi", "mkv", "m4v", "wmv", "flv", "webm"]
        let imageExts = ["jpg", "jpeg", "png", "heic", "heif", "gif", "raw", "cr2", "nef", "bmp", "tiff"]
        let archiveExts = ["zip", "rar", "7z", "tar", "gz", "bz2", "xz", "dmg", "pkg", "iso"]
        let documentExts = ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "rtf", "pages", "numbers", "keynote"]
        let audioExts = ["mp3", "m4a", "flac", "wav", "aiff", "aac", "ogg"]
        
        if videoExts.contains(ext) {
            return .video
        } else if imageExts.contains(ext) {
            return .image
        } else if archiveExts.contains(ext) {
            return .archive
        } else if documentExts.contains(ext) {
            return .document
        } else if audioExts.contains(ext) {
            return .other
        } else {
            return .other
        }
    }
    
    // MARK: - Disk Space
    
    func getAvailableDiskSpace() -> Int64? {
        let fileURL = URL(fileURLWithPath: "/")
        
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            return values.volumeAvailableCapacity.map { Int64($0) }
        } catch {
            return nil
        }
    }
    
    func getTotalDiskSpace() -> Int64? {
        let fileURL = URL(fileURLWithPath: "/")
        
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeTotalCapacityKey])
            return values.volumeTotalCapacity.map { Int64($0) }
        } catch {
            return nil
        }
    }
    
    // MARK: - File Operations
    
    func isWritable(path: String) -> Bool {
        return FileManager.default.isWritableFile(atPath: path)
    }
    
    func isDeletable(path: String) -> Bool {
        return FileManager.default.isDeletableFile(atPath: path)
    }
    
    func fileExists(at path: String) -> Bool {
        return FileManager.default.fileExists(atPath: path)
    }
    
    // MARK: - Common Paths
    
    var homeDirectory: String? {
        return FileManager.default.homeDirectoryForCurrentUser.path
    }
    
    var cachesDirectory: String? {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.path
    }
    
    var applicationSupportDirectory: String? {
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.path
    }
    
    var downloadsDirectory: String? {
        return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.path
    }
}

