import Cocoa

class PetView: NSView {

    enum Direction: CaseIterable {
        case upLeft
        case upRight
        case downLeft
        case downRight
    }

    private let imageView = NSImageView()
    private var animationFrames: [Direction: [NSImage]] = [:]
    private var frameIndex = -1
    private var lastFrameSwitch: TimeInterval = 0
    private let frameInterval: TimeInterval = 0.12

    private var lastUpdateTime: TimeInterval = 0
    private var movementTimer: Timer?
    private var velocity = CGVector(dx: 140, dy: 140)

    private let walkFrameNames: [Direction: [String]] = [
        // Replace these placeholders with the names of your sprite frames in Assets.xcassets.
        // Example: walk_up_left_01, walk_up_left_02, ... etc.
        .upLeft: [
            "walk_up_left_01",
            "walk_up_left_02",
            "walk_up_left_03",
            "walk_up_left_04"
        ],
        .upRight: [
            "walk_up_right_01",
            "walk_up_right_02",
            "walk_up_right_03",
            "walk_up_right_04"
        ],
        .downLeft: [
            "walk_down_left_01",
            "walk_down_left_02",
            "walk_down_left_03",
            "walk_down_left_04",
            "walk_down_left_05",
            "walk_down_left_06",
            "walk_down_left_07",
            "walk_down_left_08",
            "walk_down_left_09",
            "walk_down_left_10",
            "walk_down_left_11",
            "walk_down_left_12",
            "walk_down_left_13",
            "walk_down_left_14",
            "walk_down_left_15",
            "walk_down_left_16",
            "walk_down_left_17",
            "walk_down_left_18",
            "walk_down_left_19",
            "walk_down_left_20",
            "walk_down_left_21",
            "walk_down_left_22"
        ],
        .downRight: [
            "walk_down_right_01",
            "walk_down_right_02",
            "walk_down_right_03",
            "walk_down_right_04",
            "walk_down_right_05",
            "walk_down_right_06",
            "walk_down_right_07",
            "walk_down_right_08",
            "walk_down_right_09",
            "walk_down_right_10",
            "walk_down_right_11",
            "walk_down_right_12",
            "walk_down_right_13",
            "walk_down_right_14",
            "walk_down_right_15",
            "walk_down_right_16",
            "walk_down_right_17",
            "walk_down_right_18",
            "walk_down_right_19",
            "walk_down_right_20",
            "walk_down_right_21",
            "walk_down_right_22"
        ]
    ]

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        setupImageView()
        loadAnimations()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        setupImageView()
        loadAnimations()
    }

    override func layout() {
        super.layout()
        imageView.frame = bounds
    }

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        startMovementIfNeeded()
    }

    override func viewWillMove(toSuperview newSuperview: NSView?) {
        if newSuperview == nil {
            movementTimer?.invalidate()
            movementTimer = nil
        }
        super.viewWillMove(toSuperview: newSuperview)
    }

    private func setupImageView() {
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.frame = bounds
        addSubview(imageView)
    }

    private func loadAnimations() {
        Direction.allCases.forEach { direction in
            let names = walkFrameNames[direction] ?? []
            let frames = names.enumerated().map { index, name in
                if let image = NSImage(named: name) {
                    return image
                }
                return placeholderImage(direction: direction, index: index + 1)
            }
            animationFrames[direction] = frames
        }
        updateAnimationFrame(for: currentDirection())
    }

    private func startMovementIfNeeded() {
        guard movementTimer == nil else { return }
        lastUpdateTime = CACurrentMediaTime()
        lastFrameSwitch = lastUpdateTime
        movementTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        let now = CACurrentMediaTime()
        let delta = now - lastUpdateTime
        lastUpdateTime = now
        updatePosition(deltaTime: delta)
        updateAnimationIfNeeded(currentTime: now)
    }

    private func updatePosition(deltaTime: TimeInterval) {
        guard let container = superview else { return }

        var newFrame = frame
        newFrame.origin.x += velocity.dx * deltaTime
        newFrame.origin.y += velocity.dy * deltaTime

        let bounds = container.bounds
        let maxX = bounds.maxX - newFrame.width
        let maxY = bounds.maxY - newFrame.height

        if newFrame.origin.x <= bounds.minX {
            newFrame.origin.x = bounds.minX
            velocity.dx = abs(velocity.dx)
        } else if newFrame.origin.x >= maxX {
            newFrame.origin.x = maxX
            velocity.dx = -abs(velocity.dx)
        }

        if newFrame.origin.y <= bounds.minY {
            newFrame.origin.y = bounds.minY
            velocity.dy = abs(velocity.dy)
        } else if newFrame.origin.y >= maxY {
            newFrame.origin.y = maxY
            velocity.dy = -abs(velocity.dy)
        }

        frame = newFrame
    }

    private func updateAnimationIfNeeded(currentTime: TimeInterval) {
        guard currentTime - lastFrameSwitch >= frameInterval else { return }
        lastFrameSwitch = currentTime
        updateAnimationFrame(for: currentDirection())
    }

    private func updateAnimationFrame(for direction: Direction) {
        guard let frames = animationFrames[direction], !frames.isEmpty else { return }
        frameIndex = (frameIndex + 1) % frames.count
        imageView.image = frames[frameIndex]
    }

    private func currentDirection() -> Direction {
        if velocity.dx >= 0 && velocity.dy >= 0 {
            return .upRight
        }
        if velocity.dx < 0 && velocity.dy >= 0 {
            return .upLeft
        }
        if velocity.dx >= 0 && velocity.dy < 0 {
            return .downRight
        }
        return .downLeft
    }

    private func placeholderImage(direction: Direction, index: Int) -> NSImage {
        let size = bounds.size == .zero ? NSSize(width: 80, height: 80) : bounds.size
        let image = NSImage(size: size)
        image.lockFocus()
        let rect = NSRect(origin: .zero, size: size)
        NSColor.systemPink.setFill()
        rect.fill()

        let label = "\(directionLabel(direction)) \(index)"
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.white,
            .font: NSFont.boldSystemFont(ofSize: 12)
        ]
        let textSize = label.size(withAttributes: attributes)
        let textOrigin = NSPoint(
            x: (size.width - textSize.width) / 2.0,
            y: (size.height - textSize.height) / 2.0
        )
        label.draw(at: textOrigin, withAttributes: attributes)
        image.unlockFocus()
        return image
    }

    private func directionLabel(_ direction: Direction) -> String {
        switch direction {
        case .upLeft:
            return "↖︎"
        case .upRight:
            return "↗︎"
        case .downLeft:
            return "↙︎"
        case .downRight:
            return "↘︎"
        }
    }
}
