//
//  ScanResult.swift
//  MacCleaner
//

import Foundation

struct ScanResult: Identifiable, Codable {
    let id: UUID
    let path: String
    let size: Int64
    let type: FileType
    let category: String
    var isSelected: Bool
    let createdDate: Date?
    let modifiedDate: Date?
    
    init(path: String, size: Int64, type: FileType, category: String, isSelected: Bool = true) {
        self.id = UUID()
        self.path = path
        self.size = size
        self.type = type
        self.category = category
        self.isSelected = isSelected
        
        // Get file dates
        let attributes = try? FileManager.default.attributesOfItem(atPath: path)
        self.createdDate = attributes?[.creationDate] as? Date
        self.modifiedDate = attributes?[.modificationDate] as? Date
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var filename: String {
        (path as NSString).lastPathComponent
    }
    
    var directory: String {
        (path as NSString).deletingLastPathComponent
    }
}

enum FileType: String, Codable {
    case cache
    case log
    case temporary
    case download
    case duplicate
    case large
    case application
    case document
    case image
    case video
    case archive
    case trash
    case other
}

struct SmartScanResults: Codable {
    var systemJunk: [ScanResult] = []
    var photoIssues: [ScanResult] = []
    var largeFiles: [ScanResult] = []
    var mailAttachments: [ScanResult] = []
    var trashItems: [ScanResult] = []
    var browserData: [ScanResult] = []
    
    var totalSize: Int64 {
        systemJunk.reduce(0) { $0 + $1.size } +
        photoIssues.reduce(0) { $0 + $1.size } +
        largeFiles.reduce(0) { $0 + $1.size } +
        mailAttachments.reduce(0) { $0 + $1.size } +
        trashItems.reduce(0) { $0 + $1.size } +
        browserData.reduce(0) { $0 + $1.size }
    }
    
    var totalItems: Int {
        systemJunk.count + photoIssues.count + largeFiles.count +
        mailAttachments.count + trashItems.count + browserData.count
    }
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file)
    }
}

