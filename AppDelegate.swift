import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!
    private var statusItem: NSStatusItem?

    
    func isDarkMode() -> Bool {
        if #available(macOS 10.14, *) {
            let appearance = NSApp.effectiveAppearance
            return appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        }
        return false
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: 18)
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
}
