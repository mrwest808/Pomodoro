//
//  AppDelegate.swift
//  Pomodoro
//
//  Created by Johan West on 2019-05-27.
//  Copyright © 2019 Johan West. All rights reserved.
//

import Foundation
import Cocoa
import UserNotifications

let TIMER_DURATION_KEY = "timerDuration"
let DEFAULT_TIMER_DURATION = 25

enum TimerState {
  case idle
  case running
}

struct MenuItems {
  var start: NSMenuItem
  var stop: NSMenuItem
  var changeDuration: NSMenuItem
  var quit: NSMenuItem
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

  var notificationPermissionGranted = false
  var menuItems: MenuItems!
  var timer: Timer?
  var timerDurationInMinutes: Int = 25
  var timerState: TimerState = .idle {
    didSet {
      didChangeTimerState(timerState)
    }
  }
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let storedDuration = UserDefaults.standard.integer(forKey: TIMER_DURATION_KEY)
    if isValidDuration(storedDuration) {
      timerDurationInMinutes = storedDuration
    }

    setMenuButtonTitle("P")
    buildMenu()

    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
      if granted {
        self.notificationPermissionGranted = true
      }
    }
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }
  
  func buildMenu() {
    menuItems = MenuItems(
      start: NSMenuItem(title: "Start (\(timerDurationInMinutes) min)", action: #selector(pressStartTimer(_:)), keyEquivalent: ""),
      stop: NSMenuItem(title: "Stop", action: #selector(pressStopTimer(_:)), keyEquivalent: ""),
      changeDuration: NSMenuItem(title: "Change timer duration", action: #selector(pressChangeDuration(_:)), keyEquivalent: ""),
      quit: NSMenuItem(title: "Quit Pomodoro", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    )

    let menu = NSMenu()
    
    menu.addItem(menuItems.start)
    menu.addItem(menuItems.stop)
    menu.addItem(NSMenuItem.separator())
    menu.addItem(menuItems.changeDuration)
    menu.addItem(menuItems.quit)
    
    menu.autoenablesItems = false
    menuItems.stop.isEnabled = false
    menuItems.stop.isHidden = true
    
    statusItem.menu = menu
  }
  
  @objc func pressStartTimer(_ sender: Any?) {
    startTimer()
  }
  
  @objc func pressStopTimer(_ sender: Any?) {
    stopTimer(manuallyStopped: true)
  }
  
  @objc func pressChangeDuration(_ sender: Any?) {
    showChangeDurationAlert()
  }
  
  func startTimer() {
    timerState = .running
    setMenuButtonTitle("\(timerDurationInMinutes)m")

    // Tick every 30 seconds flooring the time left, which should resolve in:
    // 25.0 -> 25m
    // 24.5 -> 24m
    // 24.0 -> 24m
    // 23.5 -> 23m
    // ...
    var minutesLeft = Double(timerDurationInMinutes)
    var didAlertAboutAlmostOver = false

    timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true, block: { _ in
      minutesLeft -= 0.5
      
      if minutesLeft <= 0 {
        self.stopTimer(manuallyStopped: false)
        return
      }
      
      if minutesLeft <= 0.5 {
        self.setMenuButtonTitle("< 1m")
        return
      }

      if !didAlertAboutAlmostOver && minutesLeft <= 2.0 {
        self.triggerAlmostOverNotification()
        didAlertAboutAlmostOver = true
      }

      self.setMenuButtonTitle("\(Int(minutesLeft.rounded(.down)))m")
    })
  }
  
  func stopTimer(manuallyStopped: Bool) {
    self.timer?.invalidate()
    self.timer = nil
    self.timerState = .idle
    self.setMenuButtonTitle("P")

    if !manuallyStopped {
      showTimerFinishedAlert()
    }
  }
  
  func showTimerFinishedAlert() {
    let alert = NSAlert()
    alert.messageText = "Time's up!"
    alert.informativeText = "Take a little break and stretch your legs."
    alert.alertStyle = .informational
    alert.addButton(withTitle: "OK")
    alert.window.initialFirstResponder = alert.buttons.first

    let frontmostApp = NSWorkspace.shared.frontmostApplication
    NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)

    alert.runModal()
    frontmostApp?.activate()
  }
  
  func showChangeDurationAlert() {
    let inputView = NSTextField(string: String(timerDurationInMinutes))
    inputView.setFrameSize(NSSize(width: 40, height: inputView.frame.height))

    let alert = NSAlert()
    alert.messageText = "Change timer duration"
    alert.informativeText = "Set the number of minutes you want the timer to run."
    alert.alertStyle = .informational
    alert.addButton(withTitle: "Save")
    alert.addButton(withTitle: "Cancel")
    alert.accessoryView = inputView
    alert.window.initialFirstResponder = inputView

    let frontmostApp = NSWorkspace.shared.frontmostApplication
    NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)

    if alert.runModal() == .alertFirstButtonReturn {
      let duration = Int(inputView.stringValue) ?? timerDurationInMinutes
      
      if duration != timerDurationInMinutes && isValidDuration(duration)  {
        timerDurationInMinutes = duration
        UserDefaults.standard.set(duration, forKey: TIMER_DURATION_KEY)
        menuItems.start.title = "Start (\(duration) min)"
      }
    }

    frontmostApp?.activate()
  }
  
  func setMenuButtonTitle(_ title: String) {
    if let button = statusItem.button {
      button.title = title
    }
  }

  func triggerAlmostOverNotification() {
    if !notificationPermissionGranted {
      return
    }

    let content = UNMutableNotificationContent()
    content.title = "Time's almost up!"
    content.body = "2 minutes left, start wrapping up..."
    content.sound = UNNotificationSound.default

    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: nil
    )

    UNUserNotificationCenter.current().add(request)
  }
  
  func didChangeTimerState(_ newState: TimerState) {
    if newState == .running {
      menuItems.start.isEnabled = false
      menuItems.start.isHidden = true
      menuItems.stop.isEnabled = true
      menuItems.stop.isHidden = false
      menuItems.changeDuration.isEnabled = false
      return
    }
    
    if newState == .idle {
      menuItems.start.isEnabled = true
      menuItems.start.isHidden = false
      menuItems.stop.isEnabled = false
      menuItems.stop.isHidden = true
      menuItems.changeDuration.isEnabled = true
      return
    }
  }
  
  func isValidDuration(_ value: Int) -> Bool {
    return value > 0 && value < 720
  }
  
}
