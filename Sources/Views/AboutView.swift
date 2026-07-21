import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "key.horizontal.fill")
                .font(.system(size: 36)).foregroundColor(.accentColor)

            Text("TokenVault")
                .font(.system(size: 18, weight: .bold))

            Text("版本 1.0")
                .font(.system(size: 12)).foregroundColor(.secondary)

            Text("本地化 API Token 管理")
                .font(.system(size: 11)).foregroundColor(.secondary)

            Divider().frame(width: 200)

            VStack(spacing: 4) {
                Text("© 2026 WAHSUN")
                    .font(.system(size: 11, weight: .medium))
                Text("x@wahsun.org")
                    .font(.system(size: 10)).foregroundColor(.secondary)
            }
        }.padding(24).frame(width: 320, height: 200)
    }
}
