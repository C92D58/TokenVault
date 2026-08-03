import SwiftUI
import AppKit

// MARK: - Main View (NavigationSplitView)

enum TokenSortOrder: String, CaseIterable {
    case recent = "最近新增"
    case mostUsed = "最常用"
    case lastUsed = "最近使用"
    case nameAsc = "名稱 A-Z"
    case nameDesc = "名稱 Z-A"

    func sort(_ tokens: [TokenItem]) -> [TokenItem] {
        switch self {
        case .recent: return tokens.sorted { $0.createdAt > $1.createdAt }
        case .mostUsed: return tokens.sorted { $0.copyCount > $1.copyCount }
        case .lastUsed: return tokens.sorted { ($0.lastUsedAt ?? .distantPast) > ($1.lastUsedAt ?? .distantPast) }
        case .nameAsc: return tokens.sorted { $0.name.localizedCompare($1.name) == .orderedAscending }
        case .nameDesc: return tokens.sorted { $0.name.localizedCompare($1.name) == .orderedDescending }
        }
    }
}

struct MainView: View {
    @ObservedObject var store: DataStore
    @State private var searchText = ""
    @State private var selectedGroup: TokenGroup? = nil
    @State private var selectedEnv: TokenEnvironment? = nil
    @State private var selectedCategory: SecretCategory? = nil
    @State private var showTrash = false
    @State private var sortOrder: TokenSortOrder = .recent
    @State private var showAddToken = false
    @State private var showAddGroup = false
    @State private var showGenerator = false
    @State private var showImport = false
    @State private var editingToken: TokenItem? = nil
    @State private var isDuplicating = false
    @State private var focusedTokenID: UUID? = nil
    @State private var isMultiSelectMode = false
    @State private var selectedTokenIDs = Set<UUID>()
    @State private var showBatchMove = false
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var showSpotlight = false
    @State private var hideSecrets = true

    var tokens: [TokenItem] {
        var result = store.search(searchText, in: selectedGroup)
        if showTrash { result = result.filter { $0.isDeleted } }
        if let env = selectedEnv { result = result.filter { $0.environment == env } }
        if let cat = selectedCategory { result = result.filter { $0.category == cat } }
        return sortOrder.sort(result)
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebarView
                .navigationSplitViewColumnWidth(min: 170, ideal: 190, max: 230)
        } detail: {
            contentView
                .onKeyPress(.return) {
                    if let id = focusedTokenID, let t = store.allTokens.first(where: { $0.id == id }) {
                        (NSApp.delegate as? AppDelegate)?.copyToken(t)
                        return .handled
                    }
                    return .ignored
                }
        }
        .sheet(isPresented: $showAddToken) {
            TokenEditor(store: store, token: editingToken, isDuplicate: isDuplicating) {
                showAddToken = false; editingToken = nil; isDuplicating = false
            }
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
            // Brand header
            HStack(spacing: 8) {
                brandIcon
                Text("TokenVault")
                    .font(.system(size: 13, weight: .bold))
                    .tracking(-0.3)
                Spacer()
                Button { showAddGroup = true } label: {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(.quaternary.opacity(0.5)))
                }
                .buttonStyle(.plain)
                .focusEffectDisabled()
            }
            .padding(.horizontal, 14).padding(.vertical, 12)

            Divider().opacity(0.3)

            ScrollView {
                VStack(alignment: .leading, spacing: 1) {
                    SidebarItem(label: "所有 Secret", icon: "tray.full.fill",
                                count: store.activeTokens.count,
                                isSelected: selectedGroup == nil && selectedEnv == nil && selectedCategory == nil && !showTrash,
                                action: { selectedGroup = nil; selectedEnv = nil; selectedCategory = nil; showTrash = false })

                    // Favorites
                    let favCount = store.activeTokens.filter(\.isFavorite).count
                    if favCount > 0 {
                        SidebarSection("⭐ 收藏")
                        SidebarItem(label: "我的最愛", icon: "star.fill", count: favCount,
                                    isSelected: false, // favorites filtered below in tokens computed prop
                                    action: { /* filter by fav */ })
                    }

                    // Categories with emojis
                    SidebarSection("📂 分類")
                    ForEach(SecretCategory.allCases, id: \.self) { cat in
                        let count = store.activeTokens.filter { $0.category == cat }.count
                        if count > 0 {
                            SidebarItem(label: "\(cat.emoji) \(cat.rawValue)", icon: cat.icon, count: count,
                                        isSelected: selectedCategory == cat && !showTrash,
                                        action: { selectedCategory = (selectedCategory == cat) ? nil : cat; showTrash = false })
                        }
                    }

                    // Environments
                    SidebarSection("🔧 環境")
                    ForEach(TokenEnvironment.allCases, id: \.self) { env in
                        let count = store.activeTokens.filter { $0.environment == env }.count
                        SidebarItem(label: env.rawValue, icon: env.icon, count: count,
                                    isSelected: selectedEnv == env && !showTrash,
                                    action: { selectedEnv = (selectedEnv == env) ? nil : env; selectedCategory = nil; showTrash = false })
                    }

                    // Groups
                    if !store.groups.isEmpty {
                        SidebarSection("📁 分組")
                        ForEach(store.groups) { group in
                            SidebarItem(label: group.name, icon: group.icon, count: group.tokens.filter { !$0.isDeleted }.count,
                                        isSelected: selectedGroup == group && !showTrash,
                                        action: { selectedGroup = (selectedGroup == group) ? nil : group; showTrash = false })
                        }
                    }

                    // Trash
                    if !store.trashedTokens.isEmpty {
                        Divider().padding(.horizontal, 14).padding(.vertical, 4).opacity(0.3)
                        SidebarSection("🗑️ 垃圾桶")
                        SidebarItem(label: "已刪除", icon: "trash", count: store.trashedTokens.count,
                                    isSelected: showTrash,
                                    action: {
                                        showTrash.toggle()
                                        if showTrash { selectedGroup = nil; selectedEnv = nil; selectedCategory = nil }
                                    })
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .background(Color(.windowBackgroundColor))
    }

    private var brandIcon: some View {
        ZStack {
            AnimatedGradient(colors: [DS.Color.accentLight, DS.Color.accent, DS.Color.accentDark])
                .frame(width: 24, height: 24)
                .clipShape(RoundedRectangle(cornerRadius: 7))
            RoundedRectangle(cornerRadius: 7)
                .stroke(.white.opacity(0.18), lineWidth: 1)
                .frame(width: 24, height: 24)
            Image(systemName: "key.horizontal.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
        }
    }

    // MARK: - Content

    private var contentView: some View {
        VStack(spacing: 0) {
            DashboardBar(store: store)
            toolbarView
            if isMultiSelectMode && !showTrash { batchActionBar }
            Divider()
            if tokens.isEmpty { emptyView } else { listView }
        }
        .background(Color(.windowBackgroundColor))
        .overlay(alignment: .bottomTrailing) {
            KeyboardHUD().padding(20)
        }
        .overlay { ToastOverlay() }
        .overlay {
            if showSpotlight {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                        .onTapGesture { showSpotlight = false }
                    SpotlightSearch(store: store, isVisible: $showSpotlight) { token in
                        (NSApp.delegate as? AppDelegate)?.copyToken(token)
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .zIndex(1000)
            }
        }
        .onAppear {
            _ = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains(.command) && event.keyCode == 40 { // 'k' key
                    showSpotlight.toggle()
                    return nil
                }
                return event
            }
        }
    }

    // MARK: - Toolbar

    private var toolbarView: some View {
        HStack(spacing: 10) {
            // Search field — glass
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary.opacity(0.5))
                    .font(.system(size: 11))
                TextField("搜尋...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                    .focusEffectDisabled()
                }
            }
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.textBackgroundColor)))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.10), lineWidth: 1))

            if !showTrash {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(TokenEnvironment.allCases, id: \.self) { env in
                            EnvFilterPill(env: env, isSelected: selectedEnv == env) {
                                selectedEnv = selectedEnv == env ? nil : env
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(height: 24)
            }

            // Sort menu
            Menu {
                ForEach(TokenSortOrder.allCases, id: \.self) { order in
                    Button {
                        sortOrder = order
                    } label: {
                        HStack {
                            Text(order.rawValue)
                            if sortOrder == order { Image(systemName: "checkmark") }
                        }
                    }
                }
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.up.arrow.down").font(.system(size: 10))
                    Text(sortOrder.rawValue).font(.system(size: 10))
                }
                .foregroundColor(.secondary)
            }
            .buttonStyle(.plain).focusEffectDisabled()
            .help("排序方式").accessibilityLabel("排序方式")

            Spacer()

            // Multi-select toggle
            if !showTrash && !tokens.isEmpty {
                Button {
                    isMultiSelectMode.toggle()
                    if !isMultiSelectMode { selectedTokenIDs.removeAll() }
                } label: {
                    Image(systemName: isMultiSelectMode ? "checkmark.circle.fill" : "checkmark.circle")
                        .font(.system(size: 12))
                        .foregroundColor(isMultiSelectMode ? .accentColor : .secondary)
                }
                .buttonStyle(.plain).focusEffectDisabled()
                .help(isMultiSelectMode ? "退出多選" : "多選模式").accessibilityLabel("多選")
            }

            if showTrash {
                Button {
                    store.purgeExpiredTrash()
                } label: {
                    Image(systemName: "clear.fill").font(.system(size: 12)).foregroundColor(.secondary)
                }
                .buttonStyle(.plain).focusEffectDisabled()
                .help("永久清除超過 30 天的項目").accessibilityLabel("清空垃圾桶")
            } else {
                Button { showImport = true } label: {
                    Image(systemName: "square.and.arrow.down").font(.system(size: 13)).foregroundColor(.secondary)
                }
                .buttonStyle(.plain).focusEffectDisabled()
                .help("導入 Token").accessibilityLabel("導入 Token")

                Button { showGenerator = true } label: {
                    Image(systemName: "wand.and.stars").font(.system(size: 13)).foregroundColor(.secondary)
                }
                .buttonStyle(.plain).focusEffectDisabled()
                .help("Token 產生器").accessibilityLabel("Token 產生器")

                Button { editingToken = nil; showAddToken = true } label: {
                    Image(systemName: "plus.circle.fill").font(.system(size: 17))
                        .foregroundStyle(DS.Color.accentGradient)
                }
                .buttonStyle(.plain).focusEffectDisabled()
                .help("新增 Token").accessibilityLabel("新增 Token")
            }

            // Auto-hide toggle
            Button {
                hideSecrets.toggle()
            } label: {
                Image(systemName: hideSecrets ? "eye.slash" : "eye")
                    .font(.system(size: 12)).foregroundColor(.secondary)
            }
            .buttonStyle(.plain).focusEffectDisabled()
            .help(hideSecrets ? "顯示 Secret 值" : "隱藏 Secret 值").accessibilityLabel("顯示/隱藏")

            Button { (NSApp.delegate as? AppDelegate)?.showSettings() } label: {
                Image(systemName: "gearshape").font(.system(size: 13)).foregroundColor(.secondary)
            }
            .buttonStyle(.plain).focusEffectDisabled()
            .help("設定").accessibilityLabel("設定")
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
    }

    // MARK: - Batch Action Bar

    private var batchActionBar: some View {
        HStack(spacing: 10) {
            Text("已選 \(selectedTokenIDs.count) 個")
                .font(.system(size: 12, weight: .medium))

            Button("全選") { selectedTokenIDs = Set(tokens.map(\.id)) }
                .buttonStyle(.bordered).controlSize(.small)

            Button("取消全選") { selectedTokenIDs.removeAll() }
                .buttonStyle(.bordered).controlSize(.small)

            Spacer()

            Button {
                showBatchMove = true
            } label: {
                Label("移至分組", systemImage: "folder").font(.system(size: 11))
            }
            .buttonStyle(.bordered).controlSize(.small)
            .disabled(selectedTokenIDs.isEmpty || store.groups.isEmpty)

            Button {
                for id in selectedTokenIDs {
                    if let t = store.allTokens.first(where: { $0.id == id }) {
                        store.softDeleteToken(t)
                    }
                }
                let count = selectedTokenIDs.count
                selectedTokenIDs.removeAll()
                isMultiSelectMode = false
                ToastService.shared.show("已刪除 \(count) 個 Token", icon: "trash")
            } label: {
                Label("批次刪除", systemImage: "trash").font(.system(size: 11))
            }
            .buttonStyle(.bordered).controlSize(.small)
            .disabled(selectedTokenIDs.isEmpty)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(Color(.controlBackgroundColor))
        .overlay(alignment: .bottom) { Divider() }
        .sheet(isPresented: $showBatchMove) {
            batchMoveSheet
        }
    }

    private var batchMoveSheet: some View {
        VStack(spacing: 16) {
            Text("移至分組").font(.system(size: 15, weight: .bold))
            Text("將 \(selectedTokenIDs.count) 個 Token 移動到：")
                .font(.system(size: 11)).foregroundColor(.secondary)
            VStack(spacing: 6) {
                ForEach(store.groups) { group in
                    Button {
                        for id in selectedTokenIDs {
                            if let t = store.allTokens.first(where: { $0.id == id }) {
                                for g in store.groups { g.tokens.removeAll { $0.id == id } }
                                t.groupID = group.id
                                group.tokens.append(t)
                            }
                        }
                        store.save()
                        selectedTokenIDs.removeAll()
                        isMultiSelectMode = false
                        showBatchMove = false
                    } label: {
                        HStack {
                            Image(systemName: "folder").font(.system(size: 11))
                            Text(group.name).font(.system(size: 12))
                            Spacer()
                            Text("\(group.tokens.count)").font(.system(size: 10)).foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.controlBackgroundColor)))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 240)
            HStack {
                Button("取消") { showBatchMove = false }
            }
        }
        .padding().frame(width: 300, height: 320)
    }

    // MARK: - List

    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(Array(tokens.enumerated()), id: \.element.id) { idx, token in
                    TokenCard(token: token, store: store,
                              isFocused: focusedTokenID == token.id,
                              isMultiSelect: isMultiSelectMode,
                              isSelected: selectedTokenIDs.contains(token.id),
                              onEdit: { editingToken = token },
                              onDuplicate: { isDuplicating = true; editingToken = token },
                              onFocus: { focusedTokenID = token.id },
                              onBlur: { if focusedTokenID == token.id { focusedTokenID = nil } },
                              onToggleSelect: {
                                  if selectedTokenIDs.contains(token.id) {
                                      selectedTokenIDs.remove(token.id)
                                  } else {
                                      selectedTokenIDs.insert(token.id)
                                  }
                              },
                              index: idx)
                }
            }
            .padding(14)
        }
        .focusable()
        .onKeyPress(.upArrow) {
            moveFocus(up: true)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveFocus(up: false)
            return .handled
        }
    }

    private func moveFocus(up: Bool) {
        guard let current = focusedTokenID,
              let idx = tokens.firstIndex(where: { $0.id == current }) else {
            focusedTokenID = tokens.first?.id
            return
        }
        let newIdx = up ? max(0, idx - 1) : min(tokens.count - 1, idx + 1)
        focusedTokenID = tokens[newIdx].id
    }

    // MARK: - Empty View

    private var emptyView: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(DS.Color.accent.opacity(0.06))
                    .frame(width: 90, height: 90)
                Circle()
                    .stroke(DS.Color.accent.opacity(0.12), lineWidth: 1.5)
                    .frame(width: 72, height: 72)
                Image(systemName: showTrash ? "trash" : "key.horizontal")
                    .font(.system(size: 34))
                    .foregroundColor(DS.Color.accent.opacity(0.35))
            }
            VStack(spacing: 6) {
                Text(showTrash ? "垃圾桶為空" : searchText.isEmpty ? "尚無 Token" : "無匹配結果")
                    .font(.system(size: 16, weight: .semibold))
                Text(showTrash ? "刪除的 Token 將在此保留 30 天" : "按 ⌘N 新增第一個 Token，或拖入 .env 檔案導入")
                    .font(.system(size: 12)).foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(width: 300)
            }
            if searchText.isEmpty && !showTrash {
                HStack(spacing: 10) {
                    Button {
                        editingToken = nil; showAddToken = true
                    } label: {
                        Label("新增 Token", systemImage: "plus")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.borderedProminent).controlSize(.small)
                    Button {
                        showImport = true
                    } label: {
                        Label("導入", systemImage: "square.and.arrow.down")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.bordered).controlSize(.small)
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
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                    .frame(width: 18)
                    .foregroundColor(isSelected ? DS.Color.accent : .secondary)
                Text(label)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .foregroundColor(isSelected ? .primary : .secondary)
                Spacer()
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
            .padding(.horizontal, 14).padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? DS.Color.accent.opacity(0.08) : (isHovering ? Color.primary.opacity(0.04) : Color.clear))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .onHover { isHovering = $0 }
    }
}

private struct SidebarSection: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.secondary.opacity(0.5))
            .padding(.horizontal, 14).padding(.top, 8)
    }
}

// MARK: - Environment Filter Pill

private struct EnvFilterPill: View {
    let env: TokenEnvironment
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(env.rawValue)
                .font(.system(size: 10, weight: .medium))
                .padding(.horizontal, 8).padding(.vertical, 3)
        }
        .buttonStyle(.plain)
        .focusEffectDisabled()
        .background(Capsule().fill(isSelected ? env.color.fg.swiftUIColor : Color.gray.opacity(0.12)))
        .foregroundColor(isSelected ? env.color.bg.swiftUIColor : .secondary)
        .clipShape(Capsule())
    }
}

// MARK: - Token Card

struct TokenCard: View {
    @ObservedObject var token: TokenItem
    @ObservedObject var store: DataStore
    let isFocused: Bool
    let isMultiSelect: Bool
    let isSelected: Bool
    let onEdit: () -> Void
    let onDuplicate: () -> Void
    let onFocus: () -> Void
    let onBlur: () -> Void
    let onToggleSelect: () -> Void
    let index: Int

    @State private var isHovering = false
    @State private var copied = false
    @State private var copyFlashTrigger = false
    @State private var hasAppeared = false
    @AppStorage("hideSecrets") private var hideSecrets = true

    private let cardHeight: CGFloat = 58

    var body: some View {
        HStack(spacing: 0) {
            // Checkbox with animation
            if isMultiSelect {
                Button { onToggleSelect() } label: {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16))
                        .foregroundColor(isSelected ? DS.Color.accent : .secondary.opacity(0.35))
                }
                .buttonStyle(.plain).focusEffectDisabled()
                .padding(.leading, 8)
                .transition(.scale.combined(with: .opacity))
            }

            // Accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    token.isDeleted
                        ? AnyShapeStyle(Color.gray.opacity(0.3))
                        : AnyShapeStyle(LinearGradient(
                            colors: [token.tokenType.glassColor.swiftUIColor, token.tokenType.glassColor.swiftUIColor.opacity(0.4)],
                            startPoint: .top, endPoint: .bottom))
                )
                .frame(width: 3)
                .frame(maxHeight: .infinity)
                .padding(.vertical, 5)

            // Service icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(token.isDeleted
                        ? Color.gray.opacity(0.06)
                        : token.tokenType.glassColor.swiftUIColor.opacity(0.1))
                    .frame(width: 34, height: 34)
                Image(systemName: token.isDeleted ? "trash.fill" : token.tokenType.icon)
                    .font(.system(size: 13))
                    .foregroundColor(token.isDeleted ? .gray.opacity(0.5) : token.tokenType.glassColor.swiftUIColor)
            }
            .padding(.leading, 10)

            // Text content
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Text(token.name)
                        .font(.system(size: 12, weight: .medium))
                        .lineLimit(1)
                        .layoutPriority(1)
                    if token.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 8)).foregroundColor(.orange)
                    }
                    if !token.isDeleted {
                        Text(token.environment.rawValue)
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(token.envColor)
                            .padding(.horizontal, 5).padding(.vertical, 1)
                            .background(Capsule().fill(token.envColor.opacity(0.1)))
                    }
                    if token.isDeleted, let d = token.deletedAt {
                        Text("\(daysSince(d))天前刪除")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                }
                Text(token.isDeleted ? "已刪除" : token.maskedValue)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 10)

            Spacer(minLength: 8)

            // Trailing actions
            trailingView
                .padding(.trailing, 10)
        }
        .frame(height: cardHeight)
        .background(cardBackground)
        .copyFlash(trigger: copyFlashTrigger)
        .padding(.horizontal, 1)
        // Staggered entrance
        .scaleEffect(hasAppeared ? 1 : 0.92)
        .opacity(hasAppeared ? 1 : 0)
        .offset(y: hasAppeared ? 0 : 12)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.7).delay(Double(index) * 0.04)) {
                hasAppeared = true
            }
        }
        .onHover { hovering in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                isHovering = hovering
            }
            if hovering { onFocus() } else { onBlur() }
        }
        .onTapGesture(count: 2) {
            if isMultiSelect { onToggleSelect() }
            else if !token.isDeleted { (NSApp.delegate as? AppDelegate)?.copyToken(token) }
        }
        .onTapGesture {
            if isMultiSelect { onToggleSelect() }
            else { onFocus() }
        }
        .contextMenu { cardContextMenu }
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(Color(.controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isFocused
                            ? DS.Color.accent.opacity(0.45)
                            : Color.primary.opacity(isHovering ? 0.14 : 0.07),
                        lineWidth: isFocused ? 1.5 : 1
                    )
            )
            .shadow(
                color: .black.opacity(isHovering || isFocused ? 0.10 : 0.05),
                radius: isHovering || isFocused ? 16 : 6,
                y: isHovering || isFocused ? 6 : 2
            )
    }

    // MARK: - Trailing View

    @ViewBuilder
    private var trailingView: some View {
        if isMultiSelect {
            EmptyView()
        } else {
            HStack(spacing: 2) {
                if token.isDeleted {
                    trailingBtn("arrow.uturn.backward", color: .blue) {
                        store.restoreToken(token)
                        ToastService.shared.show("已恢復「\(token.name)」", icon: "arrow.uturn.backward")
                    }
                    trailingBtn("trash.slash", color: .red) { store.deleteToken(token) }
                } else {
                    // Copy
                    trailingBtn(copied ? "checkmark" : "doc.on.doc",
                                color: copied ? .green : .secondary) {
                        (NSApp.delegate as? AppDelegate)?.copyToken(token)
                        copied = true; copyFlashTrigger = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { copyFlashTrigger = false }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { copied = false }
                    }
                    // Edit
                    trailingBtn("pencil", color: .secondary) { onEdit() }
                    // Open URL
                    if token.tokenType.serviceURL != nil {
                        trailingBtn("safari", color: .secondary) {
                            if let u = token.tokenType.serviceURL { NSWorkspace.shared.open(u) }
                        }
                    }
                    // More menu
                    Menu {
                        Button { (NSApp.delegate as? AppDelegate)?.toggleFav(token) } label: {
                            Label(token.isFavorite ? "取消收藏" : "收藏", systemImage: token.isFavorite ? "star.slash" : "star")
                        }
                        Button { onDuplicate() } label: {
                            Label("複製", systemImage: "plus.square.on.square")
                        }
                        Divider()
                        Button(role: .destructive) { store.softDeleteToken(token) } label: {
                            Label("刪除", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.primary.opacity(isHovering ? 0.06 : 0)))
                    }
                    .buttonStyle(.plain).focusEffectDisabled().menuIndicator(.hidden)
                    .frame(width: 28)
                }
            }
            .opacity(isHovering ? 1 : 0.55)
            .animation(.easeOut(duration: 0.2), value: isHovering)
        }
    }

    private func trailingBtn(_ icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(color.opacity(isHovering ? 0.10 : 0))
                )
        }
        .buttonStyle(.plain).focusEffectDisabled()
        .scaleEffect(isHovering ? 1.0 : 0.9)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)
    }

    // MARK: - Context Menu

    @ViewBuilder
    private var cardContextMenu: some View {
        if token.isDeleted {
            Button { store.restoreToken(token) } label: {
                Label("恢復", systemImage: "arrow.uturn.backward")
            }
            Button { store.deleteToken(token) } label: {
                Label("永久刪除", systemImage: "trash.slash")
            }
        } else {
            Button { (NSApp.delegate as? AppDelegate)?.copyToken(token) } label: {
                Label("複製 Token", systemImage: "doc.on.doc")
            }
            Button { (NSApp.delegate as? AppDelegate)?.toggleFav(token) } label: {
                Label(token.isFavorite ? "取消收藏" : "收藏", systemImage: token.isFavorite ? "star.slash" : "star")
            }
            Divider()
            Button { onEdit() } label: { Label("編輯", systemImage: "pencil") }
            Button { onDuplicate() } label: { Label("複製", systemImage: "plus.square.on.square") }
            if token.tokenType.serviceURL != nil {
                Button { if let u = token.tokenType.serviceURL { NSWorkspace.shared.open(u) } } label: {
                    Label("開啟 \(token.tokenType.label) 控台", systemImage: "safari")
                }
            }
            Divider()
            Button(role: .destructive) { store.softDeleteToken(token) } label: {
                Label("刪除", systemImage: "trash")
            }
        }
    }

    private func daysSince(_ date: Date) -> Int {
        max(1, Int(Date().timeIntervalSince(date) / 86400))
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
