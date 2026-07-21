import SwiftUI

// MARK: - Design System

private enum D {
    static let rSm: CGFloat = 10; static let rMd: CGFloat = 14; static let rLg: CGFloat = 20
    static let sXs: CGFloat = 6; static let sSm: CGFloat = 10; static let sMd: CGFloat = 14
    static let sLg: CGFloat = 20; static let sXl: CGFloat = 28

    // Brand gradient
    static let accentGradient = LinearGradient(
        colors: [Color(red: 0.65, green: 0.55, blue: 0.98), Color(red: 0.45, green: 0.35, blue: 0.85)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let iconGradient = LinearGradient(
        colors: [Color(red: 0.70, green: 0.60, blue: 0.98), Color(red: 0.50, green: 0.40, blue: 0.88)],
        startPoint: .top, endPoint: .bottom
    )
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
            if tokens.isEmpty { emptyState } else { tokenList }
        }
        .background(backgroundLayer)
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

    private var backgroundLayer: some View {
        ZStack {
            Color(.controlBackgroundColor)
            // Subtle gradient overlay
            LinearGradient(
                colors: [Color.accentColor.opacity(0.03), Color.clear, Color.accentColor.opacity(0.02)],
                startPoint: .top, endPoint: .bottom
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: D.sSm) {
            HStack {
                HStack(spacing: 8) {
                    // Brand mark
                    ZStack {
                        RoundedRectangle(cornerRadius: 7)
                            .fill(D.iconGradient)
                            .frame(width: 28, height: 28)
                        Image(systemName: "key.horizontal.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text("TokenVault")
                        .font(.system(size: 17, weight: .bold))
                        .tracking(-0.3)
                }
                Spacer()
                HStack(spacing: D.sSm) {
                    Menu {
                        Button("所有 Token") { selectedGroup = nil }
                        if !store.groups.isEmpty { Divider() }
                        ForEach(store.groups) { g in Button(g.name) { selectedGroup = g } }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "folder").font(.system(size: 11))
                            Text(selectedGroup?.name ?? "全部").font(.system(size: 12, weight: .medium))
                            Image(systemName: "chevron.down").font(.system(size: 7, weight: .bold))
                        }
                        .padding(.horizontal, 11).padding(.vertical, 6)
                        .background(Capsule().fill(.bar))
                        .overlay(Capsule().stroke(.white.opacity(0.08), lineWidth: 1))
                    }.buttonStyle(.plain)

                    Button { showAddGroup = true } label: {
                        Image(systemName: "folder.badge.plus").font(.system(size: 14))
                    }.buttonStyle(.plain).foregroundColor(.secondary)

                    Button { editingToken = nil; showAddToken = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(D.accentGradient)
                    }.buttonStyle(.plain)

                    Button { (NSApp.delegate as? AppDelegate)?.showSettings() } label: {
                        Image(systemName: "gearshape").font(.system(size: 14))
                    }.buttonStyle(.plain).foregroundColor(.secondary)
                }
            }

            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary.opacity(0.6)).font(.system(size: 13))
                TextField("搜尋 Token...", text: $searchText)
                    .textFieldStyle(.plain).font(.system(size: 13))
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.5))
                    }.buttonStyle(.plain).transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 9)
            .background(.bar)
            .overlay(RoundedRectangle(cornerRadius: D.rSm).stroke(.white.opacity(0.06), lineWidth: 1))
            .cornerRadius(D.rSm)
        }
        .padding(.horizontal, D.sXl).padding(.top, D.sLg).padding(.bottom, D.sMd)
    }

    // MARK: - List

    private var tokenList: some View {
        ScrollView {
            LazyVStack(spacing: D.sSm) {
                ForEach(tokens) { token in
                    TokenCard(token: token, store: store) { editingToken = token }
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .padding(.horizontal, D.sXl)
            .padding(.bottom, D.sXl)
        }
    }

    private var emptyState: some View {
        VStack(spacing: D.sLg) {
            Spacer()
            ZStack {
                Circle().fill(D.iconGradient.opacity(0.15)).frame(width: 88, height: 88)
                Image(systemName: "key.horizontal").font(.system(size: 36)).foregroundStyle(D.iconGradient)
            }
            VStack(spacing: 4) {
                Text(searchText.isEmpty ? "尚無 Token" : "無匹配結果")
                    .font(.system(size: 14, weight: .medium))
                Text(searchText.isEmpty ? "點擊 + 新增你的第一個 API 密鑰" : "嘗試其他關鍵字")
                    .font(.system(size: 12)).foregroundColor(.secondary)
            }
            if searchText.isEmpty {
                Button("新增 Token") { editingToken = nil; showAddToken = true }
                    .buttonStyle(.borderedProminent).controlSize(.small)
            }
            Spacer()
        }
    }
}

// MARK: - Refined Token Card

struct TokenCard: View {
    @ObservedObject var token: TokenItem
    @ObservedObject var store: DataStore
    let onEdit: () -> Void

    @State private var expanded = false
    @State private var showValue = false
    @State private var copied = false
    @State private var isHovering = false
    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) { expanded.toggle() }
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isPressed = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isPressed = false }
                }
            } label: { cardHeader }
                .buttonStyle(.plain)

            if expanded {
                Divider()
                    .opacity(0.3).padding(.horizontal, D.sMd)
                cardDetail.transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)).combined(with: .scale(scale: 0.98)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
        .background(cardBackground)
        .scaleEffect(isHovering ? 1.008 : 1.0)
        .scaleEffect(isPressed ? 0.985 : 1.0)
        .shadow(color: isHovering ? Color.accentColor.opacity(0.08) : Color.clear, radius: 12, y: 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.2)) { isHovering = hovering }
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: D.rMd)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: D.rMd)
                    .stroke(LinearGradient(
                        colors: [.white.opacity(isHovering ? 0.12 : 0.06), .white.opacity(0.03)],
                        startPoint: .top, endPoint: .bottom
                    ), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 2, y: 1)
            .shadow(color: .black.opacity(0.03), radius: 8, y: 3)
    }

    // MARK: - Header

    private var cardHeader: some View {
        HStack(spacing: D.sMd) {
            // Gradient icon
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(token.isFavorite ? AnyShapeStyle(Color.orange.opacity(0.15)) : AnyShapeStyle(D.iconGradient.opacity(0.12)))
                    .frame(width: 36, height: 36)
                Image(systemName: token.isFavorite ? "star.fill" : "key.fill")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(token.isFavorite ? AnyShapeStyle(Color.orange) : AnyShapeStyle(D.iconGradient))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(token.name)
                    .font(.system(size: 13.5, weight: .semibold))
                    .tracking(-0.2).lineLimit(1)
                Text(token.maskedValue)
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundColor(.secondary).lineLimit(1)
            }

            Spacer()

            // Status badges
            if token.isExpired {
                pillBadge("過期", color: .red)
            } else if token.expiresSoon {
                pillBadge("即將過期", color: .orange)
            }

            // Favorite indicator
            if token.isFavorite {
                Image(systemName: "star.fill")
                    .font(.system(size: 10)).foregroundColor(.orange)
            }

            Image(systemName: expanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 10, weight: .medium)).foregroundColor(.secondary.opacity(0.6))
                .rotationEffect(.degrees(expanded ? 0 : 0))
        }
        .padding(.horizontal, D.sMd).padding(.vertical, 13)
    }

    // MARK: - Detail

    private var cardDetail: some View {
        VStack(alignment: .leading, spacing: D.sSm) {
            // Value display
            HStack {
                if showValue {
                    Text(token.decryptedValue())
                        .font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(.horizontal, 10).padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 7).fill(.black.opacity(0.06)))
                } else {
                    Text(token.maskedValue)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10).padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 7).fill(.black.opacity(0.03)))
                }
                Spacer()
                Button { withAnimation(.easeOut(duration: 0.15)) { showValue.toggle() } } label: {
                    Image(systemName: showValue ? "eye.slash" : "eye")
                        .font(.system(size: 11)).foregroundColor(.secondary)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(.black.opacity(0.04)))
                }.buttonStyle(.plain)
            }

            // Action buttons
            HStack(spacing: 8) {
                // Copy button - gradient
                Button {
                    ClipboardService.shared.copy(token.decryptedValue())
                    token.copyCount += 1; store.save()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { copied = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { withAnimation { copied = false } }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 11, weight: .bold))
                        Text(copied ? "已複製" : "複製")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .padding(.horizontal, 14).padding(.vertical, 7)
                    .background(
                        Capsule().fill(copied ? AnyShapeStyle(Color.green.opacity(0.15)) : AnyShapeStyle(D.accentGradient.opacity(0.12)))
                    )
                    .overlay(Capsule().stroke(
                        copied ? Color.green.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1
                    ))
                    .foregroundColor(copied ? .green : Color(red: 0.65, green: 0.55, blue: 0.98))
                }.buttonStyle(.plain)

                Button { store.toggleFav(token); store.save() } label: {
                    Image(systemName: token.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 12))
                        .foregroundColor(token.isFavorite ? .orange : .secondary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(.black.opacity(0.03)))
                        .overlay(Circle().stroke(.white.opacity(0.06), lineWidth: 1))
                }.buttonStyle(.plain)

                Button { onEdit() } label: {
                    Image(systemName: "pencil").font(.system(size: 11)).foregroundColor(.secondary)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(.black.opacity(0.03)))
                        .overlay(Circle().stroke(.white.opacity(0.06), lineWidth: 1))
                }.buttonStyle(.plain)

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { expanded = false }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { store.deleteToken(token) }
                } label: {
                    Image(systemName: "trash").font(.system(size: 11)).foregroundColor(.secondary.opacity(0.6))
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(.black.opacity(0.03)))
                        .overlay(Circle().stroke(.white.opacity(0.06), lineWidth: 1))
                }.buttonStyle(.plain)
            }

            // Metadata footer
            if token.copyCount > 0 || token.expiresAt != nil || !token.note.isEmpty {
                HStack(spacing: 14) {
                    if token.copyCount > 0 {
                        Label("\(token.copyCount)", systemImage: "arrow.triangle.capsulepath")
                            .font(.system(size: 10)).foregroundColor(.secondary.opacity(0.7))
                    }
                    if let e = token.expiresAt {
                        Label(e.formatted(date: .abbreviated, time: .omitted), systemImage: "clock")
                            .font(.system(size: 10))
                            .foregroundColor(token.isExpired ? .red : token.expiresSoon ? .orange : .secondary.opacity(0.7))
                    }
                    Spacer()
                    if !token.note.isEmpty {
                        Text(token.note).font(.system(size: 10)).foregroundColor(.secondary.opacity(0.5)).lineLimit(1)
                    }
                }
            }
        }
        .padding(.horizontal, D.sMd).padding(.vertical, D.sMd)
    }

    private func pillBadge(_ text: String, color: Color) -> some View {
        HStack(spacing: 3) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text(text).font(.system(size: 9.5, weight: .semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(Capsule().fill(color.opacity(0.12)))
        .overlay(Capsule().stroke(color.opacity(0.2), lineWidth: 1))
    }
}
