//
//  MenuBarApp.swift
//  MenuBarAgent
//
//  Menu bar monitoring application
//

import SwiftUI
import AppKit

@main
struct MenuBarApp: App {
    @NSApplicationDelegateAdaptor(MenuBarDelegate.self) var delegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class MenuBarDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var timer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "chart.bar.fill", accessibilityDescription: "MacCleaner")
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
        
        // Start monitoring
        startMonitoring()
        
        // Update every 5 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.updateStatus()
        }
    }
    
    @objc func statusBarButtonClicked() {
        let menu = NSMenu()
        
        // Add menu items
        menu.addItem(NSMenuItem(title: "CPU: \(getCPUUsage())%", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Memory: \(getMemoryUsage())%", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Open MacCleaner", action: #selector(openMainApp), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q"))
        
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    
    @objc func openMainApp() {
        NSWorkspace.shared.launchApplication("MacCleaner")
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
    
    private func startMonitoring() {
        updateStatus()
    }
    
    private func updateStatus() {
        if let button = statusItem?.button {
            let cpuUsage = getCPUUsage()
            button.title = " \(Int(cpuUsage))%"
        }
    }
    
    private func getCPUUsage() -> Double {
        var totalUsageOfCPU: Double = 0.0
        var threadsList: thread_act_array_t?
        var threadsCount = mach_msg_type_number_t(0)
        let threadsResult = task_threads(mach_task_self_, &threadsList, &threadsCount)
        
        if threadsResult == KERN_SUCCESS, let threadsList = threadsList {
            for index in 0..<threadsCount {
                var threadInfo = thread_basic_info()
                var threadInfoCount = mach_msg_type_number_t(THREAD_BASIC_INFO_COUNT)
                let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        thread_info(threadsList[Int(index)], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                    }
                }
                
                guard infoResult == KERN_SUCCESS else {
                    continue
                }
                
                let threadBasicInfo = threadInfo
                if threadBasicInfo.flags & TH_FLAGS_IDLE == 0 {
                    totalUsageOfCPU = totalUsageOfCPU + (Double(threadBasicInfo.cpu_usage) / Double(TH_USAGE_SCALE)) * 100.0
                }
            }
        }
        
        vm_deallocate(mach_task_self_, vm_address_t(UInt(bitPattern: threadsList)), vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride))
        
        return totalUsageOfCPU
    }
    
    private func getMemoryUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMemory = Double(info.resident_size) / 1024.0 / 1024.0 / 1024.0 // GB
            
            // Get total memory
            var size = UInt64(0)
            var sizeLen = MemoryLayout.size(ofValue: size)
            sysctlbyname("hw.memsize", &size, &sizeLen, nil, 0)
            let totalMemory = Double(size) / 1024.0 / 1024.0 / 1024.0 // GB
            
            return (usedMemory / totalMemory) * 100.0
        }
        
        return 0.0
    }
}

