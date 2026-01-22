import Cocoa

class PetView: NSView {

    override func draw(_ dirtyRect: NSRect) {
        NSColor.systemPink.setFill()
        dirtyRect.fill()
    }
}
