import SwiftUI
import AppKit

struct NativeHorizontalScrollView<Content: View>: NSViewRepresentable {
    let content: () -> Content
    var selectedIndex: Int
    var itemWidth: CGFloat
    var spacing: CGFloat

    init(
        selectedIndex: Int = 0,
        itemWidth: CGFloat = 180,
        spacing: CGFloat = 10,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.selectedIndex = selectedIndex
        self.itemWidth = itemWidth
        self.spacing = spacing
        self.content = content
    }
    
    func makeNSView(context: Context) -> SmoothWheelScrollView {
        let scrollView = SmoothWheelScrollView()
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = false
        scrollView.drawsBackground = false
        scrollView.autohidesScrollers = true

        let hostingView = NSHostingView(rootView: content())
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        let documentView = NSView()
        documentView.addSubview(hostingView)

        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: documentView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: documentView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: documentView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: documentView.bottomAnchor)
        ])

        scrollView.documentView = documentView
        return scrollView
    }

    func updateNSView(_ nsView: SmoothWheelScrollView, context: Context) {
        if let documentView = nsView.documentView,
           let hostingView = documentView.subviews.first as? NSHostingView<Content> {
            hostingView.rootView = content()
            hostingView.invalidateIntrinsicContentSize()
            documentView.frame = NSRect(origin: .zero, size: hostingView.intrinsicContentSize)
        }

        DispatchQueue.main.async {
            nsView.scrollToItem(at: selectedIndex, itemWidth: itemWidth, spacing: spacing)
        }
    }
}

class SmoothWheelScrollView: NSScrollView {

    override func scrollWheel(with event: NSEvent) {
        if abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) {
            super.scrollWheel(with: event)
            return
        }

        let delta = event.scrollingDeltaY != 0 ? event.scrollingDeltaY : event.deltaY * 10
        let clipView = contentView // Direct access without casting

        var newOrigin = clipView.bounds.origin
        newOrigin.x -= delta * 2.5

        if let docView = documentView {
            let maxX = docView.bounds.width - clipView.bounds.width
            newOrigin.x = max(0, min(newOrigin.x, max(0, maxX)))
        }

        clipView.scroll(to: newOrigin)
        reflectScrolledClipView(clipView)
    }

    func scrollToItem(at index: Int, itemWidth: CGFloat, spacing: CGFloat) {
        guard let docView = documentView else { return }

        let clipView = contentView

        let itemLeft = 20 + CGFloat(index) * (itemWidth + spacing)
        let itemRight = itemLeft + itemWidth

        let visibleLeft = clipView.bounds.origin.x
        let visibleWidth = clipView.bounds.width
        let visibleRight = visibleLeft + visibleWidth

        let maxScrollX = max(0, docView.bounds.width - visibleWidth)

        var newX = visibleLeft

        if itemRight > visibleRight {
            newX = itemRight - visibleWidth + 20
        }
        else if itemLeft < visibleLeft {
            newX = max(0, itemLeft - 20)
        }

        newX = max(0, min(newX, maxScrollX))

        if newX != visibleLeft {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                clipView.animator().setBoundsOrigin(NSPoint(x: newX, y: 0))
            }
            reflectScrolledClipView(clipView)
        }
    }
}
