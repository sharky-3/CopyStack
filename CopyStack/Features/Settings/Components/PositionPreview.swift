import SwiftUI

struct PositionPreview: View {
    let position: PanelPosition

    private static func panelRect(position: PanelPosition, width: CGFloat, height: CGFloat) -> CGRect {
        let margin = width * 0.025
        let top = height * 0.075
        let bottom = height * 0.11
        let usable = height - top - bottom
        switch position {
        case .top:
            return CGRect(x: margin, y: top + margin, width: width - margin * 2, height: usable * 0.4)
        case .bottom:
            let h = usable * 0.4
            return CGRect(x: margin, y: height - bottom - margin - h, width: width - margin * 2, height: h)
        case .left:
            return CGRect(x: margin, y: top + margin, width: width * 0.27, height: usable - margin * 2)
        case .right:
            let w = width * 0.27
            return CGRect(x: width - margin - w, y: top + margin, width: w, height: usable - margin * 2)
        case .center:
            let w = width * 0.64
            let h = usable * 0.74
            return CGRect(x: (width - w) / 2, y: top + (usable - h) / 2, width: w, height: h)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let rect = Self.panelRect(position: position, width: width, height: height)

            ZStack(alignment: .topLeading) {
                LinearGradient(colors: [Color(red: 0.13, green: 0.17, blue: 0.42), Color(red: 0.46, green: 0.22, blue: 0.64), Color(red: 0.96, green: 0.48, blue: 0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)

                Rectangle()
                    .fill(.black.opacity(0.28))
                    .frame(width: width, height: height * 0.075)
                    .overlay(alignment: .leading) {
                        HStack(spacing: 5) {
                            Circle().fill(.white.opacity(0.8)).frame(width: 5, height: 5)
                            Capsule().fill(.white.opacity(0.5)).frame(width: 22, height: 3)
                            Capsule().fill(.white.opacity(0.3)).frame(width: 16, height: 3)
                        }
                        .padding(.leading, 10)
                    }

                Capsule()
                    .fill(.white.opacity(0.28))
                    .frame(width: width * 0.34, height: height * 0.07)
                    .position(x: width / 2, y: height - height * 0.05)

                panel(rect: rect)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(.white.opacity(0.3), lineWidth: 1))
        }
        .aspectRatio(16.0 / 10.0, contentMode: .fit)
    }

    private func panel(rect: CGRect) -> some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .fill(Color.white.opacity(0.55))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(.white.opacity(0.45), lineWidth: 1))
            .overlay {
                ZStack {
                    MiniCards(layout: position.layout)
                        .id(position.layout)
                        .transition(.opacity)
                }
            }
            .frame(width: rect.width, height: rect.height)
            .offset(x: rect.minX, y: rect.minY)
            .animation(.spring(response: 0.55, dampingFraction: 0.78), value: position)
    }
}

private struct MiniCards: View {
    let layout: PanelLayout

    var body: some View {
        switch layout {
        case .strip:
            HStack(spacing: 5) {
                ForEach(0..<5, id: \.self) { i in
                    card(selected: i == 1)
                }
            }
            .padding(8)
        case .column:
            VStack(spacing: 5) {
                ForEach(0..<4, id: \.self) { i in
                    card(selected: i == 0)
                }
            }
            .padding(8)
        case .grid:
            VStack(spacing: 5) {
                ForEach(0..<2, id: \.self) { row in
                    HStack(spacing: 5) {
                        ForEach(0..<3, id: \.self) { col in
                            card(selected: row == 0 && col == 1)
                        }
                    }
                }
            }
            .padding(8)
        }
    }

    private func card(selected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 5, style: .continuous)
            .fill(selected ? Color.accentColor.opacity(0.95) : Color.white.opacity(0.4))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PositionPicker: View {
    @Binding var selection: PanelPosition
    @Namespace private var space

    var body: some View {
        HStack(spacing: 8) {
            ForEach(PanelPosition.allCases) { item in
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selection = item
                    }
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 18, weight: .medium))
                        Text(item.title)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(selection == item ? Color.white : Color.primary.opacity(0.7))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background {
                        if selection == item {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.accentColor.gradient)
                                .matchedGeometryEffect(id: "selected", in: space)
                        } else {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.primary.opacity(0.06))
                        }
                    }
                    .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}
