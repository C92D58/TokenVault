import SwiftUI

struct TokenEditor: View {
    @ObservedObject var store: DataStore
    let token: TokenItem?
    let onDismiss: () -> Void

    @State private var name = ""
    @State private var value = ""
    @State private var note = ""
    @State private var hasExpiry = false
    @State private var expiryDate = Date().addingTimeInterval(86400 * 30)
    @State private var selectedGroup: TokenGroup?

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(token != nil ? "編輯 Token" : "新增 Token")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Button("取消") { onDismiss() }.keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Field(label: "名稱", icon: "tag") {
                        TextField("例如：GitHub Token", text: $name).textFieldStyle(.plain)
                    }
                    Field(label: "Token 值", icon: "key") {
                        SecureField("貼上 Token", text: $value).textFieldStyle(.plain)
                    }
                    Field(label: "備註", icon: "note.text") {
                        TextField("可選", text: $note).textFieldStyle(.plain)
                    }
                    if !store.groups.isEmpty {
                        Field(label: "分組", icon: "folder") {
                            Picker("", selection: $selectedGroup) {
                                Text("無").tag(nil as TokenGroup?)
                                ForEach(store.groups) { Text($0.name).tag($0 as TokenGroup?) }
                            }.pickerStyle(.menu).labelsHidden()
                        }
                    }
                    Toggle(isOn: $hasExpiry) {
                        Label("到期日", systemImage: "clock").font(.system(size: 13))
                    }
                    if hasExpiry {
                        DatePicker("", selection: $expiryDate, displayedComponents: .date)
                            .datePickerStyle(.field).labelsHidden()
                    }
                }
                .padding()
            }

            Divider()
            HStack {
                Spacer()
                Button("儲存") { save() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return)
                    .disabled(name.isEmpty || value.isEmpty)
            }
            .padding()
        }
        .frame(width: 400, height: 360)
        .onAppear { if let t = token { name = t.name; value = t.value; note = t.note; selectedGroup = store.groups.first { $0.id == t.groupID }; if let e = t.expiresAt { hasExpiry = true; expiryDate = e } } }
    }

    private func save() {
        if let t = token {
            let old = store.groups.first { $0.tokens.contains { $0.id == t.id } }
            old?.tokens.removeAll { $0.id == t.id }
            t.name = name; t.value = value; t.note = note; t.groupID = selectedGroup?.id; t.expiresAt = hasExpiry ? expiryDate : nil
            selectedGroup?.tokens.append(t)
        } else {
            store.addToken(TokenItem(name: name, value: value, note: note, expiresAt: hasExpiry ? expiryDate : nil, groupID: selectedGroup?.id), to: selectedGroup)
        }
        store.save(); onDismiss()
    }
}

struct GroupEditor: View {
    @ObservedObject var store: DataStore
    let onDismiss: () -> Void
    @State private var name = ""

    var body: some View {
        VStack(spacing: 16) {
            Text("新增分組").font(.system(size: 15, weight: .bold))
            TextField("名稱", text: $name).textFieldStyle(.roundedBorder).frame(width: 180)
            HStack {
                Button("取消") { onDismiss() }
                Button("新增") { store.addGroup(name); onDismiss() }
                    .buttonStyle(.borderedProminent).disabled(name.isEmpty).keyboardShortcut(.return)
            }
        }.padding().frame(width: 260, height: 140)
    }
}

struct Field<Content: View>: View {
    let label: String; let icon: String
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon).font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary).labelStyle(.titleAndIcon)
            content().padding(10).background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.05)))
        }
    }
}
