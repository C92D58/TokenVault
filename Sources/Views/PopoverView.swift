import SwiftUI

struct PopoverView: View {
    @ObservedObject var store: DataStore
    @State private var searchText = ""
    @State private var copiedID: UUID?
    @State private var hoveredID: UUID?

    private let accentGradient = LinearGradient(
        colors: [Color(red: 0.65, green: 0.55, blue: 0.98), Color(red: 0.45, green: 0.35, blue: 0.85)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    var tokens: [TokenItem] {
        let sorted = store.allTokens.sorted { $0.copyCount > $1.copyCount }
        guard !searchText.isEmpty else { return Array(sorted.prefix(10)) }
        return sorted.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 7) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(accentGradient).frame(width: 22, height: 22)
                        Image(systemName: "key.horizontal.fill")
                            .font(.system(size: 10, weight: .bold)).foregroundColor(.white)
                    }
                    Text("TokenVault")
                        .font(.system(size: 13, weight: .bold)).tracking(-0.3)
                }
                Spacer()
                Button { (NSApp.delegate as? AppDelegate)?.showMainWindow(); NSApp.keyWindow?.performClose(nil) } label: {
                    Image(systemName: "rectangle.split.2x1").font(.system(size: 12))
                        .foregroundColor(.secondary).frame(width: 24, height: 24)
                        .background(Circle().fill(.black.opacity(0.04)))
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 8)

            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary.opacity(0.5)).font(.system(size: 11))
                TextField("搜尋...", text: $searchText).textFieldStyle(.plain).font(.system(size: 12))
            }
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(.bar)
            .overlay(RoundedRectangle(cornerRadius: 7).stroke(.white.opacity(0.06), lineWidth: 1))
            .cornerRadius(7)
            .padding(.horizontal, 12).padding(.bottom, 8)

            Divider().opacity(0.3)

            if tokens.isEmpty {
                VStack { Spacer()
                    Text(searchText.isEmpty ? "尚無 Token" : "無匹配").font(.system(size: 12)).foregroundColor(.secondary)
                    Spacer() }
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(tokens) { token in
                            Button {
                                ClipboardService.shared.copy(token.decryptedValue())
                                token.copyCount += 1; store.save()
                                let id = token.id
                                withAnimation(.spring(response: 0.3)) { copiedID = id }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { if copiedID == id { withAnimation { copiedID = nil } } }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { NSApp.keyWindow?.performClose(nil) }
                            } label: {
                                popoverRow(token)
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }

            Divider().opacity(0.3)

            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "command").font(.system(size: 9))
                    Image(systemName: "shift").font(.system(size: 9))
                    Text("T").font(.system(size: 9, weight: .bold, design: .monospaced))
                    Text("貼上").font(.system(size: 10))
                }
                .foregroundColor(.secondary.opacity(0.4))
                Spacer()
                Text("\(store.allTokens.count)").font(.system(size: 10, design: .monospaced)).foregroundColor(.secondary.opacity(0.35))
                Text("·").foregroundColor(.secondary.opacity(0.15))
                Text("🔒").font(.system(size: 8)).opacity(0.3)
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
        }
        .frame(width: 340)
        .background(Color(.controlBackgroundColor))
    }

    private func popoverRow(_ token: TokenItem) -> some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(token.isFavorite ? AnyShapeStyle(Color.orange.opacity(0.12)) : AnyShapeStyle(accentGradient.opacity(0.1)))
                    .frame(width: 24, height: 24)
                Image(systemName: token.isFavorite ? "star.fill" : "key.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(token.isFavorite ? AnyShapeStyle(Color.orange) : AnyShapeStyle(accentGradient))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(token.name).font(.system(size: 12, weight: .medium)).tracking(-0.2).lineLimit(1)
                Text(token.maskedValue).font(.system(size: 10, design: .monospaced)).foregroundColor(.secondary).lineLimit(1)
            }
            Spacer()
            if copiedID == token.id {
                Image(systemName: "checkmark").font(.system(size: 11, weight: .bold))
                    .foregroundColor(.green).transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(hoveredID == token.id ? Color.primary.opacity(0.04) : Color.clear)
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.15)) { hoveredID = hovering ? token.id : nil }
        }
    }
}

// Keep old PopoverRow for backward compat (unused now)
struct PopoverRow: View {
    @ObservedObject var token: TokenItem; let isCopied: Bool
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: token.isFavorite ? "star.fill" : "key.fill")
                .font(.system(size: 10)).foregroundColor(token.isFavorite ? .orange : .secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(token.name).font(.system(size: 12, weight: .medium)).lineLimit(1)
                Text(token.maskedValue).font(.system(size: 10, design: .monospaced)).foregroundColor(.secondary).lineLimit(1)
            }
            Spacer()
            if isCopied { Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(.green) }
        }.padding(.horizontal, 14).padding(.vertical, 7).contentShape(Rectangle())
    }
}
