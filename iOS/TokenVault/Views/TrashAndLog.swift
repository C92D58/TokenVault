import SwiftUI

struct TrashView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var vault: VaultStore
    @EnvironmentObject private var toast: ToastCenter
    @State private var confirmEmpty = false

    private var trashed: [TokenItem] { vault.trashedTokens }

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                if trashed.isEmpty {
                    EmptyState(symbol: "trash", title: "垃圾桶是空的",
                               message: "刪除的密鑰會在這裡保留 30 天，之後自動清除。")
                    .frame(maxHeight: .infinity, alignment: .center)
                } else {
                    ScrollView {
                        VStack(spacing: Theme.Space.xs) {
                            ForEach(trashed) { token in
                                row(token)
                            }
                            SecondaryButton(title: "清空垃圾桶", symbol: "trash.slash", destructive: true) {
                                confirmEmpty = true
                            }
                            .padding(.top, Theme.Space.s)
                        }
                        .padding(.horizontal, Theme.inset)
                        .padding(.vertical, Theme.Space.s)
                        .padding(.bottom, 90)
                    }
                }
            }
            .navigationTitle("垃圾桶")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") { dismiss() }
                        .foregroundStyle(Theme.accent)
                }
            }
            .confirmationDialog("清空垃圾桶？", isPresented: $confirmEmpty, titleVisibility: .visible) {
                Button("永久刪除全部", role: .destructive) {
                    vault.emptyTrash()
                    toast.show("垃圾桶已清空", symbol: "trash", tint: Theme.warning)
                }
                Button("取消", role: .cancel) {}
            } message: {
                Text("此操作無法復原。")
            }
        }
    }

    private func row(_ token: TokenItem) -> some View {
        HStack(spacing: Theme.Space.s) {
            ProviderBadge(provider: token.provider, size: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(token.name)
                    .font(Theme.cardTitle)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                if let deleted = token.deletedAt {
                    Text("刪除於 \(deleted.formatted(date: .abbreviated, time: .shortened))")
                        .font(Theme.caption)
                        .foregroundStyle(Theme.textTertiary)
                }
            }
            Spacer()
            Button {
                vault.restore(token)
                toast.show("已復原", symbol: "arrow.uturn.backward", tint: Theme.accent)
            } label: {
                Text("復原")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Theme.accentSoft))
            }
            .buttonStyle(.plain)
        }
        .cardSurface(radius: Theme.Radius.card, padding: 11)
    }
}

struct SecurityLogView: View {
    @ObservedObject private var log = SecurityLogService.shared
    @Environment(\.scenePhase) private var scenePhase
    @State private var confirmClear = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScreenBackground()
                if log.entries.isEmpty {
                    EmptyState(symbol: "clock.arrow.circlepath", title: "還沒有紀錄",
                               message: "複製、檢視、匯入與匯出都會寫進這份本機稽核日誌。")
                    .frame(maxHeight: .infinity, alignment: .center)
                } else {
                    List {
                        Section {
                            ForEach(log.entries) { entry in
                                row(entry)
                                    .listRowInsets(EdgeInsets(top: 5, leading: Theme.inset,
                                                              bottom: 5, trailing: Theme.inset))
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                            }
                        } footer: {
                            Text("最多保留 500 筆，只在這一台裝置上。")
                                .font(Theme.caption)
                                .foregroundStyle(Theme.textTertiary)
                                .padding(.top, Theme.Space.s)
                                .padding(.bottom, 90)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("安全日誌")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !log.entries.isEmpty {
                        Button("清空") { confirmClear = true }
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Theme.danger)
                    }
                }
            }
            .confirmationDialog("清空稽核日誌？", isPresented: $confirmClear, titleVisibility: .visible) {
                Button("清空", role: .destructive) { log.clear() }
                Button("取消", role: .cancel) {}
            }
        }
    }

    private func row(_ entry: SecurityLogEntry) -> some View {
        HStack(spacing: Theme.Space.s) {
            Image(systemName: entry.action.icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(tint(for: entry.action))
                .frame(width: 30, height: 30)
                .background(RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(tint(for: entry.action).opacity(0.12)))

            VStack(alignment: .leading, spacing: 2) {
                Text("\(entry.action.rawValue)  \(entry.tokenName)")
                    .font(Theme.callout)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(entry.provider)
                    .font(Theme.caption)
                    .foregroundStyle(Theme.textTertiary)
            }
            Spacer()
            Text(entry.relativeTime)
                .font(Theme.caption)
                .foregroundStyle(Theme.textTertiary)
        }
        .cardSurface(radius: Theme.Radius.card, padding: 11)
    }

    private func tint(for action: SecurityLogEntry.Action) -> Color {
        switch action {
        case .copied: return Theme.accent
        case .deleted: return Theme.danger
        case .created, .imported, .restored: return Theme.success
        case .exported, .edited, .rotation: return Theme.warning
        case .locked, .unlocked, .viewed: return Theme.textSecondary
        }
    }
}
