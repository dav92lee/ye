import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
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
        pet.layer?.backgroundColor = NSColor.systemPink.cgColor
        pet.layer?.cornerRadius = 12

        root.addSubview(pet)

        window.makeKeyAndOrderFront(nil)
    }
}
