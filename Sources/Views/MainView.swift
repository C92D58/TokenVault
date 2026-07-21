import SwiftUI
import AppKit

// MARK: - Main View (NavigationSplitView)

struct MainView: View {
    @ObservedObject var store: DataStore
    @State private var searchText = ""
    @State private var selectedGroup: TokenGroup? = nil
    @State private var selectedEnv: TokenEnvironment? = nil
    @State private var selectedType: TokenType? = nil
    @State private var showAddToken = false
    @State private var showAddGroup = false
    @State private var showGenerator = false
    @State private var showImport = false
    @State private var editingToken: TokenItem? = nil
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var tokens: [TokenItem] {
        var result = store.search(searchText, in: selectedGroup)
        if let env = selectedEnv { result = result.filter { $0.environment == env } }
        if let type = selectedType { result = result.filter { $0.tokenType == type } }
        return result
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarView
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 240)
        } detail: {
            contentView
        }
        .sheet(isPresented: $showAddToken) {
            TokenEditor(store: store, token: editingToken) { showAddToken = false; editingToken = nil }
        }
        .sheet(isPresented: $showAddGroup) {
            GroupSheet(store: store) { showAddGroup = false }
        }
        .sheet(isPresented: $showGenerator) {
            TokenGeneratorView()
        }
        .sheet(isPresented: $showImport) {
            ImportWizard(store: store) { showImport = false }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAddToken)) { _ in
            editingToken = nil; showAddToken = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAddGroup)) { _ in
            showAddGroup = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showImportWizard)) { _ in
            showImport = true
        }
        .onChange(of: editingToken) { _, _ in if editingToken != nil { showAddToken = true } }
    }

    // MARK: - Sidebar

    private var sidebarView: some View {
        VStack(spacing: 0) {
            // Brand
            HStack(spacing: 7) {
                brandIcon
                Text("TokenVault").font(.system(size: 12, weight: .bold)).tracking(-0.2)
                Spacer()
                Button { showAddGroup = true } label: {
                    Image(systemName: "folder.badge.plus").font(.system(size: 12))
                }.buttonStyle(.plain).foregroundColor(.secondary)
            }
            .padding(.horizontal, 12).padding(.vertical, 10)

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 1) {
                    SidebarItem(label: "所有 Token", icon: "tray.full.fill",
                                count: store.allTokens.count,
                                isSelected: selectedGroup == nil && selectedEnv == nil && selectedType == nil,
                                action: { selectedGroup = nil; selectedEnv = nil; selectedType = nil })

                    // Environments
                    SidebarSection("環境")
                    ForEach(TokenEnvironment.allCases, id: \.self) { env in
                        let count = store.allTokens.filter { $0.environment == env }.count
                        SidebarItem(label: env.rawValue, icon: env.icon, count: count,
                                    isSelected: selectedEnv == env,
                                    action: { selectedEnv = (selectedEnv == env) ? nil : env; selectedType = nil })
                    }

                    // Groups
                    if !store.groups.isEmpty {
                        SidebarSection("分組")
                        ForEach(store.groups) { group in
                            SidebarItem(label: group.name, icon: group.icon, count: group.tokens.count,
                                        isSelected: selectedGroup == group,
                                        action: { selectedGroup = (selectedGroup == group) ? nil : group })
                        }
                    }

                    // Types
                    let usedTypes = Set(store.allTokens.map(\.tokenType))
                    if usedTypes.count > 1 {
                        SidebarSection("類型")
                        ForEach(TokenType.allCases.filter { usedTypes.contains($0) }, id: \.self) { type in
                            let count = store.allTokens.filter { $0.tokenType == type }.count
                            SidebarItem(label: type.label, icon: type.icon, count: count,
                                        isSelected: selectedType == type,
                                        action: { selectedType = (selectedType == type) ? nil : type })
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .background(.bar)
    }

    private var brandIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(LinearGradient(colors: [Color(red: 0.65, green: 0.55, blue: 0.98), Color(red: 0.45, green: 0.35, blue: 0.85)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 22, height: 22)
            Image(systemName: "key.horizontal.fill").font(.system(size: 10, weight: .bold)).foregroundColor(.white)
        }
    }

    // MARK: - Content

    private var contentView: some View {
        VStack(spacing: 0) {
            DashboardBar(store: store)
            toolbarView
            Divider()
            if tokens.isEmpty { emptyView } else { listView }
        }
        .background(Color(.controlBackgroundColor))
        .overlay(alignment: .bottomTrailing) {
            KeyboardHUD().padding(20)
        }
    }

    // MARK: - Toolbar

    private var toolbarView: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary.opacity(0.5)).font(.system(size: 11))
                TextField("搜尋..." + (selectedEnv != nil ? " · \(selectedEnv!.rawValue)" : ""), text: $searchText)
                    .textFieldStyle(.plain).font(.system(size: 12))
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 10)).foregroundColor(.secondary.opacity(0.4))
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 7).fill(.bar))
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(.white.opacity(0.06), lineWidth: 1))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(TokenEnvironment.allCases, id: \.self) { env in
                        Button { selectedEnv = selectedEnv == env ? nil : env } label: {
                            Text(env.rawValue).font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 8).padding(.vertical, 3)
                                .background(selectedEnv == env
                                    ? Capsule().fill(AnyShapeStyle(env.color.fg.swiftUIColor))
                                    : Capsule().fill(AnyShapeStyle(.quaternary)))
                                .foregroundColor(selectedEnv == env ? env.color.bg.swiftUIColor : .secondary)
                        }.buttonStyle(.plain)
                    }
                }
            }

            Spacer()

            Button { showImport = true } label: {
                Image(systemName: "square.and.arrow.down").font(.system(size: 13)).foregroundColor(.secondary)
            }.buttonStyle(.plain).help("導入 Token")

            Button { showGenerator = true } label: {
                Image(systemName: "wand.and.stars").font(.system(size: 13)).foregroundColor(.secondary)
            }.buttonStyle(.plain).help("Token 產生器")

            Button { editingToken = nil; showAddToken = true } label: {
                Image(systemName: "plus.circle.fill").font(.system(size: 16))
                    .foregroundStyle(LinearGradient(colors: [Color(red: 0.65, green: 0.55, blue: 0.98), Color(red: 0.45, green: 0.35, blue: 0.85)], startPoint: .topLeading, endPoint: .bottomTrailing))
            }.buttonStyle(.plain)

            Button { (NSApp.delegate as? AppDelegate)?.showSettings() } label: {
                Image(systemName: "gearshape").font(.system(size: 13)).foregroundColor(.secondary)
            }.buttonStyle(.plain).help("設定")
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
    }

    // MARK: - List

    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(tokens) { token in
                    TokenCard(token: token, store: store) { editingToken = token }
                }
            }
            .padding(14)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 14) {
            Spacer()
            ZStack {
                Circle().fill(Color.accentColor.opacity(0.08)).frame(width: 72, height: 72)
                Image(systemName: "key.horizontal").font(.system(size: 28)).foregroundColor(.accentColor.opacity(0.5))
            }
            Text(searchText.isEmpty ? "尚無 Token" : "無匹配").font(.system(size: 13, weight: .medium)).foregroundColor(.secondary)
            if searchText.isEmpty {
                HStack(spacing: 8) {
                    Button("新增 Token") { editingToken = nil; showAddToken = true }.buttonStyle(.borderedProminent).controlSize(.small)
                    Button("導入") { showImport = true }.buttonStyle(.bordered).controlSize(.small)
                }
            }
            Spacer()
        }
    }
}

// MARK: - Sidebar Components

private struct SidebarItem: View {
    let label: String; let icon: String; let count: Int
    let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 11)).frame(width: 18)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                Text(label).font(.system(size: 12)).lineLimit(1)
                    .foregroundColor(isSelected ? .primary : .secondary)
                Spacer()
                if count > 0 {
                    Text("\(count)").font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
            .contentShape(Rectangle())
        }.buttonStyle(.plain)
    }
}

private struct SidebarSection: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text).font(.system(size: 10, weight: .semibold)).foregroundColor(.secondary.opacity(0.5))
            .padding(.horizontal, 12).padding(.top, 6)
    }
}

// MARK: - Token Card (Hoppscotch style)

struct TokenCard: View {
    @ObservedObject var token: TokenItem
    @ObservedObject var store: DataStore
    let onEdit: () -> Void

    @State private var isHovering = false
    @State private var copied = false
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2)
                .fill(token.tokenType.color.swiftUIColor)
                .frame(width: 3).padding(.vertical, 8)

            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(token.tokenType.color.swiftUIColor.opacity(0.1))
                        .frame(width: 32, height: 32)
                    Image(systemName: token.tokenType.icon)
                        .font(.system(size: 13)).foregroundColor(token.tokenType.color.swiftUIColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(token.name).font(.system(size: 12.5, weight: .medium)).tracking(-0.15).lineLimit(1)
                        if token.isFavorite {
                            Image(systemName: "star.fill").font(.system(size: 9)).foregroundColor(.orange)
                        }
                        Text(token.environment.rawValue).font(.system(size: 8.5, weight: .bold))
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Capsule().fill(token.envColor.opacity(0.12)))
                            .foregroundColor(token.envColor)
                    }
                    Text(token.maskedValue).font(.system(size: 10, design: .monospaced)).foregroundColor(.secondary).lineLimit(1)
                }

                Spacer()

                if isHovering {
                    HStack(spacing: 4) {
                        Button {
                            (NSApp.delegate as? AppDelegate)?.copyToken(token)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { copied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation { copied = false } }
                        } label: {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc").font(.system(size: 11))
                                .frame(width: 26, height: 26).background(Circle().fill(copied ? Color.green.opacity(0.1) : Color.primary.opacity(0.04)))
                                .foregroundColor(copied ? .green : .secondary)
                        }.buttonStyle(.plain).transition(.scale.combined(with: .opacity))

                        Button { onEdit() } label: {
                            Image(systemName: "pencil").font(.system(size: 10)).foregroundColor(.secondary)
                                .frame(width: 26, height: 26).background(Circle().fill(Color.primary.opacity(0.04)))
                        }.buttonStyle(.plain)

                        Menu {
                            Button { (NSApp.delegate as? AppDelegate)?.toggleFav(token) } label: {
                                Label(token.isFavorite ? "取消收藏" : "收藏", systemImage: token.isFavorite ? "star.slash" : "star")
                            }
                            Divider()
                            Button(role: .destructive) { (NSApp.delegate as? AppDelegate)?.deleteToken(token) } label: {
                                Label("刪除", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis").font(.system(size: 10)).foregroundColor(.secondary)
                                .frame(width: 26, height: 26).background(Circle().fill(Color.primary.opacity(0.04)))
                        }.buttonStyle(.plain).menuIndicator(.hidden)
                    }.animation(.easeOut(duration: 0.12), value: isHovering)
                }

                if token.isExpired {
                    Text("過期").font(.system(size: 8, weight: .bold)).foregroundColor(.red)
                        .padding(.horizontal, 5).padding(.vertical, 2).background(Capsule().fill(Color.red.opacity(0.1)))
                } else if token.expiresSoon {
                    Text("即將").font(.system(size: 8, weight: .bold)).foregroundColor(.orange)
                        .padding(.horizontal, 5).padding(.vertical, 2).background(Capsule().fill(Color.orange.opacity(0.1)))
                }
            }
            .padding(.leading, 10).padding(.trailing, 10).padding(.vertical, 10)
        }
        .background(RoundedRectangle(cornerRadius: 8)
            .fill(isHovering ? Color.primary.opacity(0.03) : Color.clear)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(isHovering ? 0.06 : 0.02), lineWidth: 1)))
        .scaleEffect(isPressed ? 0.985 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        .onHover { hovering in withAnimation(.easeOut(duration: 0.15)) { isHovering = hovering } }
        .onTapGesture(count: 2) {
            (NSApp.delegate as? AppDelegate)?.copyToken(token)
        }
        .onTapGesture {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) { isPressed = false }
            }
        }
    }
}

// MARK: - Color helpers

extension String {
    var swiftUIColor: Color {
        let s = trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        guard s.count == 6, let num = Int(s, radix: 16) else { return .accentColor }
        return Color(red: Double((num >> 16) & 0xFF)/255, green: Double((num >> 8) & 0xFF)/255, blue: Double(num & 0xFF)/255)
    }
}
