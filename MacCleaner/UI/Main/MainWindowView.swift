//
//  MainWindowView.swift
//  MacCleaner
//

import SwiftUI

struct MainWindowView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var licenseManager: LicenseManager
    
    var body: some View {
        NavigationSplitView {
            SidebarView()
                .frame(minWidth: 240)
        } detail: {
            DetailView()
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                LicenseStatusView()
            }
        }
        .sheet(isPresented: $appState.showLicenseWindow) {
            LicenseActivationView()
        }
        .sheet(isPresented: $appState.showPreferences) {
            PreferencesView()
        }
    }
}

struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var soundManager: SoundManager
    
    var body: some View {
        ZStack {
            // Background with blur effect
            VisualEffectView(material: .sidebar, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 12) {
                    // App Logo
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 48))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.purple, Color.blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("MacCleaner")
                            .font(.title2.bold())
                        
                        Text("Pro")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Module List
                    ForEach(CleaningModule.allCases) { module in
                        SidebarItemView(module: module)
                            .onTapGesture {
                                soundManager.play(.buttonClick)
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    appState.navigate(to: module)
                                }
                            }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
}

struct SidebarItemView: View {
    let module: CleaningModule
    @EnvironmentObject var appState: AppState
    
    var isSelected: Bool {
        appState.selectedModule == module
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(module.color.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: module.icon)
                    .font(.system(size: 16))
                    .foregroundColor(module.color)
            }
            
            // Title
            Text(module.rawValue)
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .primary : .secondary)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct DetailView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        Group {
            switch appState.selectedModule {
            case .smartScan:
                SmartScanView()
            case .systemJunk:
                SystemJunkView()
            case .photoCleaner:
                PhotoCleanerView()
            case .largeFiles:
                LargeFilesView()
            case .uninstaller:
                UninstallerView()
            case .mailAttachments:
                MailAttachmentsView()
            case .trashBins:
                TrashBinsView()
            case .browserData:
                BrowserDataView()
            case .errorLogs:
                ErrorLogView()
            case .loginItems:
                LoginItemsView()
            case .maintenance:
                MaintenanceView()
            case .privacy:
                PrivacyView()
            case .malware:
                MalwareView()
            case .spaceLens:
                SpaceLensView()
            case .memoryCleaner:
                MemoryCleanerView()
            case .appUpdater:
                AppUpdaterView()
            case .shredder:
                ShredderView()
            case .extensions:
                ExtensionsView()
            case .networkOptimization:
                NetworkOptimizationView()
            case .startupOptimization:
                StartupOptimizationView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}

struct LicenseStatusView: View {
    @EnvironmentObject var licenseManager: LicenseManager
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.secondary.opacity(0.1))
        )
    }
    
    var statusIcon: String {
        switch licenseManager.licenseStatus {
        case .licensed: return "checkmark.circle.fill"
        case .trial: return "clock.fill"
        case .trialExpired: return "exclamationmark.triangle.fill"
        case .invalid: return "xmark.circle.fill"
        }
    }
    
    var statusColor: Color {
        switch licenseManager.licenseStatus {
        case .licensed: return .green
        case .trial: return .blue
        case .trialExpired: return .orange
        case .invalid: return .red
        }
    }
    
    var statusText: String {
        switch licenseManager.licenseStatus {
        case .licensed:
            return licenseManager.licenseType?.rawValue ?? "Licensed"
        case .trial:
            return "\(licenseManager.trialDaysRemaining) days left"
        case .trialExpired:
            return "Trial Expired"
        case .invalid:
            return "Invalid License"
        }
    }
}

