import SwiftUI

struct TokenEditor: View {
    @ObservedObject var store: DataStore
    let token: TokenItem?
    let isDuplicate: Bool
    let onDismiss: () -> Void

    @State private var name = ""
    @State private var value = ""
    @State private var note = ""
    @State private var environment: TokenEnvironment = .production
    @State private var tokenType: TokenType = .other
    @State private var hasExpiry = false
    @State private var expiryDate = Date().addingTimeInterval(86400 * 30)
    @State private var selectedGroup: TokenGroup?
    @State private var showValue = false
    @FocusState private var focusedField: Field?

    enum Field { case name, value, note }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isDuplicate ? "複製 Token" : (token != nil ? "編輯 Token" : "新增 Token"))
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                Button("取消") { onDismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 12)

            Divider()

            // Fields
            VStack(alignment: .leading, spacing: 14) {
                // Name
                fieldLabel("名稱", icon: "tag")
                TextField("例如：GitHub Personal Token", text: $name)
                    .textFieldStyle(.plain)
                    .focused($focusedField, equals: .name)
                    .padding(.horizontal, 10).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(.textBackgroundColor)))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.10), lineWidth: 1))

                // Environment + Type
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        fieldLabel("環境", icon: "square.3.layers.3d")
                        Picker("", selection: $environment) {
                            ForEach(TokenEnvironment.allCases, id: \.self) { env in
                                Text(env.rawValue).tag(env)
                            }
                        }
                        .pickerStyle(.menu).labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.textBackgroundColor)))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.10), lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        fieldLabel("類型", icon: "square.grid.2x2")
                        Picker("", selection: $tokenType) {
                            ForEach(TokenType.allCases, id: \.self) { type in
                                Text(type.label).tag(type)
                            }
                        }
                        .pickerStyle(.menu).labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 10).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.textBackgroundColor)))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.10), lineWidth: 1))
                    }
                }

                // Token value with show/hide
                fieldLabel("Token 值", icon: "key")
                HStack(spacing: 0) {
                    ZStack {
                        TextField("貼上 Token 值", text: $value)
                            .textFieldStyle(.plain)
                            .focused($focusedField, equals: .value)
                            .opacity(showValue ? 1 : 0)
                            .allowsHitTesting(showValue)
                        SecureField("貼上 Token 值", text: $value)
                            .textFieldStyle(.plain)
                            .focused($focusedField, equals: .value)
                            .opacity(showValue ? 0 : 1)
                            .allowsHitTesting(!showValue)
                    }
                    Button { showValue.toggle() } label: {
                        Image(systemName: showValue ? "eye.slash" : "eye")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                    .buttonStyle(.plain).focusEffectDisabled()
                    .frame(width: 26)
                }
                .padding(.horizontal, 10).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color(.textBackgroundColor)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.10), lineWidth: 1))

                // Note + Group
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        fieldLabel("備註", icon: "note.text")
                        TextField("可選", text: $note)
                            .textFieldStyle(.plain)
                            .focused($focusedField, equals: .note)
                            .padding(.horizontal, 10).padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.textBackgroundColor)))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.10), lineWidth: 1))
                    }

                    if !store.groups.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            fieldLabel("分組", icon: "folder")
                            Picker("", selection: $selectedGroup) {
                                Text("無").tag(nil as TokenGroup?)
                                ForEach(store.groups) { Text($0.name).tag($0 as TokenGroup?) }
                            }
                            .pickerStyle(.menu).labelsHidden()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 10).padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color(.textBackgroundColor)))
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.10), lineWidth: 1))
                        }
                    }
                }

                // Expiry
                HStack {
                    Toggle(isOn: $hasExpiry) {
                        Label("到期日", systemImage: "clock")
                            .font(.system(size: 12))
                    }
                    if hasExpiry {
                        DatePicker("", selection: $expiryDate, displayedComponents: .date)
                            .datePickerStyle(.field).labelsHidden()
                            .frame(width: 130)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 18)

            Divider()

            // Footer
            HStack {
                Spacer()
                Button("儲存") { save() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || value.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 20).padding(.vertical, 12)
        }
        .frame(width: 480, height: 420)
        .onAppear {
            load()
            focusedField = .name
        }
    }

    // MARK: - Helpers

    private func fieldLabel(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.system(size: 10.5, weight: .semibold))
            .foregroundColor(.secondary)
    }

    // MARK: - Load / Save

    private func load() {
        guard let t = token else {
            if let pb = NSPasteboard.general.string(forType: .string), !pb.isEmpty {
                tokenType = TokenType.detect(from: "", value: pb)
            }
            return
        }
        name = isDuplicate ? "\(t.name) 副本" : t.name
        value = t.decryptedValue()
        note = t.note
        environment = t.environment
        tokenType = t.tokenType
        selectedGroup = store.groups.first { $0.id == t.groupID }
        if let e = t.expiresAt { hasExpiry = true; expiryDate = e }
    }

    private func save() {
        if isDuplicate || token == nil {
            store.addToken(TokenItem(
                name: name.trimmingCharacters(in: .whitespaces),
                plainValue: value.trimmingCharacters(in: .whitespaces),
                note: note,
                environment: environment, tokenType: tokenType,
                expiresAt: hasExpiry ? expiryDate : nil,
                groupID: selectedGroup?.id
            ), to: selectedGroup)
        } else if let t = token {
            let oldGroup = store.groups.first { $0.tokens.contains { $0.id == t.id } }
            oldGroup?.tokens.removeAll { $0.id == t.id }
            t.name = name.trimmingCharacters(in: .whitespaces)
            t.note = note
            t.groupID = selectedGroup?.id
            t.environment = environment
            t.tokenType = tokenType
            t.expiresAt = hasExpiry ? expiryDate : nil
            let newValue = value.trimmingCharacters(in: .whitespaces)
            if newValue != t.decryptedValue() {
                t.encryptedValue = (try? EncryptionService.encrypt(newValue)) ?? newValue
            }
            if let g = selectedGroup { g.tokens.append(t) }
        }
        store.save()
        ToastService.shared.show(isDuplicate || token == nil ? "已新增「\(name)」" : "已儲存「\(name)」", icon: "checkmark.circle")
        onDismiss()
    }
}

// MARK: - Group Sheet

struct GroupSheet: View {
    @ObservedObject var store: DataStore
    let onDismiss: () -> Void
    @State private var name = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 18) {
            Text("新增分組")
                .font(.system(size: 15, weight: .bold))
            TextField("分組名稱", text: $name)
                .textFieldStyle(.roundedBorder)
                .frame(width: 200)
                .focused($isFocused)
            HStack(spacing: 10) {
                Button("取消") { onDismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("新增") { store.addGroup(name); onDismiss() }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .keyboardShortcut(.return)
            }
        }
        .padding()
        .frame(width: 280, height: 150)
        .onAppear { isFocused = true }
    }
}
