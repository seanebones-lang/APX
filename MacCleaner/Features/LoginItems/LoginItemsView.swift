//
//  LoginItemsView.swift
//  MacCleaner
//

import SwiftUI

struct LoginItemsView: View {
    @StateObject private var viewModel = LoginItemsViewModel()
    @EnvironmentObject var soundManager: SoundManager
    
    var body: some View {
        ModuleView(
            title: "Login Items",
            subtitle: "Manage startup items and launch agents",
            icon: "rectangle.stack.badge.play.fill",
            iconGradient: [.indigo, .purple],
            isScanning: viewModel.isScanning,
            results: viewModel.items.map { item in
                ScanResult(path: item.path, size: 0, type: .other, category: item.type.rawValue)
            },
            onScan: {
                soundManager.play(.buttonClick)
                Task {
                    await viewModel.scan()
                }
            },
            onClean: {
                soundManager.play(.buttonClick)
                Task {
                    await viewModel.removeSelected()
                }
            }
        ) {
            if !viewModel.items.isEmpty {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.items) { item in
                            LoginItemRow(
                                item: item,
                                isSelected: viewModel.selectedItems.contains(item.id),
                                onToggle: {
                                    if viewModel.selectedItems.contains(item.id) {
                                        viewModel.selectedItems.remove(item.id)
                                    } else {
                                        viewModel.selectedItems.insert(item.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding()
                }
            }
        }
        .onAppear {
            if viewModel.items.isEmpty && !viewModel.isScanning {
                Task {
                    await viewModel.scan()
                }
            }
        }
    }
}

struct LoginItemRow: View {
    let item: LoginItem
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: onToggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.system(size: 24))
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(item.type.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(item.path)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Image(systemName: item.isEnabled ? "checkmark.circle.fill" : "circle")
                .foregroundColor(item.isEnabled ? .green : .gray)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

@MainActor
class LoginItemsViewModel: ObservableObject {
    @Published var items: [LoginItem] = []
    @Published var selectedItems: Set<UUID> = []
    @Published var isScanning: Bool = false
    
    private let scanner = LoginItemsScanner.shared
    
    func scan() async {
        isScanning = true
        items = await scanner.scan()
        isScanning = false
    }
    
    func removeSelected() async {
        let itemsToRemove = items.filter { selectedItems.contains($0.id) }
        
        for item in itemsToRemove {
            try? await scanner.remove(item)
        }
        
        items.removeAll { selectedItems.contains($0.id) }
        selectedItems.removeAll()
    }
}

