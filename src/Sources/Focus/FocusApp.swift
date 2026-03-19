import AppKit
import Carbon
import SwiftUI

@main
struct FocusApp: App {
    @StateObject private var timer = FocusTimer.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra(timer.displayString) {
            Button("Start") {
                timer.start()
            }
            .keyboardShortcut("s", modifiers: .command)
            .disabled(timer.isRunning)

            Button("Stop") {
                timer.stop()
            }
            .keyboardShortcut("s", modifiers: .command)
            .disabled(!timer.isRunning)

            Divider()

            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .menuBarExtraStyle(.menu)
    }
}

@MainActor
final class FocusTimer: ObservableObject {
    static let shared = FocusTimer()

    @Published private(set) var isRunning: Bool = false
    @Published private(set) var elapsedSeconds: Int = 0

    private let maxSeconds = (24 * 60 * 60) - 1
    private var timer: DispatchSourceTimer?

    var displayString: String {
        formatDuration(seconds: elapsedSeconds)
    }

    func start() {
        elapsedSeconds = 0
        isRunning = true
        startTimer()
    }

    func stop() {
        isRunning = false
        stopTimer()
    }

    func toggle() {
        if isRunning {
            stop()
        } else {
            start()
        }
    }

    private func startTimer() {
        stopTimer()

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 1, repeating: 1)
        timer.setEventHandler { [weak self] in
            self?.tick()
        }
        timer.resume()

        self.timer = timer
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    private func tick() {
        guard isRunning else { return }

        if elapsedSeconds < maxSeconds {
            elapsedSeconds += 1
        } else {
            stop()
        }
    }

    private func formatDuration(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let secs = seconds % 60

        var parts: [String] = []

        if hours > 0 {
            parts.append("\(hours)h")
        }

        if minutes > 0 {
            parts.append("\(minutes)m")
        }

        if secs > 0 || parts.isEmpty {
            parts.append("\(secs)s")
        }

        return parts.joined(separator: " ")
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let distributedNotificationCenter = DistributedNotificationCenter.default()

    func applicationDidFinishLaunching(_ notification: Notification) {
        HotKeyManager.shared.onToggle = {
            Task { @MainActor in
                FocusTimer.shared.toggle()
            }
        }
        HotKeyManager.shared.register()

        distributedNotificationCenter.addObserver(
            self,
            selector: #selector(handleScreenLocked(_:)),
            name: Notification.Name(rawValue: "com.apple.screenIsLocked"),
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        distributedNotificationCenter.removeObserver(
            self,
            name: Notification.Name(rawValue: "com.apple.screenIsLocked"),
            object: nil
        )
        HotKeyManager.shared.unregister()
    }

    @objc private func handleScreenLocked(_ notification: Notification) {
        Task { @MainActor in
            guard FocusTimer.shared.isRunning else { return }
            FocusTimer.shared.stop()
        }
    }
}

@MainActor
final class HotKeyManager {
    static let shared = HotKeyManager()

    var onToggle: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private var handlerUPP: EventHandlerUPP?

    private init() {}

    func register() {
        guard hotKeyRef == nil else { return }

        let hotKeyID = EventHotKeyID(
            signature: fourCharCode("FOCU"),
            id: 1
        )

        let modifiers = UInt32(controlKey | optionKey)
        let eventTarget = GetApplicationEventTarget()
        let registerStatus = RegisterEventHotKey(
            UInt32(kVK_ANSI_F),
            modifiers,
            hotKeyID,
            eventTarget,
            0,
            &hotKeyRef
        )
        guard registerStatus == noErr else {
            NSLog("RegisterEventHotKey failed: \(registerStatus)")
            return
        }

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        handlerUPP = { _, _, userData in
            guard let userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
            manager.onToggle?()
            return noErr
        }

        if let handlerUPP {
            let installStatus = InstallEventHandler(
                eventTarget,
                handlerUPP,
                1,
                &eventSpec,
                UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
                &handlerRef
            )
            if installStatus != noErr {
                NSLog("InstallEventHandler failed: \(installStatus)")
            }
        }
    }

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let handlerRef {
            RemoveEventHandler(handlerRef)
            self.handlerRef = nil
        }
    }
}

private func fourCharCode(_ string: String) -> FourCharCode {
    var result: FourCharCode = 0
    for scalar in string.unicodeScalars.prefix(4) {
        result = (result << 8) + FourCharCode(scalar.value)
    }
    return result
}
