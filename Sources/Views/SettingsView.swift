import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsService.shared
    @State private var showGHSetup = false
    @State private var ghToken = ""
    @State private var syncing = false
    @State private var syncMessage = ""

    var body: some View {
        TabView {
            generalTab.tabItem { Label("一般", systemImage: "gearshape") }
            syncTab.tabItem { Label("同步", systemImage: "arrow.triangle.capsulepath") }
            securityTab.tabItem { Label("安全", systemImage: "lock.shield") }
        }
        .frame(width: 420, height: 340)
    }

    // MARK: - General

    private var generalTab: some View {
        Form {
            Section {
                Picker("外觀", selection: $settings.appearanceMode) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: settings.appearanceMode) { _, _ in settings.applyAppearance() }
            } header: {
                Text("外觀").font(.system(size: 11, weight: .semibold))
            }

            Section {
                Toggle("自動鎖定", isOn: $settings.autoLockEnabled)
                if settings.autoLockEnabled {
                    Picker("閒置鎖定", selection: $settings.autoLockSeconds) {
                        Text("30 秒").tag(30)
                        Text("1 分鐘").tag(60)
                        Text("5 分鐘").tag(300)
                        Text("15 分鐘").tag(900)
                    }
                }
            } header: {
                Text("隱私").font(.system(size: 11, weight: .semibold))
            }

            Section {
                Picker("剪貼板清空", selection: $settings.clipboardClearSeconds) {
                    Text("15 秒").tag(15)
                    Text("30 秒").tag(30)
                    Text("45 秒").tag(45)
                    Text("永不").tag(0)
                }
            } header: {
                Text("剪貼板").font(.system(size: 11, weight: .semibold))
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Sync

    private var syncTab: some View {
        Form {
            Section {
                Toggle("iCloud 同步", isOn: $settings.useICloud)
                Text("開啟後數據自動同步到 iCloud Drive，所有 Apple 裝置共享。數據已 AES-256 加密。")
                    .font(.system(size: 10)).foregroundColor(.secondary)
            } header: {
                Text("iCloud").font(.system(size: 11, weight: .semibold))
            }

            Section {
                Toggle("GitHub 備份", isOn: $settings.githubSyncEnabled)
                if settings.githubSyncEnabled {
                    TextField("倉庫 (user/repo)", text: $settings.githubRepo)
                        .textFieldStyle(.roundedBorder).font(.system(size: 12))
                        .frame(width: 200)

                    HStack {
                        Button("設定 Token") { showGHSetup = true }
                            .buttonStyle(.bordered).controlSize(.small)
                        if !syncMessage.isEmpty {
                            Text(syncMessage)
                                .font(.system(size: 10)).foregroundColor(syncMessage.contains("✅") ? .green : .red)
                        }
                    }

                    Button {
                        syncToGitHub()
                    } label: {
                        Label(syncing ? "同步中..." : "立即同步", systemImage: "arrow.triangle.capsulepath")
                    }
                    .buttonStyle(.bordered).controlSize(.small)
                    .disabled(syncing || settings.githubRepo.isEmpty)

                    Text("Token 已 AES-256 加密，即使 GitHub 倉庫公開也無法被讀取。")
                        .font(.system(size: 10)).foregroundColor(.secondary)
                }
            } header: {
                Text("GitHub").font(.system(size: 11, weight: .semibold))
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showGHSetup) {
            VStack(spacing: 16) {
                Text("GitHub Token").font(.system(size: 15, weight: .bold))
                Text("需要 repo 寫入權限").font(.system(size: 11)).foregroundColor(.secondary)
                SecureField("ghp_...", text: $ghToken).textFieldStyle(.roundedBorder).frame(width: 260)
                HStack {
                    Button("取消") { showGHSetup = false }
                    Button("儲存") {
                        // Store GH token in Keychain
                        let tag = "org.wahsun.tokenvault.ghtoken".data(using: .utf8)!
                        try? KeychainService.write(tag: tag, data: Data(ghToken.utf8))
                        showGHSetup = false
                    }.buttonStyle(.borderedProminent).disabled(ghToken.isEmpty)
                }
            }.padding().frame(width: 320, height: 180)
        }
    }

    // MARK: - Security

    private var securityTab: some View {
        Form {
            Section {
                HStack {
                    Text("加密狀態")
                    Spacer()
                    Label("AES-256-GCM", systemImage: "checkmark.shield.fill")
                        .font(.system(size: 11)).foregroundColor(.green)
                }
                HStack {
                    Text("主密鑰")
                    Spacer()
                    Label("Secure Enclave", systemImage: "checkmark.shield.fill")
                        .font(.system(size: 11)).foregroundColor(.green)
                }
                HStack {
                    Text("儲存位置")
                    Spacer()
                    Text(settings.useICloud ? "iCloud Drive" : "本機")
                        .font(.system(size: 11)).foregroundColor(.secondary)
                }
            } header: {
                Text("安全資訊").font(.system(size: 11, weight: .semibold))
            }

            Section {
                Button("匯出加密備份") { exportBackup() }
                    .buttonStyle(.bordered).controlSize(.small)
                Button("匯入備份") { importBackup() }
                    .buttonStyle(.bordered).controlSize(.small)
            } header: {
                Text("備份").font(.system(size: 11, weight: .semibold))
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Actions

    private func syncToGitHub() {
        syncing = true; syncMessage = ""
        let repo = settings.githubRepo.trimmingCharacters(in: .whitespaces)
        guard !repo.isEmpty else { syncMessage = "請輸入倉庫"; syncing = false; return }

        Task.detached {
            let tag = "org.wahsun.tokenvault.ghtoken".data(using: .utf8)!
            guard let ghData = try? KeychainService.read(tag: tag),
                  let ghToken = String(data: ghData, encoding: .utf8) else {
                await MainActor.run { syncMessage = "請先設定 GitHub Token"; syncing = false }
                return
            }

            guard let d = await MainActor.run(body: { NSApp.delegate as? AppDelegate }) else { return }
            let snap = DataStore.BackupSnapshot(groups: d.store.groups, tokens: d.store.allTokens)
            let content = (try? JSONEncoder().encode(snap))?.base64EncodedString() ?? ""

            let url = URL(string: "https://api.github.com/repos/\(repo)/contents/tokenvault-backup.json")!
            var req = URLRequest(url: url)
            req.httpMethod = "PUT"
            req.setValue("Bearer \(ghToken)", forHTTPHeaderField: "Authorization")
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.setValue("TokenVault", forHTTPHeaderField: "User-Agent")
            req.httpBody = try? JSONSerialization.data(withJSONObject: [
                "message": "TokenVault 備份 \(Date().formatted(date: .abbreviated, time: .shortened))",
                "content": content
            ])

            do {
                let (data, _) = try await URLSession.shared.data(for: req)
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                let ok = json?["content"] != nil || json?["commit"] != nil
                await MainActor.run { syncMessage = ok ? "✅ 同步完成" : "❌ 同步失敗"; syncing = false }
            } catch {
                await MainActor.run { syncMessage = "❌ \(error.localizedDescription)"; syncing = false }
            }
        }
    }

    private func exportBackup() {
        guard let d = NSApp.delegate as? AppDelegate else { return }
        let snap = DataStore.BackupSnapshot(groups: d.store.groups, tokens: d.store.allTokens)
        let data = (try? JSONEncoder().encode(snap)) ?? Data()
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = "tokenvault-backup-\(Date().formatted(date: .abbreviated, time: .omitted)).json"
        savePanel.allowedContentTypes = [.json]
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url { try? data.write(to: url) }
        }
    }

    private func importBackup() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.json]
        openPanel.begin { response in
            guard response == .OK, let url = openPanel.url,
                  let data = try? Data(contentsOf: url) else { return }
            DispatchQueue.main.async {
                guard let d = NSApp.delegate as? AppDelegate,
                      let snap = try? JSONDecoder().decode(DataStore.BackupSnapshot.self, from: data) else { return }
                d.store.groups = snap.groups
                d.store.allTokens = snap.tokens
                d.store.save()
            }
        }
    }
}
