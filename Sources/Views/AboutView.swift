import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.shield.fill").font(.system(size: 36)).foregroundColor(.accentColor)
            Text("TokenVault").font(.system(size: 18, weight: .bold))
            Text("版本 1.0").font(.system(size: 12)).foregroundColor(.secondary)

            VStack(spacing: 6) {
                Text("零知識 API Token 管理器")
                    .font(.system(size: 11)).foregroundColor(.secondary)
                HStack(spacing: 4) {
                    Image(systemName: "lock.fill").font(.system(size: 9)).foregroundColor(.green)
                    Text("AES-256-GCM 加密").font(.system(size: 10)).foregroundColor(.secondary)
                }
                HStack(spacing: 4) {
                    Image(systemName: "icloud.fill").font(.system(size: 9))
                    Text("iCloud 端到端同步").font(.system(size: 10)).foregroundColor(.secondary)
                }
            }

            Divider().frame(width: 200)

            VStack(spacing: 4) {
                Text("© 2026 WAHSUN").font(.system(size: 11, weight: .medium))
                Text("x@wahsun.org").font(.system(size: 10)).foregroundColor(.secondary)
            }
        }.padding(24).frame(width: 320, height: 280)
    }
}
