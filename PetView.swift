import Cocoa

class PetView: NSView {

    enum Direction: CaseIterable {
        case upLeft
        case upRight
        case downLeft
        case downRight
    }

    private let imageView = NSImageView()
    private let shadowImageView = NSImageView()
    private enum AnimationState {
        case walking
        case sitTransition
        case sitting
    }

    private var walkFrames: [Direction: [NSImage]] = [:]
    private var sitTransitionFrames: [Direction: [NSImage]] = [:]
    private var sitIdleFrames: [Direction: [NSImage]] = [:]
    private var frameIndex = -1
    private var lastFrameSwitch: TimeInterval = 0
    private let walkFrameInterval: TimeInterval = 0.03
    private let sitTransitionInterval: TimeInterval = 0.06
    private let sitIdleInterval: TimeInterval = 0.12

    private var lastUpdateTime: TimeInterval = 0
    private var movementTimer: Timer?

    private var velocity = CGVector(dx: 100, dy: 100)

    private var isMoving = true
    private var nextStateChangeTime: TimeInterval = 0
    private var animationState: AnimationState = .walking
    private var lastDirection: Direction = .downLeft
    private let moveDurationRange: ClosedRange<TimeInterval> = 2.0...4.5
    private let restDurationRange: ClosedRange<TimeInterval> = 2.5...5.5

    private let walkFrameNames: [Direction: [String]] = [
        // Replace these placeholders with the names of your sprite frames in Assets.xcassets.
        // Example: walk_up_left_01, walk_up_left_02, ... etc.
        .upLeft: [
            "walk_up_left_01",
            "walk_up_left_02",
            "walk_up_left_03",
            "walk_up_left_04",
            "walk_up_left_05",
            "walk_up_left_06",
            "walk_up_left_07",
            "walk_up_left_08",
            "walk_up_left_09",
            "walk_up_left_10",
            "walk_up_left_11",
            "walk_up_left_12",
            "walk_up_left_13",
            "walk_up_left_14",
            "walk_up_left_15",
            "walk_up_left_16",
            "walk_up_left_17",
            "walk_up_left_18",
            "walk_up_left_19",
            "walk_up_left_20",
            "walk_up_left_21",
            "walk_up_left_22",
            "walk_up_left_23",
            "walk_up_left_24",
            "walk_up_left_25",
            "walk_up_left_26",
            "walk_up_left_27",
            "walk_up_left_28",
            "walk_up_left_29",
            "walk_up_left_30",
            "walk_up_left_31",
            "walk_up_left_32",
            "walk_up_left_33",
            "walk_up_left_34",
            "walk_up_left_35",
            "walk_up_left_36",
            "walk_up_left_37",
            "walk_up_left_38",
            "walk_up_left_39",
            "walk_up_left_40",
            "walk_up_left_41",
            "walk_up_left_42",
            "walk_up_left_43",
            "walk_up_left_44",
            "walk_up_left_45",
            "walk_up_left_46",
            "walk_up_left_47",
            "walk_up_left_48",
            "walk_up_left_49",
            "walk_up_left_50",
            "walk_up_left_51",
            "walk_up_left_52",
            "walk_up_left_53",
            "walk_up_left_54",
            "walk_up_left_55",
            "walk_up_left_56",
            "walk_up_left_57",
            "walk_up_left_58",
            "walk_up_left_59",
            "walk_up_left_60",
            "walk_up_left_61",
            "walk_up_left_62",
            "walk_up_left_63",
            "walk_up_left_64",
            "walk_up_left_65",
            "walk_up_left_66"
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
        ]
    ]
    private let sitTransitionFrameNames: [Direction: [String]] = [
        // Replace these placeholders with the names of your sit transition frames.
        // Sitting only uses the down direction, so only include down-facing frames.
        .downLeft: [
            "sit_transition_down_left_01",
            "sit_transition_down_left_02",
            "sit_transition_down_left_03",
            "sit_transition_down_left_04",
            "sit_transition_down_left_05",
            "sit_transition_down_left_06"
        ]
    ]
    private let sitIdleFrameNames: [Direction: [String]] = [
        // Replace these placeholders with the names of your seated idle frames.
        // Sitting only uses the down direction, so only include down-facing frames.
        .downLeft: [
            "sit_idle_down_left_01",
            "sit_idle_down_left_02",
            "sit_idle_down_left_03",
            "sit_idle_down_left_04"
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
        layoutShadow()
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
        shadowImageView.image = NSImage(named: "shadow")
        shadowImageView.imageScaling = .scaleProportionallyUpOrDown
        shadowImageView.frame = bounds
        addSubview(shadowImageView)

        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.frame = bounds
        addSubview(imageView)
    }

    private func layoutShadow() {
        guard let image = shadowImageView.image else {
            shadowImageView.frame = bounds
            return
        }
        let targetWidth = bounds.width * 0.9
        let scale = targetWidth / max(image.size.width, 1)
        let targetHeight = image.size.height * scale
        let originX = (bounds.width - targetWidth) / 2.0
        let originY = bounds.minY + 2.0
        shadowImageView.frame = NSRect(
            x: originX,
            y: originY,
            width: targetWidth,
            height: targetHeight
        )
    }

    private func loadAnimations() {
        Direction.allCases.forEach { direction in
            walkFrames[direction] = loadFrames(for: direction, namesByDirection: walkFrameNames)
            sitTransitionFrames[direction] = loadFrames(for: direction, namesByDirection: sitTransitionFrameNames)
            sitIdleFrames[direction] = loadFrames(for: direction, namesByDirection: sitIdleFrameNames)
        }
        updateAnimationFrame(for: lastDirection)
    }

    private func loadFrames(for direction: Direction, namesByDirection: [Direction: [String]]) -> [NSImage] {
        if let mirroredSource = mirroredDirection(for: direction),
           let names = namesByDirection[mirroredSource] {
            return names.enumerated().map { index, name in
                if let image = NSImage(named: name) {
                    return flippedImageHorizontally(image)
                }
                return placeholderImage(direction: direction, index: index + 1)
            }
        }

        let names = namesByDirection[direction] ?? []
        return names.enumerated().map { index, name in
            if let image = NSImage(named: name) {
                return image
            }
            return placeholderImage(direction: direction, index: index + 1)
        }
    }

    private func startMovementIfNeeded() {
        guard movementTimer == nil else { return }
        lastUpdateTime = CACurrentMediaTime()
        lastFrameSwitch = lastUpdateTime
        nextStateChangeTime = lastUpdateTime + Double.random(in: moveDurationRange)
        movementTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        let now = CACurrentMediaTime()
        let delta = now - lastUpdateTime
        lastUpdateTime = now
        updateMovementState(currentTime: now)
        if isMoving {
            updatePosition(deltaTime: delta)
        }
        updateAnimationIfNeeded(currentTime: now)
    }

    private func updateMovementState(currentTime: TimeInterval) {
        guard currentTime >= nextStateChangeTime else { return }
        if isMoving {
            isMoving = false
            animationState = .sitTransition
            frameIndex = -1
            nextStateChangeTime = currentTime + Double.random(in: restDurationRange)
        } else {
            isMoving = true
            animationState = .walking
            frameIndex = -1
            pickNewVelocity()
            nextStateChangeTime = currentTime + Double.random(in: moveDurationRange)
        }
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
        lastDirection = currentDirection()
    }

    private func updateAnimationIfNeeded(currentTime: TimeInterval) {
        let interval = animationInterval(for: animationState)
        guard currentTime - lastFrameSwitch >= interval else { return }
        lastFrameSwitch = currentTime
        updateAnimationFrame(for: animationDirection())
    }

    private func updateAnimationFrame(for direction: Direction) {
        let frames = animationFrames(for: direction, state: animationState)
        guard !frames.isEmpty else { return }
        frameIndex += 1
        if frameIndex >= frames.count {
            if animationState == .sitTransition {
                animationState = .sitting
                frameIndex = 0
                imageView.image = sitIdleFrames[direction]?.first
                return
            }
            frameIndex = 0
        }
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

    private func animationInterval(for state: AnimationState) -> TimeInterval {
        switch state {
        case .walking:
            return walkFrameInterval
        case .sitTransition:
            return sitTransitionInterval
        case .sitting:
            return sitIdleInterval
        }
    }

    private func animationDirection() -> Direction {
        switch animationState {
        case .walking:
            return lastDirection
        case .sitTransition, .sitting:
            return .downLeft
        }
    }

    private func animationFrames(for direction: Direction, state: AnimationState) -> [NSImage] {
        switch state {
        case .walking:
            return walkFrames[direction] ?? []
        case .sitTransition:
            return sitTransitionFrames[direction] ?? []
        case .sitting:
            return sitIdleFrames[direction] ?? []
        }
    }

    private func pickNewVelocity() {
        let speedRange: ClosedRange<CGFloat> = 120...180
        let speed = CGFloat.random(in: speedRange)
        let component = speed / sqrt(2)
        let directions: [(CGFloat, CGFloat)] = [
            (component, component),
            (component, -component),
            (-component, component),
            (-component, -component)
        ]
        let selected = directions.randomElement() ?? (component, component)
        velocity = CGVector(dx: selected.0, dy: selected.1)
        lastDirection = currentDirection()
    }

    private func placeholderImage(direction: Direction, index: Int) -> NSImage {
        let size = bounds.size == .zero ? NSSize(width: 80, height: 80) : bounds.size
        let image = NSImage(size: size)
        image.lockFocus()
        let rect = NSRect(origin: .zero, size: size)
        NSColor.clear.setFill()
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

    private func mirroredDirection(for direction: Direction) -> Direction? {
        switch direction {
        case .upRight:
            return .upLeft
        case .downRight:
            return .downLeft
        default:
            return nil
        }
    }

    private func flippedImageHorizontally(_ image: NSImage) -> NSImage {
        let size = image.size
        let flipped = NSImage(size: size)
        flipped.lockFocus()
        if let context = NSGraphicsContext.current?.cgContext {
            context.translateBy(x: size.width, y: 0)
            context.scaleBy(x: -1, y: 1)
        }
        image.draw(
            at: .zero,
            from: NSRect(origin: .zero, size: size),
            operation: .sourceOver,
            fraction: 1.0
        )
        flipped.unlockFocus()
        return flipped
    }
}
