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
import CoreMotion

class InterfaceController: WKInterfaceController {
	//	MARK: - IBOutlets
	@IBOutlet weak var heartrateLabel: WKInterfaceLabel!
	@IBOutlet weak var activeCaloriesLabel: WKInterfaceLabel!
	@IBOutlet weak var distanceLabel: WKInterfaceLabel!
	@IBOutlet weak var timerLabel: WKInterfaceLabel!
	@IBOutlet weak var stepCounter: WKInterfaceLabel!

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

	let pedometer = CMPedometer()
	var steps: Int = 0

	//	MARK: - Life Cycle
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)

		NotificationManager().setupNotifications()

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

		pedometer.startUpdates(from: Date()) { (data, error) in
			self.stepCounter.setText("\(data?.numberOfSteps ?? 0) passos")
			//            self.steps = Int(data?.numberOfSteps ?? 0)
		}

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

	@IBOutlet weak var backgroundGroup: WKInterfaceGroup!
	@IBOutlet weak var currentProgressLabel: WKInterfaceLabel!

	@IBAction func teste() {
//		currentProgressLabel.setText("90\nmetros")

		let duration = 0.35
		let delay = DispatchTime.now() + Double(Int64((duration + 0.15) * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)

		backgroundGroup.setBackgroundImageNamed("Progress")
		backgroundGroup.startAnimatingWithImages(in: NSRange(location: 0, length: 10),
												 duration: duration,
												 repeatCount: 1)

		DispatchQueue.main.asyncAfter(deadline: delay) { [weak self] in
			//      self?.flight?.checkedIn = true
			self?.dismiss()
		}
	}
}

// MERK: - Workout Manager
extension InterfaceController: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
	func workoutConfiguration() -> HKWorkoutConfiguration {
		let configuration = HKWorkoutConfiguration()
		configuration.activityType = .running
		configuration.locationType = .outdoor

		return configuration
	}

	func startWorkout() {
		setUpTimer()

		self.running = true

		do {
			session = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration())
			builder = session.associatedWorkoutBuilder()
		} catch {
			return
		}

		session.delegate = self
		builder.delegate = self

		builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
													 workoutConfiguration: workoutConfiguration())

		session.startActivity(with: Date())
		builder.beginCollection(withStart: Date()) { (success, error) in
			print(error.debugDescription)
		}
	}

	func endWorkout() {
		session.end()
		cancellable?.cancel()
	}

	func resetWorkout() {
		DispatchQueue.main.async {
			self.elapsedSeconds = 0
			self.activeCalories = 0
			self.heartrate = 0
			self.distance = 0
		}
	}

	// MARK: - Update the UI
	func updateForStatistics(_ statistics: HKStatistics?) {
		guard let statistics = statistics else { return }

		DispatchQueue.main.async {
			switch statistics.quantityType {
				case HKQuantityType.quantityType(forIdentifier: .heartRate):
					/// - Tag: SetLabel
					let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
					let value = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit)
					let roundedValue = Double( round( 1 * value! ) / 1 )
					self.heartrate = roundedValue
				case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
					let energyUnit = HKUnit.kilocalorie()
					let value = statistics.sumQuantity()?.doubleValue(for: energyUnit)
					self.activeCalories = Double( round( 1 * value! ) / 1 )
					return
				case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
					let meterUnit = HKUnit.meter()
					let value = statistics.sumQuantity()?.doubleValue(for: meterUnit)
					let roundedValue = Double( round( 1 * value! ) / 1 )
					self.distance = roundedValue
					return
				default:
					return
			}
		}
	}

	func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
						from fromState: HKWorkoutSessionState, date: Date) {
		if toState == .ended {
			builder.endCollection(withEnd: Date()) { (success, error) in
				self.builder.finishWorkout { (workout, error) in
					self.resetWorkout()
				}
			}
		}
	}

	func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
		for type in collectedTypes {
			guard let quantityType = type as? HKQuantityType else {
				return
			}

			let statistics = workoutBuilder.statistics(for: quantityType)

			updateForStatistics(statistics)
		}

		heartrateLabel.setText("\(heartrate)")
		activeCaloriesLabel.setText("\(activeCalories) cal")
		distanceLabel.setText("\(distance)")
		timerLabel.setText(secondsToHoursMinutesSeconds(seconds: elapsedSeconds))
		//        stepCounter.setText("\(steps) passos")
	}

	func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) { }

	func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) { }
}
