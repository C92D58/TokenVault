import SwiftUI
import UniformTypeIdentifiers

// MARK: - Import Wizard

struct ImportWizard: View {
    @ObservedObject var store: DataStore
    let onDismiss: () -> Void

    @State private var step = 0
    @State private var fileContent = ""
    @State private var fileName = ""
    @State private var parsedTokens: [ParsedToken] = []
    @State private var selectedTokens = Set<Int>()
    @State private var importSuccess = false
    @State private var importCount = 0

    struct ParsedToken: Identifiable {
        let id = UUID()
        let name: String; let value: String; let note: String
        let env: TokenEnvironment; let type: TokenType
        var selected: Bool = true
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with steps
            headerBar

            Divider()

            // Content
            Group {
                switch step {
                case 0: stepSelectFile
                case 1: stepPreview
                case 2: stepResult
                default: EmptyView()
                }
            }
            .frame(maxHeight: .infinity)

            // Footer
            if !importSuccess {
                Divider()
                footerButtons
            }
        }
        .frame(width: 520, height: 440)
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 0) {
            stepIndicator(0, "選擇檔案")
            stepConnector(0)
            stepIndicator(1, "預覽確認")
            stepConnector(1)
            stepIndicator(2, "完成")
            Spacer()
            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.cancelAction)
        }
        .padding(.horizontal, 24).padding(.vertical, 16)
    }

    private func stepIndicator(_ index: Int, _ label: String) -> some View {
        HStack(spacing: 8) {
            ZStack {
                if step > index {
                    Circle().fill(Color.green).frame(width: 24, height: 24)
                    Image(systemName: "checkmark").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                } else if step == index {
                    Circle().fill(Color.accentColor).frame(width: 24, height: 24)
                    Text("\(index + 1)").font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                } else {
                    Circle().stroke(.secondary.opacity(0.3), lineWidth: 2).frame(width: 24, height: 24)
                    Text("\(index + 1)").font(.system(size: 11)).foregroundColor(.secondary.opacity(0.4))
                }
            }
            Text(label).font(.system(size: 11, weight: step >= index ? .medium : .regular))
                .foregroundColor(step >= index ? .primary : .secondary.opacity(0.4))
        }
    }

    private func stepConnector(_ index: Int) -> some View {
        Rectangle()
            .fill(step > index ? Color.green.opacity(0.5) : Color.secondary.opacity(0.15))
            .frame(height: 2)
            .frame(width: 40)
            .padding(.horizontal, 4)
    }

    // MARK: - Step 0: Select File

    private var stepSelectFile: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                    .foregroundColor(.secondary.opacity(0.3))
                    .frame(width: 260, height: 160)

                VStack(spacing: 12) {
                    Image(systemName: "doc.badge.arrow.up")
                        .font(.system(size: 36)).foregroundColor(.accentColor.opacity(0.6))
                    Text("拖放檔案或點擊選擇").font(.system(size: 13)).foregroundColor(.secondary)
                    Text("支援 .env / .csv / .json").font(.system(size: 10)).foregroundColor(.secondary.opacity(0.5))

                    if !fileName.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "doc.fill").font(.system(size: 12)).foregroundColor(.accentColor)
                            Text(fileName).font(.system(size: 12, weight: .medium)).lineLimit(1)
                        }
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.accentColor.opacity(0.08)))
                    }
                }

                Button("選擇檔案") {
                    selectFile()
                }
                .buttonStyle(.borderedProminent)
                .opacity(0) // Invisible button on top
            }

            // Quick paste option
            VStack(spacing: 6) {
                Text("或直接貼上內容").font(.system(size: 10)).foregroundColor(.secondary.opacity(0.5))
                TextEditor(text: $fileContent)
                    .font(.system(size: 9, design: .monospaced))
                    .frame(height: 60)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(.quaternary, lineWidth: 1))
                    .cornerRadius(8)
                    .padding(.horizontal, 40)

                Button("解析貼上的內容") {
                    parseContent()
                }
                .buttonStyle(.bordered).controlSize(.small)
                .disabled(fileContent.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            Spacer()
        }
    }

    // MARK: - Step 1: Preview

    private var stepPreview: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("找到 \(parsedTokens.count) 個 Token").font(.system(size: 12, weight: .medium))
                Spacer()
                HStack(spacing: 8) {
                    Button("全選") {
                        selectedTokens = Set(parsedTokens.indices)
                        for i in parsedTokens.indices { parsedTokens[i].selected = true }
                    }.buttonStyle(.bordered).controlSize(.small)
                    Button("取消全選") {
                        selectedTokens = []
                        for i in parsedTokens.indices { parsedTokens[i].selected = false }
                    }.buttonStyle(.bordered).controlSize(.small)
                }
            }.padding(.horizontal, 16).padding(.vertical, 8)

            Divider()

            // Token list
            ScrollView {
                VStack(spacing: 4) {
                    ForEach(parsedTokens.indices, id: \.self) { i in
                        previewRow(i)
                    }
                }
                .padding(12)
            }
        }
    }

    private func previewRow(_ i: Int) -> some View {
        let token = parsedTokens[i]
        return HStack(spacing: 10) {
            Toggle("", isOn: Binding(
                get: { selectedTokens.contains(i) },
                set: { selected in
                    if selected { selectedTokens.insert(i) } else { selectedTokens.remove(i) }
                    parsedTokens[i].selected = selected
                }
            )).toggleStyle(.checkbox).labelsHidden()

            VStack(alignment: .leading, spacing: 2) {
                Text(token.name).font(.system(size: 12, weight: .medium)).lineLimit(1)
                Text(token.value.count > 30 ? "\(token.value.prefix(30))..." : token.value)
                    .font(.system(size: 10, design: .monospaced)).foregroundColor(.secondary).lineLimit(1)
            }
            Spacer()
            HStack(spacing: 4) {
                envPill(token.env)
                typePill(token.type)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 6).fill(.quaternary.opacity(0.5)))
    }

    private func envPill(_ env: TokenEnvironment) -> some View {
        Text(env.rawValue).font(.system(size: 8, weight: .bold))
            .padding(.horizontal, 5).padding(.vertical, 2)
            .background(Capsule().fill(env.color.bg.swiftUIColor.opacity(0.12)))
            .foregroundColor(env.color.bg.swiftUIColor)
    }

    private func typePill(_ type: TokenType) -> some View {
        HStack(spacing: 3) {
            Image(systemName: type.icon).font(.system(size: 7))
            Text(type.label).font(.system(size: 8))
        }
        .foregroundColor(type.color.swiftUIColor.opacity(0.7))
    }

    // MARK: - Step 2: Result

    private var stepResult: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle().fill(Color.green.opacity(0.1)).frame(width: 72, height: 72)
                Image(systemName: "checkmark.circle.fill").font(.system(size: 40)).foregroundColor(.green)
            }

            Text("導入完成").font(.system(size: 18, weight: .bold))
            Text("已導入 \(importCount) 個 Token").font(.system(size: 13)).foregroundColor(.secondary)

            Button("關閉") { onDismiss() }.buttonStyle(.borderedProminent).controlSize(.small)

            Spacer()
        }
    }

    // MARK: - Footer

    private var footerButtons: some View {
        HStack {
            if step > 0 {
                Button("上一步") { step -= 1 }.buttonStyle(.bordered).controlSize(.small)
            }
            Spacer()
            Button("取消") { onDismiss() }.buttonStyle(.bordered).controlSize(.small)
            if step == 0 && !parsedTokens.isEmpty {
                Button("下一步") { step = 1 }.buttonStyle(.borderedProminent).controlSize(.small)
            }
            if step == 1 {
                Button("導入 \(selectedTokens.count) 個") {
                    importSelected()
                }
                .buttonStyle(.borderedProminent).controlSize(.small)
                .disabled(selectedTokens.isEmpty)
            }
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }

    // MARK: - Actions

    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [
            UTType(filenameExtension: "env") ?? .plainText,
            .commaSeparatedText,
            .json,
            .plainText
        ]
        panel.allowsMultipleSelection = false
        panel.begin { response in
            guard response == .OK, let url = panel.url,
                  let content = try? String(contentsOf: url) else { return }
            fileName = url.lastPathComponent
            fileContent = content
            parseContent()
        }
    }

    private func parseContent() {
        let text = fileContent.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }

        var tokens: [ParsedToken] = []

        // Try .env format first
        if text.contains("=") && !text.hasPrefix("{") && !text.hasPrefix("[") {
            tokens = ImportExportHelper.parseEnv(text).map {
                ParsedToken(name: $0.name, value: $0.value, note: $0.note,
                            env: .production, type: TokenType.detect(from: $0.name, value: $0.value))
            }
        }

        // Try CSV
        if tokens.isEmpty && text.contains(",") {
            tokens = ImportExportHelper.parseCSV(text).map {
                ParsedToken(name: $0.name, value: $0.value, note: $0.note,
                            env: $0.env, type: TokenType.detect(from: $0.name, value: $0.value))
            }
        }

        // Try JSON (TokenVault backup)
        if tokens.isEmpty && (text.hasPrefix("{") || text.hasPrefix("[")) {
            if let data = text.data(using: .utf8),
               let snap = try? JSONDecoder().decode(DataStore.BackupSnapshot.self, from: data) {
                tokens = snap.tokens.map {
                    ParsedToken(name: $0.name, value: $0.decryptedValue(), note: $0.note,
                                env: $0.environment, type: $0.tokenType)
                }
            }
        }

        // Fallback: line by line as "name:value"
        if tokens.isEmpty {
            tokens = text.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty && !$0.hasPrefix("#") }
                .enumerated()
                .compactMap { i, line -> ParsedToken? in
                    let parts = line.contains("=") ? line.split(separator: "=", maxSplits: 1) :
                                line.contains(":") ? line.split(separator: ":", maxSplits: 1) :
                                [Substring("Token_\(i+1)"), Substring(line)]
                    guard parts.count >= 2 else { return nil }
                    let name = String(parts[0]).trimmingCharacters(in: .whitespaces)
                    let value = String(parts[1]).trimmingCharacters(in: .whitespaces)
                        .replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: "'", with: "")
                    guard !value.isEmpty else { return nil }
                    return ParsedToken(name: name, value: value, note: "手動貼上導入",
                                       env: .production, type: TokenType.detect(from: name, value: value))
                }
        }

        parsedTokens = tokens
        selectedTokens = Set(tokens.indices)
        if !tokens.isEmpty { step = 1 }
    }

    private func importSelected() {
        let selected = parsedTokens.enumerated().filter { selectedTokens.contains($0.offset) }.map(\.element)
        for t in selected {
            store.addToken(TokenItem(name: t.name, plainValue: t.value, note: t.note,
                                     environment: t.env, tokenType: t.type), to: nil)
        }
        importCount = selected.count
        importSuccess = true
        step = 2
    }
}
