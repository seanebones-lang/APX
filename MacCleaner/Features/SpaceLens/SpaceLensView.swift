//
//  SpaceLensView.swift
//  MacCleaner
//
//  Disk space visualizer with sunburst chart
//

import SwiftUI

struct SpaceLensView: View {
    @StateObject private var viewModel = SpaceLensViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.purple)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Space Lens")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("Visualize your disk space usage")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !viewModel.isScanning {
                    Button("Scan") {
                        Task {
                            await viewModel.scan()
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(color: .purple))
                }
            }
            .padding(30)
            
            Divider()
            
            // Content
            if viewModel.isScanning {
                VStack(spacing: 20) {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Scanning disk...")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else if let root = viewModel.rootNode {
                HSplitView {
                    // Sunburst Chart
                    SunburstChart(node: root, selectedNode: $viewModel.selectedNode)
                        .frame(minWidth: 400)
                    
                    // Details Panel
                    DetailsPanel(node: viewModel.selectedNode ?? root)
                        .frame(minWidth: 300)
                }
            } else {
                VStack(spacing: 24) {
                    Spacer()
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.purple.opacity(0.3))
                    Text("No disk analysis yet")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
    }
}

struct SunburstChart: View {
    let node: DiskNode
    @Binding var selectedNode: DiskNode?
    
    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            
            ZStack {
                // Draw sunburst segments
                ForEach(node.children.indices, id: \.self) { index in
                    let child = node.children[index]
                    SunburstSegment(
                        node: child,
                        center: center,
                        innerRadius: size * 0.15,
                        outerRadius: size * 0.4,
                        startAngle: angleFor(index: index),
                        selectedNode: $selectedNode
                    )
                }
                
                // Center circle
                Circle()
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .frame(width: size * 0.3, height: size * 0.3)
                    .overlay(
                        VStack(spacing: 8) {
                            Text(node.name)
                                .font(.title3.bold())
                                .lineLimit(1)
                            
                            Text(ByteCountFormatter.string(fromByteCount: node.size, countStyle: .file))
                                .font(.title2.bold())
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        .padding()
                    )
            }
        }
        .padding(40)
    }
    
    private func angleFor(index: Int) -> Angle {
        let totalSize = node.children.reduce(0) { $0 + $1.size }
        guard totalSize > 0 else { return .zero }
        
        var currentAngle: Double = 0
        for i in 0..<index {
            let portion = Double(node.children[i].size) / Double(totalSize)
            currentAngle += portion * 360
        }
        
        return .degrees(currentAngle)
    }
}

struct SunburstSegment: View {
    let node: DiskNode
    let center: CGPoint
    let innerRadius: CGFloat
    let outerRadius: CGFloat
    let startAngle: Angle
    @Binding var selectedNode: DiskNode?
    
    var angleSpan: Angle {
        guard let parent = node.parent else { return .zero }
        let totalSize = parent.children.reduce(0) { $0 + $1.size }
        guard totalSize > 0 else { return .zero }
        let portion = Double(node.size) / Double(totalSize)
        return .degrees(portion * 360)
    }
    
    var isSelected: Bool {
        selectedNode?.path == node.path
    }
    
    var body: some View {
        ZStack {
            // Segment path
            Path { path in
                path.addArc(
                    center: center,
                    radius: outerRadius,
                    startAngle: startAngle - .degrees(90),
                    endAngle: startAngle + angleSpan - .degrees(90),
                    clockwise: false
                )
                path.addArc(
                    center: center,
                    radius: innerRadius,
                    startAngle: startAngle + angleSpan - .degrees(90),
                    endAngle: startAngle - .degrees(90),
                    clockwise: true
                )
                path.closeSubpath()
            }
            .fill(colorForNode(node))
            .opacity(isSelected ? 1.0 : 0.8)
            .overlay(
                Path { path in
                    path.addArc(
                        center: center,
                        radius: outerRadius,
                        startAngle: startAngle - .degrees(90),
                        endAngle: startAngle + angleSpan - .degrees(90),
                        clockwise: false
                    )
                    path.addArc(
                        center: center,
                        radius: innerRadius,
                        startAngle: startAngle + angleSpan - .degrees(90),
                        endAngle: startAngle - .degrees(90),
                        clockwise: true
                    )
                    path.closeSubpath()
                }
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
        .onTapGesture {
            selectedNode = node
        }
    }
    
    private func colorForNode(_ node: DiskNode) -> Color {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .yellow, .green, .cyan, .indigo]
        let hash = abs(node.path.hashValue)
        return colors[hash % colors.count]
    }
}

struct DetailsPanel: View {
    let node: DiskNode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text(node.name)
                    .font(.title2.bold())
                
                Text(node.path)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(title: "Size", value: ByteCountFormatter.string(fromByteCount: node.size, countStyle: .file))
                InfoRow(title: "Items", value: "\(node.children.count)")
            }
            
            if !node.children.isEmpty {
                Divider()
                
                Text("Contents")
                    .font(.headline)
                
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(node.children.sorted(by: { $0.size > $1.size }).prefix(20), id: \.path) { child in
                            HStack {
                                Image(systemName: child.children.isEmpty ? "doc.fill" : "folder.fill")
                                    .foregroundColor(.blue)
                                
                                Text(child.name)
                                    .font(.system(size: 13))
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                Text(ByteCountFormatter.string(fromByteCount: child.size, countStyle: .file))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            
            Spacer()
            
            HStack {
                Button("Show in Finder") {
                    NSWorkspace.shared.selectFile(node.path, inFileViewerRootedAtPath: "")
                }
                .buttonStyle(.bordered)
                
                Button("Move to Trash") {
                    try? FileManager.default.trashItem(at: URL(fileURLWithPath: node.path), resultingItemURL: nil)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
        .padding(20)
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.subheadline.bold())
        }
    }
}

class DiskNode: Identifiable {
    let id = UUID()
    let path: String
    let name: String
    var size: Int64
    var children: [DiskNode] = []
    weak var parent: DiskNode?
    
    init(path: String, name: String, size: Int64) {
        self.path = path
        self.name = name
        self.size = size
    }
}

@MainActor
class SpaceLensViewModel: ObservableObject {
    @Published var isScanning = false
    @Published var rootNode: DiskNode?
    @Published var selectedNode: DiskNode?
    
    func scan() async {
        isScanning = true
        
        guard let homeDir = FileManager.default.homeDirectoryForCurrentUser.path as String? else {
            isScanning = false
            return
        }
        
        let root = DiskNode(path: homeDir, name: "Home", size: 0)
        rootNode = root
        selectedNode = root
        
        await buildTree(for: root, maxDepth: 2)
        
        isScanning = false
    }
    
    private func buildTree(for node: DiskNode, maxDepth: Int, currentDepth: Int = 0) async {
        guard currentDepth < maxDepth else { return }
        
        let fileManager = FileManager.default
        guard let contents = try? fileManager.contentsOfDirectory(atPath: node.path) else {
            return
        }
        
        for item in contents {
            let itemPath = "\(node.path)/\(item)"
            
            var isDirectory: ObjCBool = false
            guard fileManager.fileExists(atPath: itemPath, isDirectory: &isDirectory) else {
                continue
            }
            
            let size = calculateSize(at: itemPath)
            let childNode = DiskNode(path: itemPath, name: item, size: size)
            childNode.parent = node
            node.children.append(childNode)
            
            if isDirectory.boolValue && currentDepth + 1 < maxDepth {
                await buildTree(for: childNode, maxDepth: maxDepth, currentDepth: currentDepth + 1)
            }
        }
        
        // Update parent size
        node.size = node.children.reduce(0) { $0 + $1.size }
    }
    
    private func calculateSize(at path: String) -> Int64 {
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        
        for case let fileURL as URL in enumerator {
            if let size = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(size)
            }
        }
        
        return totalSize
    }
}
