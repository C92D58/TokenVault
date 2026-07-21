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
            HStack {
                Text(token != nil ? "編輯 Token" : "新增 Token").font(.system(size: 15, weight: .bold))
                Spacer()
                Button("取消") { onDismiss() }.keyboardShortcut(.cancelAction)
            }.padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    nameField

                    // Environment + Type row
                    HStack(spacing: 10) {
                        envPicker
                        typePicker
                    }

                    valueField
                    noteField

                    if !store.groups.isEmpty {
                        groupPicker
                    }

                    expiryToggle
                }.padding()
            }

            Divider()
            HStack {
                Spacer()
                Button("儲存") { save() }.buttonStyle(.borderedProminent).keyboardShortcut(.return)
                    .disabled(name.isEmpty || value.isEmpty)
            }.padding()
        }
        .frame(width: 440, height: 400)
        .onAppear { load() }
    }

    // MARK: - Fields

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("名稱", systemImage: "tag").font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
            TextField("例如：GitHub Personal Token", text: $name).textFieldStyle(.plain)
                .padding(9).background(RoundedRectangle(cornerRadius: 8).fill(.quaternary))
        }
    }

    private var envPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("環境", systemImage: "square.3.layers.3d").font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
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
            .padding(9).background(RoundedRectangle(cornerRadius: 8).fill(.quaternary))
        }
    }

    private var typePicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("類型", systemImage: "square.grid.2x2").font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
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
            .padding(9).background(RoundedRectangle(cornerRadius: 8).fill(.quaternary))
        }
    }

    private var valueField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Token 值", systemImage: "key").font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
            SecureField("貼上 Token 值", text: $value).textFieldStyle(.plain)
                .padding(9).background(RoundedRectangle(cornerRadius: 8).fill(.quaternary))
        }
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("備註", systemImage: "note.text").font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
            TextField("可選", text: $note).textFieldStyle(.plain)
                .padding(9).background(RoundedRectangle(cornerRadius: 8).fill(.quaternary))
        }
    }

    private var groupPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("分組", systemImage: "folder").font(.system(size: 11, weight: .semibold)).foregroundColor(.secondary)
            Picker("", selection: $selectedGroup) {
                Text("無分組").tag(nil as TokenGroup?)
                ForEach(store.groups) { Text($0.name).tag($0 as TokenGroup?) }
            }.pickerStyle(.menu).labelsHidden()
                .padding(9).background(RoundedRectangle(cornerRadius: 8).fill(.quaternary))
        }
    }

    private var expiryToggle: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle(isOn: $hasExpiry) {
                Label("到期日", systemImage: "clock").font(.system(size: 13))
            }
            if hasExpiry {
                DatePicker("", selection: $expiryDate, displayedComponents: .date).datePickerStyle(.field).labelsHidden()
            }
        }
    }

    // MARK: - Load / Save

    private func load() {
        guard let t = token else {
            // Pre-detect type from clipboard if pasting
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

