import SwiftUI

struct MenuBarPopover: View {
    @ObservedObject var store: DataStore
    @State private var searchText = ""
    @State private var copiedID: UUID?

    var tokens: [TokenItem] {
        let sorted = store.allTokens.sorted { $0.copyCount > $1.copyCount }
        guard !searchText.isEmpty else { return Array(sorted.prefix(10)) }
        return sorted.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Label("TokenVault", systemImage: "key.horizontal.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.accentColor)
                Spacer()
                Button {
                    if let d = NSApp.delegate as? AppDelegate { d.showMainWindow() }
                    NSApp.keyWindow?.performClose(nil)
                } label: {
                    Image(systemName: "rectangle.split.2x1").font(.system(size: 12))
                }.buttonStyle(.plain).foregroundColor(.secondary)
            }
            .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 6)

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundColor(.secondary).font(.system(size: 11))
                TextField("搜尋...", text: $searchText).textFieldStyle(.plain).font(.system(size: 12))
            }
            .padding(8).background(RoundedRectangle(cornerRadius: 7).fill(Color.primary.opacity(0.06)))
            .padding(.horizontal, 12).padding(.bottom, 6)

            Divider()

            if tokens.isEmpty {
                VStack { Spacer(); Text("無結果").font(.system(size: 12)).foregroundColor(.secondary); Spacer() }
            } else {
                ScrollView {
                    LazyVStack(spacing: 1) {
                        ForEach(tokens) { token in
                            Button {
                                ClipboardService.shared.copy(token.value)
                                token.copyCount += 1; store.save()
                                let id = token.id
                                withAnimation(.spring(response: 0.3)) { copiedID = id }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { if copiedID == id { withAnimation { copiedID = nil } } }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { NSApp.keyWindow?.performClose(nil) }
                            } label: {
                                HStack(spacing: 10) {
                                    Image(systemName: token.isFavorite ? "star.fill" : "key.fill")
                                        .font(.system(size: 10)).foregroundColor(token.isFavorite ? .orange : .secondary)
                                        .frame(width: 20, height: 20)
                                        .background(RoundedRectangle(cornerRadius: 5).fill(token.isFavorite ? Color.orange.opacity(0.12) : Color.primary.opacity(0.05)))
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(token.name).font(.system(size: 12, weight: .medium)).lineLimit(1)
                                        Text(token.maskedValue).font(.system(size: 10, design: .monospaced)).foregroundColor(.secondary).lineLimit(1)
                                    }
                                    Spacer()
                                    if copiedID == token.id {
                                        Image(systemName: "checkmark").font(.system(size: 10, weight: .bold)).foregroundColor(.green)
                                    }
                                }.padding(.horizontal, 14).padding(.vertical, 7).contentShape(Rectangle())
                            }.buttonStyle(.plain)
                        }
                    }
                }
            }

            Divider()
            HStack {
                Text("⌘⇧T 最近").font(.system(size: 10)).foregroundColor(.secondary.opacity(0.5))
                Spacer()
                Text("WAHSUN").font(.system(size: 9, weight: .medium)).foregroundColor(.secondary.opacity(0.3))
                Text("·").foregroundColor(.secondary.opacity(0.2))
                Text("\(store.allTokens.count)").font(.system(size: 10, design: .monospaced)).foregroundColor(.secondary.opacity(0.4))
            }
            .padding(.horizontal, 14).padding(.vertical, 8)
        }
        .frame(width: 340)
    }
}
