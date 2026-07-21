import SwiftUI

struct ContentView: View {
    @ObservedObject var store: DataStore
    @State private var selectedGroup: TokenGroup? = nil
    @State private var selectedToken: TokenItem? = nil
    @State private var showAddGroup = false

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
        } content: {
            TokenListView(store: store, group: selectedGroup, selectedToken: $selectedToken)
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
        } detail: {
            TokenDetailView(store: store, token: selectedToken)
                .frame(minWidth: 320)
        }
        .sheet(isPresented: $showAddGroup) {
            AddGroupSheet(store: store, onDismiss: { showAddGroup = false })
        }
    }
}
