//
//  Application.swift
//  Focus
//
//  Created by Johan West on 2022-01-25.
//

import Foundation
import Intents
import AppKit

enum AppState {
  case idle
  case running
}

class Application: NSObject {
  
  var duration = 25
  var appState: AppState = .idle {
    didSet(newAppState) {
      if newAppState == .idle {
        timer.run(forDuration: duration, block: handleTick(minutesLeft:))
        menu.running(duration)
      }

      if newAppState == .running {
        timer.stop()
        menu.reset()
        didShowAlmostOverAlert = false
      }
    }
  }
  
  var notificationPermissionGranted = false
  var didShowAlmostOverAlert = false
  var timer = AppTimer()
  let menu = Menu()
  
  override init() {
    super.init()
    menu.onStart = handleMenuStart
    menu.onStop = handleMenuStop
    
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
      if granted {
        self.notificationPermissionGranted = true
      }
    }
  }
  
  private func handleMenuStart(duration: Int) {
    if appState == .idle {
      self.duration = duration
      appState = .running
    }
  }
  
  private func handleMenuStop() {
    if appState == .running {
      appState = .idle
    }
  }
  
  private func handleTick(minutesLeft: Double) {
    if minutesLeft <= 0 {
      appState = .idle
      showTimerFinishedAlert()
      return
    }
    
    var timeLeft = "\(Int(minutesLeft.rounded(.down)))m"
    
    if minutesLeft <= 0.5 {
      timeLeft = "< 1m"
    }
    
    if (!didShowAlmostOverAlert && minutesLeft <= 3.0) {
      showAlmostOverAlert()
      didShowAlmostOverAlert = true
    }
    
    menu.tick(timeLeft: timeLeft)
  }
  
  private func showAlmostOverAlert() {
    if !notificationPermissionGranted {
      return
    }
    
    let content = UNMutableNotificationContent()
    content.title = "Time's almost up!"
    content.body = "A few minutes left, start wrapping up..."
    content.sound = .default
    
    let request = UNNotificationRequest(
      identifier: UUID().uuidString,
      content: content,
      trigger: nil
    )
    
    UNUserNotificationCenter.current().add(request)
  }
  
  private func showTimerFinishedAlert() {
    let alert = NSAlert()
    alert.messageText = "Time's up!"
    alert.informativeText = "Take a little break and stretch your legs."
    alert.alertStyle = .informational
    alert.addButton(withTitle: "OK")
    alert.window.initialFirstResponder = alert.buttons.first
    
    let frontmostApp = NSWorkspace.shared.frontmostApplication
    NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)
    
    alert.runModal()
    frontmostApp?.activate(options: .activateIgnoringOtherApps)
  }
}

extension Application: StartTimerIntentHandling {
  func confirm(intent: StartTimerIntent, completion: @escaping (StartTimerIntentResponse) -> Void) {
    var responseCode: StartTimerIntentResponseCode = .success
    
    if intent.duration == nil {
      responseCode = .failure
    }
    
    let response = StartTimerIntentResponse(code: responseCode, userActivity: nil)
    completion(response)
  }
  
  func handle(intent: StartTimerIntent, completion: @escaping (StartTimerIntentResponse) -> Void) {
    handleMenuStart(duration: Int(truncating: intent.duration!))
    let response = StartTimerIntentResponse(code: .success, userActivity: nil)
    completion(response)
  }
  
}
