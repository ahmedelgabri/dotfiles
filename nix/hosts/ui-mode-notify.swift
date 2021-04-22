#!/usr/bin/env swift

// Run as ./ui-mode-notify.swift <program to run when dark mode changes>
// The program will have the DARKMODE env flag set to 1 or 0
// You can also compile with:
// swiftc ui-mode-notify.swift -o ui-mode-notify
// And run the binary directly
// Most credit goes to https://github.com/bouk/dark-mode-notify & https://github.com/mnewt/dotemacs/blob/master/bin/dark-mode-notifier.swift
import Cocoa

@discardableResult
func shell(_ args: [String]) -> Int32 {
    let task = Process()
    let isDark = UserDefaults.standard.string(forKey: "AppleInterfaceStyle") == "Dark"
    var env = ProcessInfo.processInfo.environment
    env["DARKMODE"] = isDark ? "1" : "0"
    task.environment = env
    task.launchPath = "/usr/bin/env"
    task.arguments = args
    task.standardError = FileHandle.standardError
    task.standardOutput = FileHandle.standardOutput
    task.launch()
    task.waitUntilExit()
    return task.terminationStatus
}

let args = Array(CommandLine.arguments.suffix(from: 1))
shell(args)

DistributedNotificationCenter.default.addObserver(
    forName: Notification.Name("AppleInterfaceThemeChangedNotification"),
    object: nil,
    queue: nil) { (notification) in
        shell(args)
}

NSApplication.shared.run()
