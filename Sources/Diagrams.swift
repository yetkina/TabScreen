import SwiftUI

/// Little illustrated scenes (Mac ⇄ link ⇄ tablet) drawn with shapes + SF Symbols, used by the guide.
struct Endpoint {
    var symbol: String? = nil
    var text: String? = nil
    var tint: Color = .blue
    var dim: Bool = false
}

struct LinkSpec {
    var symbol: String
    var color: Color = .green
    var badge: String? = nil
    var badgeColor: Color = .red
}

struct MacShape: View {
    var e: Endpoint
    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 9)
                .fill(LinearGradient(colors: [e.tint.opacity(e.dim ? 0.25 : 0.9), e.tint.opacity(e.dim ? 0.12 : 0.5)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.primary.opacity(0.55), lineWidth: 3))
                .frame(width: 104, height: 68)
                .overlay(content)
            Rectangle().fill(Color.primary.opacity(0.4)).frame(width: 10, height: 9)
            Capsule().fill(Color.primary.opacity(0.4)).frame(width: 46, height: 5)
        }
    }
    @ViewBuilder private var content: some View {
        if let s = e.symbol { Image(systemName: s).font(.title).foregroundStyle(.white) }
        if let t = e.text { Text(t).font(.system(.title3, design: .monospaced).bold()).foregroundStyle(.white) }
    }
}

struct TabletShape: View {
    var e: Endpoint
    var body: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(LinearGradient(colors: [e.tint.opacity(e.dim ? 0.2 : 0.9), e.tint.opacity(e.dim ? 0.1 : 0.5)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.6), lineWidth: 4))
            .overlay(Circle().fill(Color.primary.opacity(0.5)).frame(width: 5, height: 5).offset(x: -52 + 4, y: 0), alignment: .leading)
            .frame(width: 98, height: 68)
            .overlay {
                if let s = e.symbol { Image(systemName: s).font(.title).foregroundStyle(.white) }
                if let t = e.text { Text(t).font(.system(.title3, design: .monospaced).bold()).foregroundStyle(.white) }
            }
    }
}

struct LinkView: View {
    var l: LinkSpec
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: l.symbol).font(.system(size: 26, weight: .semibold)).foregroundStyle(l.color)
                .overlay(alignment: .topTrailing) {
                    if let b = l.badge {
                        Image(systemName: b).font(.system(size: 15, weight: .bold)).foregroundStyle(l.badgeColor)
                            .background(Circle().fill(.background)).offset(x: 10, y: -8)
                    }
                }
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { _ in Capsule().fill(l.color.opacity(0.6)).frame(width: 6, height: 3) }
            }
        }
        .frame(width: 70)
    }
}

struct DiagramScene: View {
    var left: Endpoint
    var link: LinkSpec
    var right: Endpoint
    var body: some View {
        HStack(spacing: 6) {
            MacShape(e: left)
            LinkView(l: link)
            TabletShape(e: right)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.primary.opacity(0.05)))
    }
}

/// A set of ready-made scenes keyed by name.
enum Scenes {
    static func make(_ key: String) -> DiagramScene {
        switch key {
        case "setup":
            return DiagramScene(left: .init(symbol: "shippingbox.fill", tint: .indigo),
                         link: .init(symbol: "arrow.right", color: .indigo),
                         right: .init(symbol: "moon.zzz.fill", tint: .gray, dim: true))
        case "virtual":
            return DiagramScene(left: .init(symbol: "display.2", tint: .purple),
                         link: .init(symbol: "plus.circle.fill", color: .purple),
                         right: .init(symbol: "rectangle.dashed", tint: .gray, dim: true))
        case "permissions":
            return DiagramScene(left: .init(symbol: "lock.open.fill", tint: .orange),
                         link: .init(symbol: "checkmark.shield.fill", color: .orange),
                         right: .init(symbol: "moon.zzz.fill", tint: .gray, dim: true))
        case "pairing":
            return DiagramScene(left: .init(symbol: "keyboard", tint: .teal),
                         link: .init(symbol: "link", color: .teal),
                         right: .init(text: "1234", tint: .teal))
        case "connected":
            return DiagramScene(left: .init(symbol: "macwindow", tint: .blue),
                         link: .init(symbol: "wifi", color: .green),
                         right: .init(symbol: "macwindow", tint: .blue))
        case "nosignal":
            return DiagramScene(left: .init(symbol: "desktopcomputer", tint: .blue),
                         link: .init(symbol: "wifi.slash", color: .red, badge: "xmark.circle.fill"),
                         right: .init(symbol: "questionmark", tint: .gray, dim: true))
        case "samenet":
            return DiagramScene(left: .init(symbol: "desktopcomputer", tint: .blue),
                         link: .init(symbol: "wifi.router.fill", color: .green, badge: "checkmark.circle.fill", badgeColor: .green),
                         right: .init(symbol: "wifi", tint: .green))
        case "black":
            return DiagramScene(left: .init(symbol: "display", tint: .blue),
                         link: .init(symbol: "arrow.right", color: .orange, badge: "exclamationmark.triangle.fill", badgeColor: .orange),
                         right: .init(symbol: "moon.fill", tint: .black))
        case "blurry":
            return DiagramScene(left: .init(text: "1920×1200", tint: .blue),
                         link: .init(symbol: "equal.circle.fill", color: .green),
                         right: .init(text: "1920×1200", tint: .blue))
        case "lag":
            return DiagramScene(left: .init(symbol: "cable.connector", tint: .blue),
                         link: .init(symbol: "speedometer", color: .green, badge: "bolt.fill", badgeColor: .yellow),
                         right: .init(symbol: "wifi", tint: .green))
        case "firewall":
            return DiagramScene(left: .init(symbol: "flame.fill", tint: .red),
                         link: .init(symbol: "shield.lefthalf.filled", color: .red, badge: "xmark.circle.fill"),
                         right: .init(symbol: "questionmark", tint: .gray, dim: true))
        case "logs":
            return DiagramScene(left: .init(symbol: "doc.text.magnifyingglass", tint: .brown),
                         link: .init(symbol: "arrow.right", color: .brown),
                         right: .init(symbol: "lightbulb.fill", tint: .yellow))
        default:
            return DiagramScene(left: .init(symbol: "desktopcomputer"), link: .init(symbol: "wifi"), right: .init(symbol: "ipad"))
        }
    }
}
