import AppKit
import Carbon.HIToolbox
import SwiftUI

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

    var shortcutLabel: String { "⌃⌥\(rawValue)" }
}

enum TaxTermsWindowLayout {
    static let margin: CGFloat = 12
    static let widthRatio: CGFloat = 0.25
    static let heightRatio: CGFloat = 0.40
    static let minimumSize = NSSize(width: 340, height: 320)

    static func defaultSize(visibleFrame: NSRect) -> NSSize {
        NSSize(
            width: max(minimumSize.width, (visibleFrame.width * widthRatio).rounded()),
            height: max(minimumSize.height, (visibleFrame.height * heightRatio).rounded())
        )
    }

    static func frame(
        for position: WindowPosition,
        windowSize: NSSize,
        visibleFrame: NSRect
    ) -> NSRect {
        let usableWidth = max(1, visibleFrame.width - margin * 2)
        let usableHeight = max(1, visibleFrame.height - margin * 2)
        let size = NSSize(
            width: min(max(minimumSize.width, windowSize.width), usableWidth),
            height: min(max(minimumSize.height, windowSize.height), usableHeight)
        )
        let xValues = [
            visibleFrame.minX + margin,
            visibleFrame.midX - size.width / 2,
            visibleFrame.maxX - size.width - margin
        ]
        let yValues = [
            visibleFrame.minY + margin,
            visibleFrame.midY - size.height / 2,
            visibleFrame.maxY - size.height - margin
        ]

        let grid: (Int, Int)
        switch position {
        case .bottomLeft: grid = (0, 0)
        case .bottomCenter: grid = (1, 0)
        case .bottomRight: grid = (2, 0)
        case .middleLeft: grid = (0, 1)
        case .center: grid = (1, 1)
        case .middleRight: grid = (2, 1)
        case .topLeft: grid = (0, 2)
        case .topCenter: grid = (1, 2)
        case .topRight: grid = (2, 2)
        }
        return NSRect(x: xValues[grid.0], y: yValues[grid.1], width: size.width, height: size.height)
    }
}

@MainActor
final class FloatingWindowController: ObservableObject {
    @Published private(set) var currentPosition: WindowPosition = .topRight
    @Published private(set) var globalShortcutsAvailable = false
    @Published var privacyCurtain = false
    @Published private(set) var transparency: Double = 0
    @Published private(set) var alwaysOnTop = true

    private weak var window: NSWindow?
    private var frameObservers: [NSObjectProtocol] = []
    private var didApplyInitialFrame = false
    private let defaults = UserDefaults.standard

    private lazy var hotKeyManager = GlobalHotKeyManager { [weak self] action in
        Task { @MainActor in
            switch action {
            case .position(let position): self?.snap(to: position)
            case .privacy: self?.togglePrivacyCurtain()
            }
        }
    }

    func attach(window: NSWindow, settings: AppSettings) {
        let isNew = self.window !== window
        self.window = window
        applyPolicy(to: window)
        apply(settings: settings)
        if isNew {
            observeFrameChanges(window)
            globalShortcutsAvailable = hotKeyManager.start()
        }
        guard !didApplyInitialFrame else { return }
        didApplyInitialFrame = true

        if let saved = decodeFrame(defaults.string(forKey: "tax-terms.window-frame")),
           NSScreen.screens.contains(where: { $0.visibleFrame.intersects(saved) }) {
            window.setFrame(saved, display: true)
        } else {
            resetLayout()
        }
    }

    func apply(settings: AppSettings) {
        transparency = min(max(settings.transparency, 0), 0.60)
        alwaysOnTop = settings.alwaysOnTop
        guard let window else { return }
        window.alphaValue = CGFloat(1 - transparency)
        window.level = alwaysOnTop ? .floating : .normal
    }

    func snap(to position: WindowPosition, animate: Bool = true) {
        guard let window, let screen = resolvedScreen(for: window) else { return }
        let frame = TaxTermsWindowLayout.frame(
            for: position,
            windowSize: window.frame.size,
            visibleFrame: screen.visibleFrame
        )
        window.setFrame(frame, display: true, animate: animate)
        currentPosition = position
        persistFrame(window)
    }

    func resetLayout() {
        guard let window, let screen = resolvedScreen(for: window) else { return }
        let frame = TaxTermsWindowLayout.frame(
            for: .topRight,
            windowSize: TaxTermsWindowLayout.defaultSize(visibleFrame: screen.visibleFrame),
            visibleFrame: screen.visibleFrame
        )
        window.setFrame(frame, display: true, animate: true)
        currentPosition = .topRight
        persistFrame(window)
    }

    func togglePrivacyCurtain() {
        privacyCurtain.toggle()
        if privacyCurtain { window?.makeKeyAndOrderFront(nil) }
    }

    func setPrivacyCurtain(_ active: Bool) {
        privacyCurtain = active
    }

    private func applyPolicy(to window: NSWindow) {
        // Legacy, best-effort capture hint only. Apple does not guarantee capture exclusion.
        // Demo mode deliberately remains capturable so release visual QA can inspect
        // the real window. Normal launches always apply the privacy hint.
        if ProcessInfo.processInfo.environment["TAX_TERMS_DEMO"] != "1" {
            window.sharingType = .none
        }
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.isMovableByWindowBackground = true
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isOpaque = false
        window.hasShadow = true
        window.minSize = TaxTermsWindowLayout.minimumSize
        window.standardWindowButton(.zoomButton)?.isHidden = true
    }

    private func resolvedScreen(for window: NSWindow) -> NSScreen? {
        window.screen
            ?? NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) })
            ?? NSScreen.main
    }

    private func observeFrameChanges(_ window: NSWindow) {
        frameObservers.forEach(NotificationCenter.default.removeObserver)
        frameObservers = [NSWindow.didMoveNotification, NSWindow.didResizeNotification].map { name in
            NotificationCenter.default.addObserver(
                forName: name,
                object: window,
                queue: .main
            ) { [weak self, weak window] _ in
                Task { @MainActor in
                    if let window { self?.persistFrame(window) }
                }
            }
        }
    }

    private func persistFrame(_ window: NSWindow) {
        let f = window.frame
        defaults.set("\(f.origin.x),\(f.origin.y),\(f.size.width),\(f.size.height)", forKey: "tax-terms.window-frame")
    }

    private func decodeFrame(_ value: String?) -> NSRect? {
        guard let values = value?.split(separator: ",").compactMap({ Double($0) }), values.count == 4 else {
            return nil
        }
        return NSRect(x: values[0], y: values[1], width: values[2], height: values[3])
    }
}

struct WindowAccessor: NSViewRepresentable {
    @ObservedObject var controller: FloatingWindowController
    let settings: AppSettings

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window { controller.attach(window: window, settings: settings) }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window { controller.attach(window: window, settings: settings) }
        }
    }
}

private enum GlobalHotKeyAction {
    case position(WindowPosition)
    case privacy
}

private final class GlobalHotKeyManager {
    private static let signature: OSType = 0x5458544D // TXTM
    private let action: (GlobalHotKeyAction) -> Void
    private var handler: EventHandlerRef?
    private var references: [EventHotKeyRef] = []
    private var started = false

    init(action: @escaping (GlobalHotKeyAction) -> Void) {
        self.action = action
    }

    deinit { stop() }

    func start() -> Bool {
        guard !started else { return references.count == 10 }
        started = true
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, userData in
                guard let event, let userData else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<GlobalHotKeyManager>.fromOpaque(userData).takeUnretainedValue()
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
                guard result == noErr else { return OSStatus(eventNotHandledErr) }
                if identifier.id == 10 {
                    manager.action(.privacy)
                } else if let position = WindowPosition(rawValue: Int(identifier.id)) {
                    manager.action(.position(position))
                }
                return noErr
            },
            1,
            &eventType,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &handler
        )
        guard status == noErr else { return false }

        let positionCodes: [WindowPosition: UInt32] = [
            .bottomLeft: UInt32(kVK_ANSI_1), .bottomCenter: UInt32(kVK_ANSI_2),
            .bottomRight: UInt32(kVK_ANSI_3), .middleLeft: UInt32(kVK_ANSI_4),
            .center: UInt32(kVK_ANSI_5), .middleRight: UInt32(kVK_ANSI_6),
            .topLeft: UInt32(kVK_ANSI_7), .topCenter: UInt32(kVK_ANSI_8),
            .topRight: UInt32(kVK_ANSI_9)
        ]
        let modifiers = UInt32(controlKey | optionKey)
        for position in WindowPosition.allCases {
            let id = EventHotKeyID(signature: Self.signature, id: UInt32(position.rawValue))
            var reference: EventHotKeyRef?
            if RegisterEventHotKey(positionCodes[position]!, modifiers, id, GetApplicationEventTarget(), 0, &reference) == noErr,
               let reference {
                references.append(reference)
            }
        }
        let privacyID = EventHotKeyID(signature: Self.signature, id: 10)
        var privacyRef: EventHotKeyRef?
        if RegisterEventHotKey(UInt32(kVK_ANSI_0), modifiers, privacyID, GetApplicationEventTarget(), 0, &privacyRef) == noErr,
           let privacyRef {
            references.append(privacyRef)
        }
        return references.count == 10
    }

    private func stop() {
        references.forEach { _ = UnregisterEventHotKey($0) }
        references.removeAll()
        if let handler { RemoveEventHandler(handler) }
        handler = nil
    }
}
