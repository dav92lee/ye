import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!
    private var statusItem: NSStatusItem?
    private var moodIndicator: NSProgressIndicator?
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
        let root = NSView(frame: screenFrame)
        root.wantsLayer = true
        root.layer?.backgroundColor = NSColor.clear.cgColor
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
