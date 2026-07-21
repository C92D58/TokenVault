import SwiftUI

// MARK: - Design Constants
enum Design {
    static let radiusSm: CGFloat = 8
    static let radiusMd: CGFloat = 12
    static let radiusLg: CGFloat = 16
    static let spacingXs: CGFloat = 4
    static let spacingSm: CGFloat = 8
    static let spacingMd: CGFloat = 12
    static let spacingLg: CGFloat = 16
    static let spacingXl: CGFloat = 24
}

// MARK: - Main Window

struct MainView: View {
    @ObservedObject var store: DataStore
    @State private var searchText = ""
    @State private var selectedGroup: TokenGroup? = nil
    @State private var showAddToken = false
    @State private var showAddGroup = false
    @State private var editingToken: TokenItem? = nil

    var tokens: [TokenItem] { store.search(searchText, in: selectedGroup) }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if tokens.isEmpty { emptyState } else { tokenList }
        }
        .background(Color(.controlBackgroundColor))
        .sheet(isPresented: $showAddToken) {
            TokenEditor(store: store, token: editingToken) { showAddToken = false; editingToken = nil }
        }
        .sheet(isPresented: $showAddGroup) {
            GroupSheet(store: store) { showAddGroup = false }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAddToken)) { _ in
            editingToken = nil; showAddToken = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAddGroup)) { _ in
            showAddGroup = true
        }
        .onChange(of: editingToken) { _, _ in
            if editingToken != nil { showAddToken = true }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: Design.spacingSm) {
            HStack {
                Text("TokenVault")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                HStack(spacing: Design.spacingMd) {
                    // Group filter
                    Menu {
                        Button("所有 Token") { selectedGroup = nil }
                        if !store.groups.isEmpty { Divider() }
                        ForEach(store.groups) { g in
                            Button(g.name) { selectedGroup = g }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "folder").font(.system(size: 11))
                            Text(selectedGroup?.name ?? "全部").font(.system(size: 12))
                            Image(systemName: "chevron.down").font(.system(size: 8))
                        }
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(Capsule().fill(.quaternary))
                    }
                    .buttonStyle(.plain)

                    Button { showAddGroup = true } label: {
                        Image(systemName: "folder.badge.plus").font(.system(size: 14))
                    }
                    .buttonStyle(.plain).foregroundColor(.secondary)

                    Button { editingToken = nil; showAddToken = true } label: {
                        Image(systemName: "plus.circle.fill").font(.system(size: 18))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary).font(.system(size: 12))
                TextField("搜尋...", text: $searchText).textFieldStyle(.plain).font(.system(size: 13))
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 11)).foregroundColor(.secondary)
                    }.buttonStyle(.plain)
                }
            }
            .padding(9)
            .background(RoundedRectangle(cornerRadius: Design.radiusSm).fill(.quaternary))
        }
        .padding(.horizontal, Design.spacingLg)
        .padding(.top, Design.spacingLg)
        .padding(.bottom, Design.spacingMd)
    }

    // MARK: - Token List

    private var tokenList: some View {
        ScrollView {
            LazyVStack(spacing: Design.spacingSm) {
                ForEach(tokens) { token in
                    TokenCard(token: token, store: store) { editingToken = token }
                }
            }
            .padding(Design.spacingLg)
        }
    }

    private var emptyState: some View {
        VStack(spacing: Design.spacingLg) {
            Spacer()
            Image(systemName: "key.horizontal").font(.system(size: 40)).foregroundColor(.secondary.opacity(0.3))
            Text(searchText.isEmpty ? "尚無 Token" : "無結果").font(.system(size: 14)).foregroundColor(.secondary)
            if searchText.isEmpty {
                Button("新增 Token") { editingToken = nil; showAddToken = true }
                    .buttonStyle(.borderedProminent).controlSize(.small)
            }
            Spacer()
        }
    }
}

// MARK: - Token Card

struct TokenCard: View {
    @ObservedObject var token: TokenItem
    @ObservedObject var store: DataStore
    let onEdit: () -> Void

    @State private var expanded = false
    @State private var showValue = false
    @State private var copied = false
    @Namespace private var ns

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { expanded.toggle() }
            } label: {
                cardHeader
            }
            .buttonStyle(.plain)

            if expanded {
                Divider().padding(.horizontal, 14)
                cardDetail
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: Design.radiusMd)
                .fill(.quaternary.opacity(0.5))
                .overlay(RoundedRectangle(cornerRadius: Design.radiusMd).stroke(.quaternary, lineWidth: 1))
        )
    }

    private var cardHeader: some View {
        HStack(spacing: Design.spacingMd) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(token.isFavorite ? Color.orange.opacity(0.12) : Color.accentColor.opacity(0.1))
                    .frame(width: 34, height: 34)
                Image(systemName: token.isFavorite ? "star.fill" : "key.fill")
                    .font(.system(size: 14))
                    .foregroundColor(token.isFavorite ? .orange : .accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(token.name)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                Text(token.maskedValue)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if token.isExpired {
                badge("過期", color: .red)
            } else if token.expiresSoon {
                badge("即將過期", color: .orange)
            }

            Image(systemName: expanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 10)).foregroundColor(.secondary)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
    }

    private var cardDetail: some View {
        VStack(alignment: .leading, spacing: Design.spacingSm) {
            // Value row
            HStack {
                if showValue {
                    Text(token.value)
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                } else {
                    Text(token.maskedValue)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button { showValue.toggle() } label: {
                    Image(systemName: showValue ? "eye.slash" : "eye").font(.system(size: 11))
                }.buttonStyle(.plain).foregroundColor(.secondary)
            }

            // Actions
            HStack(spacing: 8) {
                Button {
                    ClipboardService.shared.copy(token.value)
                    token.copyCount += 1; store.save()
                    withAnimation(.spring(response: 0.3)) { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { withAnimation { copied = false } }
                } label: {
                    Label(copied ? "已複製" : "複製", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 11, weight: .medium))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(copied ? Color.green.opacity(0.12) : Color.accentColor.opacity(0.1)))
                        .foregroundColor(copied ? .green : .accentColor)
                }.buttonStyle(.plain)

                Button { store.toggleFav(token); store.save() } label: {
                    Image(systemName: token.isFavorite ? "star.fill" : "star").font(.system(size: 12))
                        .foregroundColor(token.isFavorite ? .orange : .secondary)
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(.quaternary))
                }.buttonStyle(.plain)

                Button { onEdit() } label: {
                    Image(systemName: "pencil").font(.system(size: 11)).foregroundColor(.secondary)
                        .frame(width: 28, height: 28).background(Circle().fill(.quaternary))
                }.buttonStyle(.plain)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3)) { expanded = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { store.deleteToken(token) }
                } label: {
                    Image(systemName: "trash").font(.system(size: 11)).foregroundColor(.secondary)
                        .frame(width: 28, height: 28).background(Circle().fill(.quaternary))
                }.buttonStyle(.plain)
            }

            // Meta
            if token.copyCount > 0 || token.expiresAt != nil {
                HStack(spacing: 16) {
                    if token.copyCount > 0 {
                        Label("\(token.copyCount)", systemImage: "arrow.triangle.capsulepath")
                            .font(.system(size: 10)).foregroundColor(.secondary)
                    }
                    if let e = token.expiresAt {
                        Label(e.formatted(date: .abbreviated, time: .omitted), systemImage: "clock")
                            .font(.system(size: 10))
                            .foregroundColor(token.isExpired ? .red : token.expiresSoon ? .orange : .secondary)
                    }
                    Spacer()
                }
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private func badge(_ text: String, color: Color) -> some View {
        Text(text).font(.system(size: 9, weight: .bold)).foregroundColor(color)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.12)))
    }
}
