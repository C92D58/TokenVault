import SwiftUI

struct AddTokenSheet: View {
    @ObservedObject var store: DataStore
    let editingToken: TokenItem?
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
                Text(editingToken != nil ? "編輯 Token" : "新增 Token")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Button("取消") { onDismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    FieldGroup(label: "名稱", icon: "tag") {
                        TextField("例如：GitHub Personal Token", text: $name)
                            .textFieldStyle(.plain)
                    }

                    FieldGroup(label: "Token 值", icon: "key") {
                        HStack {
                            SecureField("貼上你的 Token", text: $value)
                                .textFieldStyle(.plain)
                            if !value.isEmpty {
                                Button {
                                    ClipboardService.shared.copy(value)
                                } label: {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 12))
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.secondary)
                            }
                        }
                    }

                    FieldGroup(label: "備註", icon: "note.text") {
                        TextField("可選備註", text: $note)
                            .textFieldStyle(.plain)
                    }

                    if !store.groups.isEmpty {
                        FieldGroup(label: "分組", icon: "folder") {
                            Picker("", selection: $selectedGroup) {
                                Text("無分組").tag(nil as TokenGroup?)
                                ForEach(store.groups) { group in
                                    Text(group.name).tag(group as TokenGroup?)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: $hasExpiry) {
                            HStack(spacing: 6) {
                                Image(systemName: "clock").frame(width: 20)
                                Text("到期日")
                            }
                            .font(.system(size: 13))
                        }
                        .toggleStyle(.switch)

                        if hasExpiry {
                            DatePicker("", selection: $expiryDate, displayedComponents: .date)
                                .datePickerStyle(.field)
                                .labelsHidden()
                        }
                    }
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.05)))
                }
                .padding()
            }

            Divider()

            HStack {
                Spacer()
                Button("儲存") { saveToken() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return)
                    .disabled(name.isEmpty || value.isEmpty)
            }
            .padding()
        }
        .frame(width: 440, height: 400)
        .onAppear { loadEditingToken() }
    }

    private func loadEditingToken() {
        guard let token = editingToken else { return }
        name = token.name
        value = token.value
        note = token.note
        selectedGroup = store.groups.first { $0.id == token.groupID }
        if let exp = token.expiresAt {
            hasExpiry = true
            expiryDate = exp
        }
    }

    private func saveToken() {
        if let token = editingToken {
            token.name = name
            token.value = value
            token.note = note
            token.groupID = selectedGroup?.id
            token.expiresAt = hasExpiry ? expiryDate : nil
            // Move between groups if needed
            let oldGroup = store.groups.first { $0.tokens.contains { $0.id == token.id } }
            if oldGroup?.id != selectedGroup?.id {
                oldGroup?.tokens.removeAll { $0.id == token.id }
                selectedGroup?.tokens.append(token)
            }
        } else {
            let token = TokenItem(
                name: name,
                value: value,
                note: note,
                expiresAt: hasExpiry ? expiryDate : nil,
                groupID: selectedGroup?.id
            )
            store.addToken(token, to: selectedGroup)
        }
        store.save()
        onDismiss()
    }
}

struct FieldGroup<Content: View>: View {
    let label: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon).frame(width: 20).foregroundColor(.secondary)
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            content()
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.06)))
        }
    }
}
