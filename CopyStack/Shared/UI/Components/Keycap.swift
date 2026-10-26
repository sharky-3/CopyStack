import SwiftUI

struct Keycap: View {
    let text: String
    var large = false

    var body: some View {
        Text(text)
            .font(.system(size: large ? 15 : 11, weight: .semibold, design: .rounded))
            .foregroundStyle(.primary.opacity(0.8))
            .padding(.horizontal, large ? 10 : 6)
            .frame(minWidth: large ? 34 : 20, minHeight: large ? 34 : 20)
            .background(RoundedRectangle(cornerRadius: large ? 10 : 6, style: .continuous).fill(.primary.opacity(0.1)))
            .overlay(RoundedRectangle(cornerRadius: large ? 10 : 6, style: .continuous).strokeBorder(.primary.opacity(0.14), lineWidth: 1))
    }
}
