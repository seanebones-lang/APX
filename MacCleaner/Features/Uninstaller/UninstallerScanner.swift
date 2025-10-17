//
//  MacCleaner
//
//

import Foundation
import AppKit

class UninstallerScanner {
    static let shared = UninstallerScanner()
    
    private init() {}
    
    func scanApplications() async -> [Application] {
        var applications: [Application] = []
        
        let searchPaths = [
            "/Applications",
            "/System/Applications",
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path
        ]
        
        for path in searchPaths {
            let foundApps = await scanDirectory(path)
            applications.append(contentsOf: foundApps)
        }
        
        return applications.sorted { $0.size > $1.size }
    }
    
    private func scanDirectory(_ path: String) async -> [Application] {
        var results: [Application] = []
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: path) else {
            return results
        }
        
        guard let contents = try? fileManager.contentsOfDirectory(atPath: path) else {
            return results
        }
        
        for item in contents {
            let fullPath = "\(path)/\(item)"
            
            if item.hasSuffix(".app") {
                let appURL = URL(fileURLWithPath: fullPath)
                
                if let bundle = Bundle(url: appURL),
                   let appName = bundle.infoDictionary?["CFBundleName"] as? String ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String {
                    
                    let size = await calculateDirectorySize(appURL)
                    let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
                    let bundleID = bundle.bundleIdentifier ?? "Unknown"
                    let icon = getAppIcon(for: appURL)
                    
                    let associatedFiles = await findAssociatedFiles(for: bundleID)
                    
                    let app = Application(
                        name: appName,
                        path: fullPath,
                        size: size,
                        version: version,
                        bundleIdentifier: bundleID,
                        icon: icon,
                        associatedFiles: associatedFiles
                    )
                    
                    results.append(app)
                }
            }
        }
        
        return results
    }
    
    private func calculateDirectorySize(_ url: URL) async -> Int64 {
        var totalSize: Int64 = 0
        
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                if let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                }
            } catch {
                continue
            }
        }
        
        return totalSize
    }
    
    private func getAppIcon(for appURL: URL) -> NSImage? {
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }
    
    private func findAssociatedFiles(for bundleID: String) async -> [String] {
        var files: [String] = []
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        
        let searchPaths = [
            "\(homeDir)/Library/Application Support/\(bundleID)",
            "\(homeDir)/Library/Caches/\(bundleID)",
            "\(homeDir)/Library/Preferences/\(bundleID).plist",
            "\(homeDir)/Library/Logs/\(bundleID)",
            "\(homeDir)/Library/Saved Application State/\(bundleID).savedState"
        ]
        
        for path in searchPaths {
            if FileManager.default.fileExists(atPath: path) {
                files.append(path)
            }
        }
        
        return files
    }
    
    func uninstallApplication(_ app: Application, removeAssociatedFiles: Bool) async throws {
        let fileManager = FileManager.default
        
        try fileManager.trashItem(at: URL(fileURLWithPath: app.path), resultingItemURL: nil)
        
        if removeAssociatedFiles {
            for file in app.associatedFiles {
                try? fileManager.trashItem(at: URL(fileURLWithPath: file), resultingItemURL: nil)
            }
        }
    }
}

struct Application: Identifiable, Codable {
    let id = UUID()
    let name: String
    let path: String
    let size: Int64
    let version: String
    let bundleIdentifier: String
    var icon: NSImage?
    let associatedFiles: [String]
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var associatedFilesSize: Int64 {
        var total: Int64 = 0
        for file in associatedFiles {
            if let attributes = try? FileManager.default.attributesOfItem(atPath: file),
               let fileSize = attributes[.size] as? Int64 {
                total += fileSize
            }
        }
        return total
    }
    
    var totalSize: Int64 {
        size + associatedFilesSize
    }
    
    enum CodingKeys: String, CodingKey {
        case name, path, size, version, bundleIdentifier, associatedFiles
    }
    
    init(name: String, path: String, size: Int64, version: String, bundleIdentifier: String, icon: NSImage?, associatedFiles: [String]) {
        self.name = name
        self.path = path
        self.size = size
        self.version = version
        self.bundleIdentifier = bundleIdentifier
        self.icon = icon
        self.associatedFiles = associatedFiles
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        path = try container.decode(String.self, forKey: .path)
        size = try container.decode(Int64.self, forKey: .size)
        version = try container.decode(String.self, forKey: .version)
        bundleIdentifier = try container.decode(String.self, forKey: .bundleIdentifier)
        associatedFiles = try container.decode([String].self, forKey: .associatedFiles)
        icon = nil
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(path, forKey: .path)
        try container.encode(size, forKey: .size)
        try container.encode(version, forKey: .version)
        try container.encode(bundleIdentifier, forKey: .bundleIdentifier)
        try container.encode(associatedFiles, forKey: .associatedFiles)
    }
}
