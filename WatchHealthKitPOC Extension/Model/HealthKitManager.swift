//
//  HealthKitManager.swift
//  WatchHealthKitPOC Extension
//
//  Created by Joao Flores on 11/11/20.
//

import WatchKit
import Foundation
import HealthKit
import UserNotifications
import WatchConnectivity
import Foundation
import HealthKit
import Combine

class HealthKitManager {

	func requestAuthorization(healthStore: HKHealthStore) {
		// Requesting authorization.
		/// - Tag: RequestAuthorization
		// The quantity type to write to the health store.
		let typesToShare: Set = [
			HKQuantityType.workoutType()
		]

		// The quantity types to read from the health store.
		let typesToRead: Set = [
			HKQuantityType.quantityType(forIdentifier: .heartRate)!,
			HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
			HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
		]

		// Request authorization for those quantity types.
		healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
			// Handle error.
		}
	}
}
