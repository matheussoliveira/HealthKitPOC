//
//  InterfaceController.swift
//  WatchHealthKitPOC Extension
//
//  Created by Joao Flores on 06/11/20.
//

import WatchKit
import Foundation
import HealthKit
import UserNotifications
import WatchConnectivity
import Foundation
import HealthKit
import Combine

class InterfaceController: WKInterfaceController {
	//	MARK: - IBOutlets
	@IBOutlet weak var heartrateLabel: WKInterfaceLabel!
	@IBOutlet weak var activeCaloriesLabel: WKInterfaceLabel!
	@IBOutlet weak var distanceLabel: WKInterfaceLabel!
	@IBOutlet weak var timerLabel: WKInterfaceLabel!

	//	MARK: - IBActions
	@IBAction func requestLocalNotification() {
		NotificationManager().singleNotification()
	}

	//	MARK: - Variables
	let healthStore = HKHealthStore()
	var session: HKWorkoutSession!
	var builder: HKLiveWorkoutBuilder!

	var heartrate: Double = 0
	var activeCalories: Double = 0
	var distance: Double = 0
	var elapsedSeconds: Int = 0

	var running: Bool = false

	var start: Date = Date()
	var cancellable: Cancellable?
	var accumulatedTime: Int = 0

	//	MARK: - Life Cycle
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)

		NotificationManager().setupNotifications()
		NotificationManager().setReminderNotification()

		requestAuthorization()
		startWorkout()
	}

//	MARK: - HealthKit
	// Request authorization to access HealthKit.
	func requestAuthorization() {
		guard HKHealthStore.isHealthDataAvailable() else {
			heartrateLabel.setText("HealthKit is not available ")
			print("HealthKit is not available on this device.")
			return
		}

		let typesToShare: Set = [
			HKQuantityType.workoutType()
		]

		let typesToRead: Set = [
			HKQuantityType.quantityType(forIdentifier: .heartRate)!,
			HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
			HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
		]

		healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
			print(error.debugDescription)
		}
	}

//	MARK: - Timer
	func setUpTimer() {
		start = Date()
		cancellable = Timer.publish(every: 0.1, on: .main, in: .default)
			.autoconnect()
			.sink { [weak self] _ in
				guard let self = self else { return }
				self.elapsedSeconds = self.incrementElapsedTime()
			}
	}

	func incrementElapsedTime() -> Int {
		let runningTime: Int = Int(-1 * (self.start.timeIntervalSinceNow))
		return self.accumulatedTime + runningTime
	}

	func secondsToHoursMinutesSeconds (seconds : Int) -> String {

		let hours = String(format: "%02d", seconds / 3600)
		let minuts = String(format: "%02d", (seconds % 3600) / 60)
		let seconds = String(format: "%02d", (seconds % 3600) % 60)
		return hours + ":" + minuts + ":" + seconds
	}
}
