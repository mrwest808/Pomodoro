//
//  Menu.swift
//  Focus
//
//  Created by Johan West on 2022-01-27.
//

import Foundation
import AppKit

class Menu {
  var onStart: ((Int) -> Void)?
  var onStop: (() -> Void)?
  
  private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
  private var menu: NSMenu
  private var startMenuItem: NSMenuItem
  private var stopMenuItem: NSMenuItem
  private var quitMenuItem: NSMenuItem
  
  init() {
    startMenuItem = NSMenuItem(title: "Start ...", action: #selector(pressStart(_:)), keyEquivalent: "1")
    stopMenuItem = NSMenuItem(title: "Stop", action: #selector(pressStop(_:)), keyEquivalent: "2")
    quitMenuItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    
    menu = NSMenu()
    
    startMenuItem.target = self
    stopMenuItem.target = self
    
    menu.addItem(startMenuItem)
    menu.addItem(stopMenuItem)
    menu.addItem(NSMenuItem.separator())
    menu.addItem(quitMenuItem)
    
    menu.autoenablesItems = false
    stopMenuItem.isEnabled = false
    stopMenuItem.isHidden = true
    
    statusItem.menu = menu
    reset()
  }
  
  @objc func pressStart(_ sender: Any?) {
    let duration = askForDuration()
    
    if duration > -1 {
      onStart?(duration)
    }
  }
  
  @objc func pressStop(_ sender: Any?) {
    onStop?()
  }
  
  private func askForDuration() -> Int {
    let alert = NSAlert()
    alert.messageText = "Set timer duration"
    alert.informativeText = "Set the number of minutes you want the timer to run."
    alert.alertStyle = .informational
    
    let textfield = NSTextField(string: String(25))
    textfield.setFrameSize(.init(width: 40, height: textfield.frame.height))
    
    alert.addButton(withTitle: "Run")
    alert.addButton(withTitle: "Cancel")
    alert.accessoryView = textfield
    alert.window.initialFirstResponder = textfield
    
    let frontmostApp = NSWorkspace.shared.frontmostApplication
    NSRunningApplication.current.activate(options: .activateIgnoringOtherApps)
    
    if alert.runModal() == .alertFirstButtonReturn {
      let duration = Int(textfield.stringValue) ?? 25
      
      if isValidDuration(duration) {
        frontmostApp?.activate(options: .activateIgnoringOtherApps)
        return duration
      }
    }
    
    frontmostApp?.activate(options: .activateIgnoringOtherApps)
    return -1
  }
  
  private func isValidDuration(_ value: Int) -> Bool {
    return value > 0 && value < 240
  }
  
  private func setMenuButtonTitle(_ title: String) {
    if let button = statusItem.button {
      button.title = title
    }
  }
  
  public func reset() {
    setMenuButtonTitle("P")
    stopMenuItem.isEnabled = false
    stopMenuItem.isHidden = true
    startMenuItem.isEnabled = true
    startMenuItem.isHidden = false
  }
  
  public func running(_ duration: Int) {
    tick(timeLeft: "\(duration)m")
    startMenuItem.isEnabled = false
    startMenuItem.isHidden = true
    stopMenuItem.isEnabled = true
    stopMenuItem.isHidden = false
  }
  
  public func tick(timeLeft: String) {
    setMenuButtonTitle(timeLeft)
  }
}
