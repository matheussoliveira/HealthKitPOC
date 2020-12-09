//
//  HealthKitManager.swift
//  WatchHealthKitPOC Extension
//
//  Created by Joao Flores on 09/12/20.
//

import Foundation
import WatchKit
import HealthKit
import UserNotifications
import WatchConnectivity
import Foundation
import HealthKit
import Combine
import CoreMotion

class HealthKitManager {
	func requestAuthorization() -> String?{
		let healthStore = HKHealthStore()

		guard HKHealthStore.isHealthDataAvailable() else {
			return "HealthKit is not available "
		}

		let typesToShare: Set = [ HKQuantityType.workoutType() ]

		let typesToRead: Set = [
			HKQuantityType.quantityType(forIdentifier: .heartRate)!,
			HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
			HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
		]

		healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
			print(error.debugDescription)
		}

		return nil
	}
}
