import SwiftUI

struct RevealUp: ViewModifier {
    @State private var appeared = false
    var delay: Double

    func body(content: Content) -> some View {
        content
            .offset(y: appeared ? 0 : 28)
            .opacity(appeared ? 1 : 0)
            .blur(radius: appeared ? 0 : 8)
            .onAppear {
                withAnimation(.spring(response: 0.75, dampingFraction: 0.82).delay(delay)) {
                    appeared = true
                }
            }
            .onDisappear {
                appeared = false
            }
    }
}

struct RevealSide: ViewModifier {
    @State private var appeared = false
    var delay: Double

    func body(content: Content) -> some View {
        content
            .offset(x: appeared ? 0 : -50)
            .opacity(appeared ? 1 : 0)
            .blur(radius: appeared ? 0 : 10)
            .onAppear {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.78).delay(delay)) {
                    appeared = true
                }
            }
            .onDisappear {
                appeared = false
            }
    }
}

struct RevealPop: ViewModifier {
    @State private var appeared = false
    var delay: Double

    func body(content: Content) -> some View {
        content
            .scaleEffect(appeared ? 1 : 0.4)
            .rotationEffect(.degrees(appeared ? 0 : -25))
            .opacity(appeared ? 1 : 0)
            .onAppear {
                withAnimation(.spring(response: 0.55, dampingFraction: 0.55).delay(delay)) {
                    appeared = true
                }
            }
            .onDisappear {
                appeared = false
            }
    }
}

extension View {
    func revealUp(delay: Double = 0) -> some View {
        modifier(RevealUp(delay: delay))
    }
    func revealSide(delay: Double = 0) -> some View {
        modifier(RevealSide(delay: delay))
    }
    func revealPop(delay: Double = 0) -> some View {
        modifier(RevealPop(delay: delay))
    }
}
