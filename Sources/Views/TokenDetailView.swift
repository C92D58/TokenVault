import SwiftUI

struct TokenDetailView: View {
    @ObservedObject var store: DataStore
    let token: TokenItem?
    @State private var showCopied = false
    @State private var showValue = false
    @State private var showEditSheet = false

    var body: some View {
        if let token = token {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    HStack(spacing: 12) {
                        Image(systemName: token.isFavorite ? "star.fill" : "key.fill")
                            .font(.system(size: 18))
                            .foregroundColor(token.isFavorite ? .orange : .accentColor)
                            .frame(width: 40, height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(token.isFavorite ? Color.orange.opacity(0.15) : Color.accentColor.opacity(0.12))
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(token.name)
                                .font(.system(size: 16, weight: .bold))
                            if let gid = token.groupID, let group = store.groups.first(where: { $0.id == gid }) {
                                Text(group.name)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        Spacer()

                        Button {
                            store.toggleFavorite(token)
                            store.save()
                        } label: {
                            Image(systemName: token.isFavorite ? "star.fill" : "star")
                                .font(.system(size: 15))
                                .foregroundColor(token.isFavorite ? .orange : .secondary)
                        }
                        .buttonStyle(.plain)

                        Button {
                            showEditSheet = true
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)

                        Button {
                            store.deleteToken(token)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    Divider()

                    // Token value
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Token 值")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)

                        HStack {
                            if showValue {
                                Text(token.value)
                                    .font(.system(size: 12, design: .monospaced))
                                    .textSelection(.enabled)
                            } else {
                                Text(token.maskedValue)
                                    .font(.system(size: 12, design: .monospaced))
                            }
                            Spacer()
                            HStack(spacing: 8) {
                                Button { showValue.toggle() } label: {
                                    Image(systemName: showValue ? "eye.slash" : "eye")
                                        .font(.system(size: 12))
                                }
                                .buttonStyle(.plain)
                                .foregroundColor(.secondary)

                                Button {
                                    ClipboardService.shared.copy(token.value)
                                    token.copyCount += 1
                                    store.save()
                                    withAnimation(.spring(response: 0.3)) { showCopied = true }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        withAnimation { showCopied = false }
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                                            .font(.system(size: 11))
                                        Text(showCopied ? "已複製" : "複製")
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule()
                                            .fill(showCopied ? Color.green.opacity(0.15) : Color.accentColor.opacity(0.12))
                                    )
                                    .foregroundColor(showCopied ? .green : .accentColor)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
                    }

                    // Info grid
                    InfoGrid(token: token)

                    if !token.note.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("備註")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.secondary)
                            Text(token.note)
                                .font(.system(size: 13))
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(20)
            }
            .sheet(isPresented: $showEditSheet) {
                AddTokenSheet(store: store, editingToken: token) { showEditSheet = false }
            }
        } else {
            VStack(spacing: 8) {
                Image(systemName: "key.horizontal")
                    .font(.system(size: 28))
                    .foregroundColor(.secondary.opacity(0.3))
                Text("選擇一個 Token")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct InfoGrid: View {
    @ObservedObject var token: TokenItem

    var body: some View {
        VStack(spacing: 0) {
            InfoRow(label: "建立時間", value: token.createdAt.formatted(date: .abbreviated, time: .shortened))
            Divider().padding(.leading, 44)
            InfoRow(label: "複製次數", value: "\(token.copyCount)")
            if let exp = token.expiresAt {
                Divider().padding(.leading, 44)
                InfoRow(
                    label: "到期日",
                    value: exp.formatted(date: .abbreviated, time: .omitted),
                    valueColor: token.isExpired ? .red : (token.expiresSoon ? .orange : .primary)
                )
            }
        }
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)
                .padding(.leading, 12)
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(valueColor)
            Spacer()
        }
        .padding(.vertical, 8)
    }
}
