//
//  Timer.swift
//  Focus
//
//  Created by Johan West on 2022-01-25.
//

import Foundation

struct AppTimer {
  var timer: Timer?
  
  mutating func run(forDuration minutes: Int, block: @escaping (Double) -> Void) {
    var minutesLeft = Double(minutes)
    timer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true, block: { _ in
      minutesLeft -= 0.5
      block(minutesLeft)
    })
  }
  
  mutating func stop() {
    timer?.invalidate()
    timer = nil
  }
}
