//
//  MacCleaner
//

import Foundation
import ServiceManagement

class LoginItemsScanner {
    static let shared = LoginItemsScanner()
    
    private init() {}
    
    func scan() async -> [LoginItem] {
        var items: [LoginItem] = []
        
        items.append(contentsOf: await scanLaunchAgents())
        items.append(contentsOf: await scanLaunchDaemons())
        items.append(contentsOf: await scanLoginItems())
        
        return items.sorted { $0.name < $1.name }
    }
    
    private func scanLaunchAgents() async -> [LoginItem] {
        var items: [LoginItem] = []
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        
        let paths = [
            "\(homeDir)/Library/LaunchAgents",
            "/Library/LaunchAgents",
            "/System/Library/LaunchAgents"
        ]
        
        for path in paths {
            guard let files = try? FileManager.default.contentsOfDirectory(atPath: path) else { continue }
            
            for file in files where file.hasSuffix(".plist") {
                let fullPath = "\(path)/\(file)"
                if let plist = NSDictionary(contentsOfFile: fullPath) as? [String: Any],
                   let label = plist["Label"] as? String {
                    items.append(LoginItem(
                        name: label,
                        path: fullPath,
                        type: .launchAgent,
                        isEnabled: true
                    ))
                }
            }
        }
        
        return items
    }
    
    private func scanLaunchDaemons() async -> [LoginItem] {
        var items: [LoginItem] = []
        
        let paths = [
            "/Library/LaunchDaemons",
            "/System/Library/LaunchDaemons"
        ]
        
        for path in paths {
            guard let files = try? FileManager.default.contentsOfDirectory(atPath: path) else { continue }
            
            for file in files where file.hasSuffix(".plist") {
                let fullPath = "\(path)/\(file)"
                if let plist = NSDictionary(contentsOfFile: fullPath) as? [String: Any],
                   let label = plist["Label"] as? String {
                    items.append(LoginItem(
                        name: label,
                        path: fullPath,
                        type: .launchDaemon,
                        isEnabled: true
                    ))
                }
            }
        }
        
        return items
    }
    
    private func scanLoginItems() async -> [LoginItem] {
        var items: [LoginItem] = []
        
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        let prefsPath = "\(homeDir)/Library/Preferences/com.apple.loginitems.plist"
        
        if let plist = NSDictionary(contentsOfFile: prefsPath) as? [String: Any] {
            if let sessionItems = plist["SessionItems"] as? [String: Any],
               let customItems = sessionItems["CustomListItems"] as? [[String: Any]] {
                for item in customItems {
                    if let name = item["Name"] as? String {
                        items.append(LoginItem(
                            name: name,
                            path: prefsPath,
                            type: .loginItem,
                            isEnabled: true
                        ))
                    }
                }
            }
        }
        
        return items
    }
    
    func remove(_ item: LoginItem) async throws {
        try FileManager.default.removeItem(atPath: item.path)
    }
}

struct LoginItem: Identifiable {
    let id = UUID()
    let name: String
    let path: String
    let type: LoginItemType
    let isEnabled: Bool
}

enum LoginItemType: String {
    case launchAgent = "Launch Agent"
    case launchDaemon = "Launch Daemon"
    case loginItem = "Login Item"
}
