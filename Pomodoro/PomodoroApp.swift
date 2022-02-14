//
//  PomodoroApp.swift
//  Pomodoro
//
//  Created by Johan West on 2022-01-25.
//

import SwiftUI
import Intents

@main
struct PomodoroApp: App {
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  
  var body: some Scene {
    WindowGroup {
      if false {}
    }
  }
}

@MainActor
private final class AppDelegate: NSObject, NSApplicationDelegate {
  var app: Application?
  
  func applicationDidFinishLaunching(_ notification: Notification) {
    app = Application()
  }
  
  func application(_ application: NSApplication, handlerFor intent: INIntent) -> Any? {
    if intent is StartTimerIntent || intent is StopTimerIntent, app != nil {
      return app
    }
    return nil
  }
}
