import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!
    private var statusItem: NSStatusItem?
    private var moodIndicator: NSProgressIndicator?
    private var rootView: SnackOverlayView?
    private var snackCursor: NSCursor?
    private var moodLevel: Double = 0.5 {
        didSet {
            updateMoodUI()
        }
    }

    
    func isDarkMode() -> Bool {
        if #available(macOS 10.14, *) {
            let appearance = NSApp.effectiveAppearance
            return appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        }
        return false
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {

            let imageName = isDarkMode()
                ? "status-icon-white"
                : "status-icon-black"

            if let image = NSImage(named: imageName) {
                image.isTemplate = false
                button.image = image
            }

            button.imagePosition = .imageOnly
        }

        statusItem?.menu = buildStatusMenu()

        let screenFrame = NSScreen.main?.frame ?? .zero

        // 1) Full-screen transparent overlay window
        window = NSWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = .floating
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // 2) Clear root view that covers the screen
        let root = SnackOverlayView(frame: screenFrame)
        root.wantsLayer = true
        root.layer?.backgroundColor = NSColor.clear.cgColor
        root.onSnackPlacement = { [weak self] point in
            self?.placeSnack(at: point)
        }
        rootView = root
        window.contentView = root

        // 3) Small pet view (pink square)
        let petSize: CGFloat = 80
        let pet = PetView(frame: NSRect(x: 200, y: 200, width: petSize, height: petSize))
        pet.wantsLayer = true

        root.addSubview(pet)

        window.makeKeyAndOrderFront(nil)
        
        for existingWindow in NSApp.windows where existingWindow !== window {
            existingWindow.orderOut(nil)
        }
    }

    private func buildStatusMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(makeMoodMenuItem())
        menu.addItem(.separator())

        let snackItem = NSMenuItem(title: "Snack", action: #selector(handleSnack), keyEquivalent: "")
        snackItem.target = self
        menu.addItem(snackItem)

        let feedItem = NSMenuItem(title: "Feed", action: #selector(handleFeed), keyEquivalent: "")
        feedItem.target = self
        menu.addItem(feedItem)

        let petItem = NSMenuItem(title: "Pet", action: #selector(handlePet), keyEquivalent: "")
        petItem.target = self
        menu.addItem(petItem)

        return menu
    }

    private func makeMoodMenuItem() -> NSMenuItem {
        let menuItem = NSMenuItem()
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 200, height: 28))

        let label = NSTextField(labelWithString: "Mood")
        label.font = NSFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = NSColor.secondaryLabelColor
        label.frame = NSRect(x: 8, y: 6, width: 48, height: 16)

        let indicator = NSProgressIndicator()
        indicator.isIndeterminate = false
        indicator.minValue = 0
        indicator.maxValue = 100
        indicator.controlSize = .small
        indicator.style = .bar
        indicator.frame = NSRect(x: 60, y: 7, width: 128, height: 12)

        container.addSubview(label)
        container.addSubview(indicator)

        menuItem.view = container
        moodIndicator = indicator
        updateMoodUI()
        return menuItem
    }

    private func updateMoodUI() {
        let clamped = min(max(moodLevel, 0.0), 1.0)
        moodIndicator?.doubleValue = clamped * 100.0
    }

    @objc private func handleSnack() {
        adjustMood(by: 0.1)
        beginSnackPlacement()
    }

    @objc private func handleFeed() {
        adjustMood(by: 0.2)
    }

    @objc private func handlePet() {
        adjustMood(by: 0.15)
    }

    private func adjustMood(by delta: Double) {
        moodLevel = min(max(moodLevel + delta, 0.0), 1.0)
    }
}

private final class SnackOverlayView: NSView {
    var onSnackPlacement: ((NSPoint) -> Void)?
    var snackCursor: NSCursor?
    var isSnackPlacementEnabled = false {
        didSet {
            if isSnackPlacementEnabled != oldValue {
                window?.ignoresMouseEvents = !isSnackPlacementEnabled
                window?.invalidateCursorRects(for: self)
                if !isSnackPlacementEnabled {
                    NSCursor.arrow.set()
                }
            }
        }
    }

    override func mouseDown(with event: NSEvent) {
        guard isSnackPlacementEnabled else {
            super.mouseDown(with: event)
            return
        }
        let location = convert(event.locationInWindow, from: nil)
        onSnackPlacement?(location)
        isSnackPlacementEnabled = false
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        guard isSnackPlacementEnabled, let cursor = snackCursor else { return }
        addCursorRect(bounds, cursor: cursor)
        cursor.set()
    }
}

private extension AppDelegate {
    func beginSnackPlacement() {
        guard let rootView = rootView else { return }
        if snackCursor == nil {
            snackCursor = makeSnackCursor()
        }
        rootView.snackCursor = snackCursor
        rootView.isSnackPlacementEnabled = true
        snackCursor?.set()
    }

    func makeSnackCursor() -> NSCursor? {
        guard let image = NSImage(named: "carrot") else { return nil }
        let hotSpot = NSPoint(x: image.size.width / 2.0, y: image.size.height / 2.0)
        return NSCursor(image: image, hotSpot: hotSpot)
    }

    func placeSnack(at point: NSPoint) {
        guard let rootView = rootView, let image = NSImage(named: "carrot") else { return }
        let maxDimension: CGFloat = 40
        let scale = maxDimension / max(image.size.width, image.size.height, 1.0)
        let size = NSSize(width: image.size.width * scale, height: image.size.height * scale)
        let originX = min(max(point.x - size.width / 2.0, 0), rootView.bounds.width - size.width)
        let originY = min(max(point.y - size.height / 2.0, 0), rootView.bounds.height - size.height)

        let imageView = NSImageView(frame: NSRect(origin: NSPoint(x: originX, y: originY), size: size))
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        rootView.addSubview(imageView)
    }
}
