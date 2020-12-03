//
//  TimerManager.swift
//  WatchHealthKitPOC Extension
//
//  Created by Joao Flores on 03/12/20.
//

import WatchKit
import Foundation
import HealthKit
import UserNotifications
import WatchConnectivity
import Foundation
import HealthKit
import Combine

/// class handle timer in trains

class TimerManager {
	func secondsToHoursMinutesSeconds (seconds : Int) -> String {
		
		let hours = String(format: "%02d", seconds / 3600)
		let minuts = String(format: "%02d", (seconds % 3600) / 60)
		let seconds = String(format: "%02d", (seconds % 3600) % 60)
		return hours + ":" + minuts + ":" + seconds
	}
	
	func workoutConfiguration() -> HKWorkoutConfiguration {
		let configuration = HKWorkoutConfiguration()
		configuration.activityType = .running
		configuration.locationType = .outdoor
		
		return configuration
	}
}
