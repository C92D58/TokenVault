import SwiftUI

struct ContentView: View {
    @ObservedObject var store: DataStore
    @State private var selectedGroup: TokenGroup? = nil
    @State private var selectedToken: TokenItem? = nil
    @State private var showAddGroup = false
    @State private var showAddToken = false

    var body: some View {
        NavigationSplitView {
            SidebarView(store: store, selectedGroup: $selectedGroup, selectedToken: $selectedToken)
                .navigationSplitViewColumnWidth(min: 180, ideal: 200, max: 260)
                .toolbar {
                    ToolbarItem {
                        Button { showAddGroup = true } label: {
                            Image(systemName: "folder.badge.plus")
                        }
                    }
                }
                .background(Color(red: 0.08, green: 0.08, blue: 0.10))
        } content: {
            TokenListView(store: store, group: selectedGroup, selectedToken: $selectedToken)
                .navigationSplitViewColumnWidth(min: 280, ideal: 340, max: 420)
                .background(Color(red: 0.07, green: 0.07, blue: 0.09))
        } detail: {
            TokenDetailView(store: store, token: selectedToken)
                .frame(minWidth: 340)
                .background(Color(red: 0.06, green: 0.06, blue: 0.08))
        }
        .sheet(isPresented: $showAddGroup) {
            AddGroupSheet(store: store, onDismiss: { showAddGroup = false })
        }
        .sheet(isPresented: $showAddToken) {
            AddTokenSheet(store: store, editingToken: nil) { showAddToken = false }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAddToken)) { _ in
            showAddToken = true
        }
        .onReceive(NotificationCenter.default.publisher(for: .showAddGroup)) { _ in
            showAddGroup = true
        }
        .background(Color(red: 0.07, green: 0.07, blue: 0.09))
    }
}
