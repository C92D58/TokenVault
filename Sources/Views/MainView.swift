import SwiftUI

enum D { // Design tokens
    static let rSm: CGFloat = 8; static let rMd: CGFloat = 12
    static let sSm: CGFloat = 8; static let sMd: CGFloat = 12; static let sLg: CGFloat = 16; static let sXl: CGFloat = 24
}

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

    private var header: some View {
        VStack(spacing: D.sSm) {
            HStack {
                Text("TokenVault").font(.system(size: 16, weight: .bold))
                Spacer()
                HStack(spacing: D.sMd) {
                    Menu {
                        Button("所有 Token") { selectedGroup = nil }
                        if !store.groups.isEmpty { Divider() }
                        ForEach(store.groups) { g in Button(g.name) { selectedGroup = g } }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "folder").font(.system(size: 11))
                            Text(selectedGroup?.name ?? "全部").font(.system(size: 12))
                            Image(systemName: "chevron.down").font(.system(size: 8))
                        }.padding(.horizontal, 10).padding(.vertical, 5).background(Capsule().fill(.quaternary))
                    }.buttonStyle(.plain)

                    Button { showAddGroup = true } label: {
                        Image(systemName: "folder.badge.plus").font(.system(size: 14))
                    }.buttonStyle(.plain).foregroundColor(.secondary)

                    Button { editingToken = nil; showAddToken = true } label: {
                        Image(systemName: "plus.circle.fill").font(.system(size: 18))
                    }.buttonStyle(.plain)

                    Button {
                        (NSApp.delegate as? AppDelegate)?.showSettings()
                    } label: {
                        Image(systemName: "gearshape").font(.system(size: 14))
                    }.buttonStyle(.plain).foregroundColor(.secondary)
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary).font(.system(size: 12))
                TextField("搜尋...", text: $searchText).textFieldStyle(.plain).font(.system(size: 13))
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 11)).foregroundColor(.secondary)
                    }.buttonStyle(.plain)
                }
            }.padding(9).background(RoundedRectangle(cornerRadius: D.rSm).fill(.quaternary))
        }
        .padding(.horizontal, D.sXl).padding(.top, D.sXl).padding(.bottom, D.sMd)
    }

    private var tokenList: some View {
        ScrollView {
            LazyVStack(spacing: D.sSm) {
                ForEach(tokens) { token in
                    TokenCard(token: token, store: store) { editingToken = token }
                }
            }.padding(D.sXl)
        }
    }

    private var emptyState: some View {
        VStack(spacing: D.sLg) {
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

    var body: some View {
        VStack(spacing: 0) {
            Button { withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { expanded.toggle() } } label: { cardHeader }
                .buttonStyle(.plain)

            if expanded {
                Divider().padding(.horizontal, 14)
                cardDetail.transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(RoundedRectangle(cornerRadius: D.rMd).fill(.quaternary.opacity(0.5))
            .overlay(RoundedRectangle(cornerRadius: D.rMd).stroke(.quaternary, lineWidth: 1)))
    }

    private var cardHeader: some View {
        HStack(spacing: D.sMd) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(token.isFavorite ? Color.orange.opacity(0.12) : Color.accentColor.opacity(0.1))
                    .frame(width: 34, height: 34)
                Image(systemName: token.isFavorite ? "star.fill" : "key.fill")
                    .font(.system(size: 14)).foregroundColor(token.isFavorite ? .orange : .accentColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(token.name).font(.system(size: 13, weight: .medium)).lineLimit(1)
                Text(token.maskedValue).font(.system(size: 11, design: .monospaced)).foregroundColor(.secondary).lineLimit(1)
            }
            Spacer()
            if token.isExpired { badge("過期", .red) } else if token.expiresSoon { badge("即將過期", .orange) }
            Image(systemName: expanded ? "chevron.up" : "chevron.down").font(.system(size: 10)).foregroundColor(.secondary)
        }.padding(.horizontal, 14).padding(.vertical, 12)
    }

    private var cardDetail: some View {
        VStack(alignment: .leading, spacing: D.sSm) {
            HStack {
                if showValue {
                    Text(token.decryptedValue()).font(.system(size: 11, design: .monospaced)).textSelection(.enabled)
                } else {
                    Text(token.maskedValue).font(.system(size: 11, design: .monospaced)).foregroundColor(.secondary)
                }
                Spacer()
                Button { showValue.toggle() } label: {
                    Image(systemName: showValue ? "eye.slash" : "eye").font(.system(size: 11))
                }.buttonStyle(.plain).foregroundColor(.secondary)
            }

            HStack(spacing: 8) {
                Button {
                    ClipboardService.shared.copy(token.decryptedValue())
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
                        .frame(width: 28, height: 28).background(Circle().fill(.quaternary))
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
        }.padding(.horizontal, 16).padding(.vertical, 12)
    }

    private func badge(_ t: String, _ c: Color) -> some View {
        Text(t).font(.system(size: 9, weight: .bold)).foregroundColor(c)
            .padding(.horizontal, 6).padding(.vertical, 2).background(Capsule().fill(c.opacity(0.12)))
    }
}
