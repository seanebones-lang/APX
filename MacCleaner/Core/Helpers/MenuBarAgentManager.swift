//
//  MenuBarAgentManager.swift
//  MacCleaner
//

import Foundation
import ServiceManagement

class MenuBarAgentManager {
    static let shared = MenuBarAgentManager()
    
    private let agentID = "com.maccleaner.menubar"
    private var isAgentRunning = false
    
    private init() {}
    
    func launchAgent() {
        guard !isAgentRunning else { return }
        
        // Launch the menu bar agent
        let agentURL = Bundle.main.bundleURL.appendingPathComponent("Contents/Library/LoginItems/MenuBarAgent.app")
        
        if FileManager.default.fileExists(atPath: agentURL.path) {
            NSWorkspace.shared.openApplication(at: agentURL, configuration: NSWorkspace.OpenConfiguration()) { app, error in
                if let error = error {
                    print("Failed to launch menu bar agent: \(error)")
                } else {
                    self.isAgentRunning = true
                }
            }
        }
    }
    
    func terminateAgent() {
        guard isAgentRunning else { return }
        
        // Terminate the menu bar agent
        let runningApps = NSWorkspace.shared.runningApplications
        if let agent = runningApps.first(where: { $0.bundleIdentifier == agentID }) {
            agent.terminate()
            isAgentRunning = false
        }
    }
}

