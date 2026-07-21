import SwiftUI

struct SidebarView: View {
    @ObservedObject var store: DataStore
    @Binding var selectedGroup: TokenGroup?
    @Binding var selectedToken: TokenItem?
    @State private var showAddGroup = false
    @State private var searchText = ""

    var body: some View {
        List(selection: $selectedGroup) {
            Label {
                HStack {
                    Text("所有 Token")
                    Spacer()
                    Text("\(store.allTokens.count)")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            } icon: {
                Image(systemName: "tray.full.fill").foregroundColor(.accentColor)
            }
            .tag(nil as TokenGroup?)
            .listRowSeparator(.hidden)

            Section {
                ForEach(store.groups) { group in
                    HStack {
                        Image(systemName: group.icon)
                            .foregroundColor(.accentColor)
                            .frame(width: 16)
                        Text(group.name)
                        Spacer()
                        Text("\(group.tokens.count)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .tag(group as TokenGroup?)
                }
            } header: {
                HStack {
                    Text("分組")
                    Spacer()
                    Button {
                        showAddGroup = true
                    } label: {
                        Image(systemName: "plus").font(.system(size: 10, weight: .bold))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.sidebar)
        .sheet(isPresented: $showAddGroup) {
            AddGroupSheet(store: store, onDismiss: { showAddGroup = false })
        }
    }
}

struct AddGroupSheet: View {
    @ObservedObject var store: DataStore
    let onDismiss: () -> Void
    @State private var name = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("新增分組")
                .font(.system(size: 15, weight: .bold))
            TextField("分組名稱", text: $name)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
            HStack {
                Button("取消") { onDismiss() }
                Button("新增") {
                    store.addGroup(name)
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
                .keyboardShortcut(.return)
            }
        }
        .padding()
        .frame(width: 280, height: 150)
    }
}
