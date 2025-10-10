//
//  PhotoScanner.swift
//  MacCleaner
//
//  Scans for duplicate and similar photos
//

import Foundation
import CryptoKit
import CoreImage

class PhotoScanner {
    static let shared = PhotoScanner()
    
    private init() {}
    
    func scan() async -> [ScanResult] {
        var results: [ScanResult] = []
        
        // Scan Photos library
        results.append(contentsOf: await scanPhotosLibrary())
        
        // Scan common photo directories
        results.append(contentsOf: await scanCommonDirectories())
        
        return results
    }
    
    private func scanPhotosLibrary() async -> [ScanResult] {
        guard let homeDir = FileManager.default.homeDirectoryForCurrentUser.path as String? else {
            return []
        }
        
        let photosLibraryPath = "\(homeDir)/Pictures/Photos Library.photoslibrary"
        
        guard FileManager.default.fileExists(atPath: photosLibraryPath) else {
            return []
        }
        
        // Scan for duplicates
        return await findDuplicates(in: photosLibraryPath)
    }
    
    private func scanCommonDirectories() async -> [ScanResult] {
        guard let homeDir = FileManager.default.homeDirectoryForCurrentUser.path as String? else {
            return []
        }
        
        let photoDirs = [
            "\(homeDir)/Pictures",
            "\(homeDir)/Downloads",
            "\(homeDir)/Desktop"
        ]
        
        var results: [ScanResult] = []
        
        for dir in photoDirs {
            results.append(contentsOf: await findDuplicates(in: dir))
        }
        
        return results
    }
    
    private func findDuplicates(in directory: String) async -> [ScanResult] {
        var results: [ScanResult] = []
        var hashMap: [String: [String]] = [:]
        
        let fileManager = FileManager.default
        let imageExtensions = ["jpg", "jpeg", "png", "heic", "heif", "gif", "raw", "cr2", "nef"]
        
        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: directory),
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return results
        }
        
        for case let fileURL as URL in enumerator {
            let ext = fileURL.pathExtension.lowercased()
            
            guard imageExtensions.contains(ext) else {
                continue
            }
            
            // Calculate hash
            if let hash = calculateFileHash(at: fileURL.path) {
                hashMap[hash, default: []].append(fileURL.path)
            }
        }
        
        // Find duplicates
        for (_, paths) in hashMap where paths.count > 1 {
            // Keep the first file, mark others as duplicates
            for path in paths.dropFirst() {
                if let size = fileSize(at: path) {
                    results.append(ScanResult(
                        path: path,
                        size: size,
                        type: .duplicate,
                        category: "Duplicate Photos"
                    ))
                }
            }
        }
        
        // Find similar photos using perceptual hashing
        results.append(contentsOf: await findSimilarPhotos(in: directory))
        
        // Find RAW+JPEG pairs
        results.append(contentsOf: findRAWJPEGPairs(in: directory))
        
        return results
    }
    
    private func findSimilarPhotos(in directory: String) async -> [ScanResult] {
        var results: [ScanResult] = []
        
        // This would use perceptual hashing (pHash) to find visually similar images
        // For now, return empty array - full implementation would use CoreImage
        
        return results
    }
    
    private func findRAWJPEGPairs(in directory: String) -> [ScanResult] {
        var results: [ScanResult] = []
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(atPath: directory) else {
            return results
        }
        
        var jpegFiles: Set<String> = []
        var rawFiles: Set<String> = []
        
        for case let file as String in enumerator {
            let ext = (file as NSString).pathExtension.lowercased()
            let basename = (file as NSString).deletingPathExtension
            
            if ["jpg", "jpeg"].contains(ext) {
                jpegFiles.insert(basename)
            } else if ["raw", "cr2", "nef", "arw", "dng"].contains(ext) {
                rawFiles.insert(basename)
            }
        }
        
        // Find pairs (suggest removing JPEG if RAW exists)
        let pairs = jpegFiles.intersection(rawFiles)
        
        for basename in pairs {
            // Find the JPEG file
            for ext in ["jpg", "jpeg"] {
                let jpegPath = "\(directory)/\(basename).\(ext)"
                if fileManager.fileExists(atPath: jpegPath) {
                    if let size = fileSize(at: jpegPath) {
                        results.append(ScanResult(
                            path: jpegPath,
                            size: size,
                            type: .duplicate,
                            category: "RAW+JPEG Pairs"
                        ))
                    }
                    break
                }
            }
        }
        
        return results
    }
    
    private func calculateFileHash(at path: String) -> String? {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            return nil
        }
        
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func fileSize(at path: String) -> Int64? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path) else {
            return nil
        }
        return attributes[.size] as? Int64
    }
}

