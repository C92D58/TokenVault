import SwiftUI

struct TokenEditor: View {
    @ObservedObject var store: DataStore
    let token: TokenItem?
    let onDismiss: () -> Void

    @State private var name = ""
    @State private var value = ""
    @State private var note = ""
    @State private var environment: TokenEnvironment = .production
    @State private var tokenType: TokenType = .other
    @State private var hasExpiry = false
    @State private var expiryDate = Date().addingTimeInterval(86400 * 30)
    @State private var selectedGroup: TokenGroup?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(token != nil ? "編輯 Token" : "新增 Token")
                    .font(.system(size: 14, weight: .bold))
                Spacer()
                Button("取消") { onDismiss() }
                    .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 12)

            Divider()

            // All fields — no scroll
            VStack(alignment: .leading, spacing: 10) {
                // Name
                fieldLabel("名稱", icon: "tag")
                TextField("例如：GitHub Personal Token", text: $name)
                    .textFieldStyle(.plain)
                    .padding(7)
                    .background(RoundedRectangle(cornerRadius: 7).fill(.quaternary))

                // Environment + Type side by side
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        fieldLabel("環境", icon: "square.3.layers.3d")
                        Picker("", selection: $environment) {
                            ForEach(TokenEnvironment.allCases, id: \.self) { env in
                                HStack(spacing: 4) {
                                    Circle().fill(env.color.bg.swiftUIColor).frame(width: 8, height: 8)
                                    Text(env.rawValue)
                                }.tag(env)
                            }
                        }
                        .pickerStyle(.menu).labelsHidden()
                        .frame(maxWidth: .infinity)
                        .padding(7)
                        .background(RoundedRectangle(cornerRadius: 7).fill(.quaternary))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        fieldLabel("類型", icon: "square.grid.2x2")
                        Picker("", selection: $tokenType) {
                            ForEach(TokenType.allCases, id: \.self) { type in
                                HStack(spacing: 4) {
                                    Image(systemName: type.icon).font(.system(size: 10))
                                    Text(type.label)
                                }.tag(type)
                            }
                        }
                        .pickerStyle(.menu).labelsHidden()
                        .frame(maxWidth: .infinity)
                        .padding(7)
                        .background(RoundedRectangle(cornerRadius: 7).fill(.quaternary))
                    }
                }

                // Token value
                fieldLabel("Token 值", icon: "key")
                SecureField("貼上 Token 值", text: $value)
                    .textFieldStyle(.plain)
                    .padding(7)
                    .background(RoundedRectangle(cornerRadius: 7).fill(.quaternary))

                // Note + Group side by side
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        fieldLabel("備註", icon: "note.text")
                        TextField("可選", text: $note)
                            .textFieldStyle(.plain)
                            .padding(7)
                            .background(RoundedRectangle(cornerRadius: 7).fill(.quaternary))
                    }

                    if !store.groups.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            fieldLabel("分組", icon: "folder")
                            Picker("", selection: $selectedGroup) {
                                Text("無").tag(nil as TokenGroup?)
                                ForEach(store.groups) { Text($0.name).tag($0 as TokenGroup?) }
                            }
                            .pickerStyle(.menu).labelsHidden()
                            .padding(7)
                            .background(RoundedRectangle(cornerRadius: 7).fill(.quaternary))
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
                            .datePickerStyle(.field)
                            .labelsHidden()
                            .frame(width: 130)
                    }
                    Spacer()
                }
            }
            .padding(.horizontal, 20).padding(.vertical, 14)

            Divider()

            // Footer
            HStack {
                Spacer()
                Button("儲存") { save() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return)
                    .disabled(name.isEmpty || value.isEmpty)
            }
            .padding(.horizontal, 20).padding(.vertical, 12)
        }
        .frame(width: 460, height: 370)
        .onAppear { load() }
    }

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
        name = t.name; value = t.decryptedValue(); note = t.note
        environment = t.environment; tokenType = t.tokenType
        selectedGroup = store.groups.first { $0.id == t.groupID }
        if let e = t.expiresAt { hasExpiry = true; expiryDate = e }
    }

    private func save() {
        if let t = token {
            let old = store.groups.first { $0.tokens.contains { $0.id == t.id } }
            old?.tokens.removeAll { $0.id == t.id }
            t.name = name; t.note = note; t.groupID = selectedGroup?.id
            t.environment = environment; t.tokenType = tokenType
            t.expiresAt = hasExpiry ? expiryDate : nil
            if value != t.decryptedValue() { t.encryptedValue = (try? EncryptionService.encrypt(value)) ?? value }
            selectedGroup?.tokens.append(t)
        } else {
            store.addToken(TokenItem(name: name, plainValue: value, note: note,
                environment: environment, tokenType: tokenType,
                expiresAt: hasExpiry ? expiryDate : nil, groupID: selectedGroup?.id), to: selectedGroup)
        }
        store.save(); onDismiss()
    }
}

struct GroupSheet: View {
    @ObservedObject var store: DataStore; let onDismiss: () -> Void
    @State private var name = ""
    var body: some View {
        VStack(spacing: 16) {
            Text("新增分組").font(.system(size: 15, weight: .bold))
            TextField("分組名稱", text: $name).textFieldStyle(.roundedBorder).frame(width: 180)
            HStack {
                Button("取消") { onDismiss() }
                Button("新增") { store.addGroup(name); onDismiss() }
                    .buttonStyle(.borderedProminent).disabled(name.isEmpty).keyboardShortcut(.return)
            }
        }.padding().frame(width: 260, height: 140)
    }
}

