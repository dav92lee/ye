import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let screen = NSScreen.main!.frame

        window = NSWindow(
            contentRect: screen,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.ignoresMouseEvents = true
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary
        ]

        window.makeKeyAndOrderFront(nil)
        
        let petSize: CGFloat = 80

        let petView = PetView(frame: NSRect(
            x: 200,
            y: 200,
            width: petSize,
            height: petSize
        ))

        window.contentView = NSView(frame: screen)
        window.contentView?.wantsLayer = true
        window.contentView?.addSubview(petView)
    }
}
