import SwiftUI

enum ZT {
    static let ink = Color(red: 0.12, green: 0.19, blue: 0.28)
    static let muted = Color(red: 0.43, green: 0.48, blue: 0.53)
    static let blue = Color(red: 0.20, green: 0.45, blue: 0.94)
    static let green = Color(red: 0.29, green: 0.66, blue: 0.53)
    static let paper = Color(red: 0.97, green: 0.96, blue: 0.93)
    static let card = Color.white
    static let line = Color(red: 0.89, green: 0.90, blue: 0.89)
}

struct ZTCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(16)
            .background(ZT.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(ZT.line.opacity(0.7), lineWidth: 0.7))
    }
}

struct SectionHeading: View {
    let title: String
    var trailing: String? = nil
    var body: some View {
        HStack {
            Text(title).font(.system(size: 19, weight: .bold)).foregroundStyle(ZT.ink)
            Spacer()
            if let trailing {
                Text(trailing).font(.system(size: 13, weight: .medium)).foregroundStyle(ZT.blue)
            }
        }
    }
}
