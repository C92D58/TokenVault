import SwiftUI

// MARK: - Spotlight Search (Command+K)

/// Spotlight-style search overlay, triggered by ⌘K.
struct SpotlightSearch: View {
    @ObservedObject var store: DataStore
    @Binding var isVisible: Bool
    let onSelect: (TokenItem) -> Void

    @State private var query = ""
    @State private var selectedIndex = 0
    @FocusState private var isFocused: Bool

    private var results: [TokenItem] {
        store.search(query, in: nil).prefix(8).map { $0 }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary.opacity(0.6))
                TextField("搜尋 Token...", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .focused($isFocused)
                if !query.isEmpty {
                    Text("\(results.count)")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.4))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(.quaternary))
                }
                Text("⌘K")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.4))
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(.quaternary))
            }
            .padding(.horizontal, 16).padding(.vertical, 14)

            // Filter hints
            if !query.isEmpty {
                HStack(spacing: 6) {
                    filterChip("tag:AI")
                    filterChip("cat:Cloud")
                    filterChip("expired:true")
                    filterChip("fav:true")
                    Spacer()
                }
                .padding(.horizontal, 16).padding(.bottom, 8)
            }

            Divider().opacity(0.3)

            // Results
            if results.isEmpty && !query.isEmpty {
                VStack(spacing: 10) {
                    Spacer()
                    Image(systemName: "magnifyingglass").font(.system(size: 24)).foregroundColor(.secondary.opacity(0.3))
                    Text("無匹配結果").font(.system(size: 13)).foregroundColor(.secondary)
                    Spacer()
                }
                .frame(height: 200)
            } else if !results.isEmpty {
                ScrollView {
                    VStack(spacing: 1) {
                        ForEach(Array(results.enumerated()), id: \.element.id) { idx, token in
                            Button {
                                onSelect(token)
                                isVisible = false
                            } label: {
                                HStack(spacing: 10) {
                                    // Category emoji
                                    Text(token.category.emoji).font(.system(size: 14))
                                    // Provider icon
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(token.provider.color.swiftUIColor.opacity(0.1))
                                            .frame(width: 24, height: 24)
                                        Image(systemName: token.provider.icon)
                                            .font(.system(size: 11))
                                            .foregroundColor(token.provider.color.swiftUIColor)
                                    }
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(token.name).font(.system(size: 13, weight: .medium))
                                        Text("\(token.provider.rawValue) · \(token.environment.rawValue)")
                                            .font(.system(size: 10)).foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if token.isFavorite {
                                        Image(systemName: "star.fill").font(.system(size: 10)).foregroundColor(.orange)
                                    }
                                    // Shortcut hint for first 4 results
                                    if idx < 4 {
                                        Text("⌘\(idx + 1)")
                                            .font(.system(size: 10, design: .monospaced))
                                            .foregroundColor(.secondary.opacity(0.35))
                                    }
                                }
                                .padding(.horizontal, 14).padding(.vertical, 8)
                                .background(idx == selectedIndex ? Color.accentColor.opacity(0.08) : Color.clear)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } else {
                // Quick actions when empty
                VStack(spacing: 8) {
                    Spacer()
                    quickAction("plus.circle", "新增 Token", "⌘N")
                    quickAction("square.and.arrow.down", "導入 .env", "⌘I")
                    quickAction("wand.and.stars", "Token 工具箱")
                    quickAction("arrow.triangle.2.circlepath", "健康檢查")
                    Spacer()
                }
                .padding(.vertical, 8)
            }
        }
        .frame(width: 420, height: 340)
        .background(
            Color(.controlBackgroundColor)
                .overlay(.ultraThinMaterial)
        )
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.primary.opacity(0.10), lineWidth: 1))
        .shadow(color: .black.opacity(0.2), radius: 40, y: 16)
        .onAppear { isFocused = true; selectedIndex = 0 }
        .onKeyPress(.downArrow) {
            selectedIndex = min(selectedIndex + 1, results.count - 1)
            return .handled
        }
        .onKeyPress(.upArrow) {
            selectedIndex = max(0, selectedIndex - 1)
            return .handled
        }
        .onKeyPress(.return) {
            if selectedIndex < results.count {
                onSelect(results[selectedIndex])
                isVisible = false
            }
            return .handled
        }
        .onKeyPress(.escape) {
            isVisible = false
            return .handled
        }
    }

    private func filterChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 10, design: .monospaced))
            .foregroundColor(.secondary.opacity(0.5))
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().fill(.quaternary))
    }

    private func quickAction(_ icon: String, _ label: String, _ shortcut: String = "") -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 13)).foregroundColor(.secondary).frame(width: 20)
            Text(label).font(.system(size: 12))
            Spacer()
            if !shortcut.isEmpty {
                Text(shortcut).font(.system(size: 10, design: .monospaced)).foregroundColor(.secondary.opacity(0.4))
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 7)
        .contentShape(Rectangle())
    }
}
