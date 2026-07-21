import SwiftUI

// MARK: - Main Window

struct MainView: View {
    @ObservedObject var store: DataStore
    @State private var searchText = ""
    @State private var selectedGroup: TokenGroup? = nil
    @State private var showAddToken = false
    @State private var showAddGroup = false
    @State private var editingToken: TokenItem? = nil

    @Environment(\.colorScheme) var colorScheme

    var tokens: [TokenItem] {
        store.search(searchText, in: selectedGroup)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerBar

            Divider()

            // Token list
            if tokens.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(tokens) { token in
                            TokenCard(token: token, store: store) {
                                editingToken = token
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .background(Color(.windowBackgroundColor))
        .sheet(isPresented: $showAddToken) {
            TokenEditor(store: store, token: editingToken) {
                showAddToken = false; editingToken = nil
            }
        }
        .sheet(isPresented: $showAddGroup) {
            GroupEditor(store: store) { showAddGroup = false }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAddToken)) { _ in
            editingToken = nil; showAddToken = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAddGroup)) { _ in
            showAddGroup = true
        }
        .onChange(of: editingToken) { if $0 != nil { showAddToken = true } }
    }

    private var headerBar: some View {
        VStack(spacing: 10) {
            // Title row
            HStack {
                Text("TokenVault")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                HStack(spacing: 12) {
                    Menu {
                        Button("所有 Token") { selectedGroup = nil }
                        Divider()
                        ForEach(store.groups) { group in
                            Button(group.name) { selectedGroup = group }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                                .font(.system(size: 11))
                            Text(selectedGroup?.name ?? "全部")
                                .font(.system(size: 12))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.primary.opacity(0.08)))
                    }
                    .buttonStyle(.plain)

                    Button { showAddGroup = true } label: {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)

                    Button {
                        editingToken = nil; showAddToken = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                TextField("搜尋 Token...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(9)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.06)))
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "key.horizontal")
                .font(.system(size: 40))
                .foregroundColor(.secondary.opacity(0.3))
            Text("尚無 Token")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            Button("新增 Token") { editingToken = nil; showAddToken = true }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            Spacer()
        }
    }
}

// MARK: - Token Card

struct TokenCard: View {
    @ObservedObject var token: TokenItem
    @ObservedObject var store: DataStore
    let onEdit: () -> Void

    @State private var showValue = false
    @State private var copied = false
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Main row
            Button {
                withAnimation(.spring(response: 0.3)) { expanded.toggle() }
            } label: {
                HStack(spacing: 12) {
                    // Icon
                    Image(systemName: token.isFavorite ? "star.fill" : "key.fill")
                        .font(.system(size: 14))
                        .foregroundColor(token.isFavorite ? .orange : .accentColor)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(token.isFavorite ? Color.orange.opacity(0.12) : Color.accentColor.opacity(0.1))
                        )

                    // Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(token.name)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        Text(token.maskedValue)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Badges
                    if token.isExpired {
                        Badge(text: "過期", color: .red)
                    } else if token.expiresSoon {
                        Badge(text: "即將過期", color: .orange)
                    }

                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            // Expanded detail
            if expanded {
                Divider()
                    .padding(.horizontal, 14)

                VStack(spacing: 10) {
                    // Token value
                    HStack {
                        if showValue {
                            Text(token.value)
                                .font(.system(size: 11, design: .monospaced))
                                .textSelection(.enabled)
                                .foregroundColor(.primary)
                        } else {
                            Text(token.maskedValue)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Button { showValue.toggle() } label: {
                            Image(systemName: showValue ? "eye.slash" : "eye")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                    }

                    // Actions
                    HStack(spacing: 8) {
                        // Copy button
                        Button {
                            ClipboardService.shared.copy(token.value)
                            token.copyCount += 1
                            store.save()
                            withAnimation(.spring(response: 0.3)) { copied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation { copied = false }
                            }
                        } label: {
                            Label(copied ? "已複製" : "複製", systemImage: copied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 11, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(copied ? Color.green.opacity(0.12) : Color.accentColor.opacity(0.1)))
                                .foregroundColor(copied ? .green : .accentColor)
                        }
                        .buttonStyle(.plain)

                        // Favorite
                        Button {
                            store.toggleFavorite(token); store.save()
                        } label: {
                            Image(systemName: token.isFavorite ? "star.fill" : "star")
                                .font(.system(size: 12))
                                .foregroundColor(token.isFavorite ? .orange : .secondary)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(Color.primary.opacity(0.06)))
                        }
                        .buttonStyle(.plain)

                        // Edit
                        Button { onEdit() } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(Color.primary.opacity(0.06)))
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        // Delete
                        Button {
                            store.deleteToken(token)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(Color.primary.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                    }

                    // Meta info
                    if token.copyCount > 0 || token.expiresAt != nil || !token.note.isEmpty {
                        HStack(spacing: 16) {
                            if token.copyCount > 0 {
                                Label("\(token.copyCount)", systemImage: "arrow.triangle.capsulepath")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            if let exp = token.expiresAt {
                                Label(exp.formatted(date: .abbreviated, time: .omitted), systemImage: "clock")
                                    .font(.system(size: 10))
                                    .foregroundColor(token.isExpired ? .red : (token.expiresSoon ? .orange : .secondary))
                            }
                            Spacer()
                        }
                    }

                    if !token.note.isEmpty {
                        Text(token.note)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.primary.opacity(0.03))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.06), lineWidth: 1))
        )
    }
}

struct Badge: View {
    let text: String
    let color: Color
    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Capsule().fill(color.opacity(0.12)))
    }
}
