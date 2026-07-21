import SwiftUI

struct TokenListView: View {
    @ObservedObject var store: DataStore
    let group: TokenGroup?
    @Binding var selectedToken: TokenItem?
    @State private var searchText = ""
    @State private var showAddSheet = false

    var tokens: [TokenItem] {
        store.searchTokens(searchText, in: group)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                TextField("搜尋...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.05)))
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 8)

            if tokens.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "key.horizontal")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text("沒有 Token")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                    Button("新增 Token") { showAddSheet = true }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(tokens) { token in
                            TokenRowView(
                                item: token,
                                isSelected: selectedToken?.id == token.id,
                                onCopy: {
                                    ClipboardService.shared.copy(token.value)
                                    token.copyCount += 1
                                    store.save()
                                }
                            )
                            .onTapGesture { selectedToken = token }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 12)
                }
            }
        }
        .toolbar {
            ToolbarItem {
                Button { showAddSheet = true } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddSheet) {
            AddTokenSheet(store: store, editingToken: nil) { showAddSheet = false }
        }
    }
}
