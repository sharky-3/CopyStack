import SwiftUI
import AppKit

struct NativeHorizontalScrollView<Content: View>: NSViewRepresentable {
    let content: () -> Content
    var itemWidth: CGFloat
    var spacing: CGFloat

    init(
        itemWidth: CGFloat = 180,
        spacing: CGFloat = 10,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.itemWidth = itemWidth
        self.spacing = spacing
        self.content = content
    }
    
    func makeNSView(context: Context) -> EdgeHoverScrollView {
        let scrollView = EdgeHoverScrollView()
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

    func updateNSView(_ nsView: EdgeHoverScrollView, context: Context) {
        if let documentView = nsView.documentView,
           let hostingView = documentView.subviews.first as? NSHostingView<Content> {
            hostingView.rootView = content()
            hostingView.invalidateIntrinsicContentSize()
            documentView.frame = NSRect(origin: .zero, size: hostingView.intrinsicContentSize)
        }
    }
}

class EdgeHoverScrollView: NSScrollView {
    private var displayLink: CADisplayLink?
    private var scrollSpeed: CGFloat = 0
    private var trackingArea: NSTrackingArea?

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        setupTrackingArea()
        updateDisplayLinkState()
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        setupTrackingArea()
    }

    private func setupTrackingArea() {
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    override func mouseMoved(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        let edgeZoneWidth: CGFloat = 120.0
        let maxEdgeSpeed: CGFloat = 38.0
        
        if location.x < edgeZoneWidth {
            let intensity = (edgeZoneWidth - location.x) / edgeZoneWidth
            scrollSpeed = -maxEdgeSpeed * intensity
        } else if location.x > bounds.width - edgeZoneWidth {
            let intensity = (location.x - (bounds.width - edgeZoneWidth)) / edgeZoneWidth
            scrollSpeed = maxEdgeSpeed * intensity
        } else {
            scrollSpeed = 0
        }
        
        updateDisplayLinkState()
    }

    override func mouseExited(with event: NSEvent) {
        scrollSpeed = 0
        updateDisplayLinkState()
    }

    override func scrollWheel(with event: NSEvent) {
        let deltaX = event.scrollingDeltaX != 0 ? event.scrollingDeltaX : event.deltaY * 10
        let deltaY = event.scrollingDeltaY != 0 ? event.scrollingDeltaY : event.deltaY * 10
        
        let effectiveDelta = abs(deltaX) > abs(deltaY) ? deltaX : deltaY
        
        var newOrigin = contentView.bounds.origin
        newOrigin.x -= effectiveDelta * 4.5

        if let docView = documentView {
            let maxX = docView.bounds.width - contentView.bounds.width
            newOrigin.x = max(0, min(newOrigin.x, max(0, maxX)))
        }

        contentView.scroll(to: newOrigin)
        reflectScrolledClipView(contentView)
    }

    // MARK: - Modern macOS 15+ DisplayLink Setup

    private func updateDisplayLinkState() {
        if #available(macOS 14.0, *) {
            if scrollSpeed != 0 {
                if displayLink == nil {
                    // Modern NSView CADisplayLink factory method
                    displayLink = self.displayLink(target: self, selector: #selector(stepEdgeScrollModern(_:)))
                    displayLink?.add(to: .main, forMode: .common)
                }
                displayLink?.isPaused = false
            } else {
                displayLink?.isPaused = true
            }
        } else {
            // Fallback for macOS 13 or earlier if deployment target requires legacy support
            stepEdgeScrollLegacy()
        }
    }

    @objc private func stepEdgeScrollModern(_ link: CADisplayLink) {
        performScrollStep()
    }

    private func stepEdgeScrollLegacy() {
        guard scrollSpeed != 0 else { return }
        performScrollStep()
        
        // Loop using main thread async if on older macOS versions
        DispatchQueue.main.asyncAfter(deadline: .now() + (1.0 / 60.0)) { [weak self] in
            self?.stepEdgeScrollLegacy()
        }
    }

    private func performScrollStep() {
        guard scrollSpeed != 0, let docView = documentView else { return }

        var newOrigin = contentView.bounds.origin
        newOrigin.x += scrollSpeed

        let maxX = docView.bounds.width - contentView.bounds.width
        newOrigin.x = max(0, min(newOrigin.x, max(0, maxX)))

        contentView.scroll(to: newOrigin)
        reflectScrolledClipView(contentView)
    }

    deinit {
        displayLink?.invalidate()
    }
}
