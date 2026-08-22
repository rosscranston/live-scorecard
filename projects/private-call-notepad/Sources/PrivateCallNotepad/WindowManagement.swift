import AppKit
import Carbon.HIToolbox
import SwiftUI

enum WindowTransparency {
    static let preferenceKey = "private-notepad.window-transparency"
    static let defaultValue = 0.10
    static let maximumValue = 0.75

    static func sanitized(_ transparency: Double) -> Double {
        min(max(transparency, 0), maximumValue)
    }

    @MainActor
    static func apply(to window: NSWindow, transparency: Double) {
        window.alphaValue = CGFloat(1 - sanitized(transparency))
    }
}

enum PrivateWindowPolicy {
    @MainActor
    static func apply(to window: NSWindow) {
        // Defense in depth only. Apple now documents NSWindowSharingNone as a
        // legacy hint, so the user must share a single app/window, not a display.
        window.sharingType = .none
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.isMovableByWindowBackground = true
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.backgroundColor = .black
        window.isOpaque = false
        window.hasShadow = true
        window.minSize = NSSize(width: 280, height: 360)
        window.standardWindowButton(.zoomButton)?.isHidden = true
    }
}

enum WindowPosition: Int, CaseIterable, Identifiable {
    case bottomLeft = 1
    case bottomCenter = 2
    case bottomRight = 3
    case middleLeft = 4
    case center = 5
    case middleRight = 6
    case topLeft = 7
    case topCenter = 8
    case topRight = 9

    var id: Int { rawValue }

    static let gridOrder: [WindowPosition] = [
        .topLeft, .topCenter, .topRight,
        .middleLeft, .center, .middleRight,
        .bottomLeft, .bottomCenter, .bottomRight
    ]

    var label: String {
        switch self {
        case .bottomLeft: return "BOTTOM LEFT"
        case .bottomCenter: return "BOTTOM CENTER"
        case .bottomRight: return "BOTTOM RIGHT"
        case .middleLeft: return "MIDDLE LEFT"
        case .center: return "CENTER"
        case .middleRight: return "MIDDLE RIGHT"
        case .topLeft: return "TOP LEFT"
        case .topCenter: return "TOP CENTER"
        case .topRight: return "TOP RIGHT"
        }
    }

    var symbolName: String {
        switch self {
        case .bottomLeft: return "arrow.down.left"
        case .bottomCenter: return "arrow.down"
        case .bottomRight: return "arrow.down.right"
        case .middleLeft: return "arrow.left"
        case .center: return "circle"
        case .middleRight: return "arrow.right"
        case .topLeft: return "arrow.up.left"
        case .topCenter: return "arrow.up"
        case .topRight: return "arrow.up.right"
        }
    }

    var shortcutLabel: String {
        "⌃⌥\(rawValue)"
    }
}

enum WindowLayout {
    static let margin: CGFloat = 12

    static func frame(
        for position: WindowPosition,
        windowSize: NSSize,
        visibleFrame: NSRect
    ) -> NSRect {
        let usableWidth = max(1, visibleFrame.width - (margin * 2))
        let usableHeight = max(1, visibleFrame.height - (margin * 2))
        let size = NSSize(
            width: min(max(1, windowSize.width), usableWidth),
            height: min(max(1, windowSize.height), usableHeight)
        )

        let left = visibleFrame.minX + margin
        let centerX = visibleFrame.midX - (size.width / 2)
        let right = visibleFrame.maxX - size.width - margin
        let bottom = visibleFrame.minY + margin
        let middleY = visibleFrame.midY - (size.height / 2)
        let top = visibleFrame.maxY - size.height - margin

        let origin: NSPoint
        switch position {
        case .bottomLeft: origin = NSPoint(x: left, y: bottom)
        case .bottomCenter: origin = NSPoint(x: centerX, y: bottom)
        case .bottomRight: origin = NSPoint(x: right, y: bottom)
        case .middleLeft: origin = NSPoint(x: left, y: middleY)
        case .center: origin = NSPoint(x: centerX, y: middleY)
        case .middleRight: origin = NSPoint(x: right, y: middleY)
        case .topLeft: origin = NSPoint(x: left, y: top)
        case .topCenter: origin = NSPoint(x: centerX, y: top)
        case .topRight: origin = NSPoint(x: right, y: top)
        }

        return NSRect(origin: origin, size: size)
    }
}

enum WindowFramePersistence {
    static let preferenceKey = "private-notepad.window-frame"

    static func encode(_ frame: NSRect) -> String {
        NSStringFromRect(frame)
    }

    static func decode(_ value: String?) -> NSRect? {
        guard let value, !value.isEmpty else { return nil }
        let frame = NSRectFromString(value)
        guard frame.width >= 1, frame.height >= 1 else { return nil }
        return frame
    }

    static func isUsable(_ frame: NSRect, on visibleFrames: [NSRect]) -> Bool {
        visibleFrames.contains { visibleFrame in
            let intersection = frame.intersection(visibleFrame)
            return intersection.width >= 80 && intersection.height >= 60
        }
    }
}

@MainActor
final class FloatingWindowController: ObservableObject {
    @Published private(set) var currentPosition: WindowPosition
    @Published private(set) var globalShortcutsAvailable = false
    @Published private(set) var transparency: Double

    private weak var window: NSWindow?
    private var didApplyInitialPosition = false
    private var frameObserverTokens: [NSObjectProtocol] = []
    private let defaults: UserDefaults

    private lazy var hotKeyManager = GlobalHotKeyManager { [weak self] position in
        DispatchQueue.main.async {
            self?.snap(to: position)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let savedPosition = defaults.integer(forKey: "private-notepad.window-position")
        currentPosition = WindowPosition(rawValue: savedPosition) ?? .topLeft

        let storedTransparency: Double
        if defaults.object(forKey: WindowTransparency.preferenceKey) == nil {
            storedTransparency = WindowTransparency.defaultValue
        } else {
            storedTransparency = defaults.double(forKey: WindowTransparency.preferenceKey)
        }
        transparency = WindowTransparency.sanitized(storedTransparency)
    }

    func attach(window: NSWindow) {
        let isNewWindow = self.window !== window
        self.window = window
        PrivateWindowPolicy.apply(to: window)
        WindowTransparency.apply(to: window, transparency: transparency)

        if isNewWindow {
            observeFrameChanges(for: window)
            globalShortcutsAvailable = hotKeyManager.start()
        }

        guard !didApplyInitialPosition else { return }
        didApplyInitialPosition = true
        let savedFrame = WindowFramePersistence.decode(
            defaults.string(forKey: WindowFramePersistence.preferenceKey)
        )
        let visibleFrames = NSScreen.screens.map(\.visibleFrame)
        if let savedFrame,
           WindowFramePersistence.isUsable(savedFrame, on: visibleFrames) {
            window.setFrame(savedFrame, display: true)
        } else if WindowFramePersistence.isUsable(window.frame, on: visibleFrames) {
            persistFrame(window)
        } else {
            snap(to: currentPosition, animate: false)
        }
    }

    func setTransparency(_ value: Double) {
        let sanitized = WindowTransparency.sanitized(value)
        transparency = sanitized
        defaults.set(sanitized, forKey: WindowTransparency.preferenceKey)
        if let window {
            WindowTransparency.apply(to: window, transparency: sanitized)
        }
    }

    func snap(to position: WindowPosition, animate: Bool = true) {
        guard let window else { return }
        let screen = resolvedScreen(for: window)
        let target = WindowLayout.frame(
            for: position,
            windowSize: window.frame.size,
            visibleFrame: screen.visibleFrame
        )
        window.setFrame(target, display: true, animate: animate)
        persistFrame(window)
        currentPosition = position
        defaults.set(position.rawValue, forKey: "private-notepad.window-position")
    }

    func resetLayout() {
        setTransparency(WindowTransparency.defaultValue)
        snap(to: .topLeft)
    }

    private func resolvedScreen(for window: NSWindow) -> NSScreen {
        if let screen = window.screen { return screen }
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) })
            ?? NSScreen.main
            ?? NSScreen.screens[0]
    }

    private func observeFrameChanges(for window: NSWindow) {
        frameObserverTokens.forEach(NotificationCenter.default.removeObserver)
        frameObserverTokens = [
            NSWindow.didMoveNotification,
            NSWindow.didResizeNotification,
            NSWindow.willCloseNotification
        ].map { name in
            NotificationCenter.default.addObserver(
                forName: name,
                object: window,
                queue: .main
            ) { [weak self, weak window] _ in
                Task { @MainActor in
                    if let window {
                        self?.persistFrame(window)
                    }
                }
            }
        }
    }

    private func persistFrame(_ window: NSWindow) {
        defaults.set(
            WindowFramePersistence.encode(window.frame),
            forKey: WindowFramePersistence.preferenceKey
        )
    }
}

struct WindowAccessor: NSViewRepresentable {
    @ObservedObject var controller: FloatingWindowController

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                controller.attach(window: window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                controller.attach(window: window)
            }
        }
    }
}

private final class GlobalHotKeyManager {
    private static let signature: OSType = 0x50434E50 // PCNP

    private let action: (WindowPosition) -> Void
    private var eventHandler: EventHandlerRef?
    private var hotKeyReferences: [EventHotKeyRef] = []
    private var started = false

    init(action: @escaping (WindowPosition) -> Void) {
        self.action = action
    }

    deinit {
        stop()
    }

    func start() -> Bool {
        guard !started else { return hotKeyReferences.count == WindowPosition.allCases.count }
        started = true

        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<GlobalHotKeyManager>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                var identifier = EventHotKeyID()
                let result = GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &identifier
                )
                guard result == noErr,
                      let position = WindowPosition(rawValue: Int(identifier.id)) else {
                    return OSStatus(eventNotHandledErr)
                }
                manager.action(position)
                return noErr
            },
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandler
        )

        guard status == noErr else { return false }

        let keyCodes: [WindowPosition: UInt32] = [
            .bottomLeft: UInt32(kVK_ANSI_1),
            .bottomCenter: UInt32(kVK_ANSI_2),
            .bottomRight: UInt32(kVK_ANSI_3),
            .middleLeft: UInt32(kVK_ANSI_4),
            .center: UInt32(kVK_ANSI_5),
            .middleRight: UInt32(kVK_ANSI_6),
            .topLeft: UInt32(kVK_ANSI_7),
            .topCenter: UInt32(kVK_ANSI_8),
            .topRight: UInt32(kVK_ANSI_9)
        ]

        for position in WindowPosition.allCases {
            guard let keyCode = keyCodes[position] else { continue }
            var reference: EventHotKeyRef?
            let identifier = EventHotKeyID(
                signature: Self.signature,
                id: UInt32(position.rawValue)
            )
            let registerStatus = RegisterEventHotKey(
                keyCode,
                UInt32(controlKey | optionKey),
                identifier,
                GetApplicationEventTarget(),
                0,
                &reference
            )
            if registerStatus == noErr, let reference {
                hotKeyReferences.append(reference)
            }
        }

        return hotKeyReferences.count == WindowPosition.allCases.count
    }

    private func stop() {
        hotKeyReferences.forEach { UnregisterEventHotKey($0) }
        hotKeyReferences.removeAll()
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
    }
}
