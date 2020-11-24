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
	@IBOutlet weak var backgroundGroup: WKInterfaceGroup!
	@IBOutlet weak var mensureLabel: WKInterfaceLabel!
	@IBOutlet weak var target: WKInterfaceLabel!

	//	MARK: - IBActions
	@IBAction func startWorkoutAction() {

		if running {
			// to do: pause
		}
		else {
			let startLabels = TypeExerciseManager().initialLabels(train: train)
			distanceLabel.setText(startLabels.distance)
			mensureLabel.setText(startLabels.mensure)

			startWorkout()
		}
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

	var train = Train(type: .distance, targuet: 100)


	//	MARK: - Life Cycle
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)

		requestAuthorization()

		distanceLabel.setText("Começar")
		mensureLabel.setText("")

		if let getTrain = context as? Train {
			train = Train(type: getTrain.type, targuet: getTrain.targuet)
		}

		target.setText("meta: \(TypeExerciseManager().populateTargetLabel(train: train))")
	}

	//	MARK: - HealthKit
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

		startPedometer()

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
}

// MERK: - Workout Manager
extension InterfaceController: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {

	func startWorkout() {
		setUpTimer()

		self.running = true

		do {
			session = try HKWorkoutSession(healthStore: healthStore, configuration: TimerManager().workoutConfiguration())
			builder = session.associatedWorkoutBuilder()
		} catch {
			return
		}

		session.delegate = self
		builder.delegate = self

		builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
													 workoutConfiguration: TimerManager().workoutConfiguration())

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
		timerLabel.setText(TimerManager().secondsToHoursMinutesSeconds(seconds: elapsedSeconds))

		if(train.type == .distance) {
			distanceLabel.setText("\(distance)")

			let currentProgress = Int((distance / Double(train.targuet))*100)

			if(currentProgress >= 100) {
				backgroundGroup.setBackgroundImageNamed("Progress-101")
				endWorkout()
				session.end()
				mensureLabel.setText("Parabéns!")
				distanceLabel.setText("✓")
			}
			else {
				backgroundGroup.setBackgroundImageNamed("Progress-\(currentProgress)")
			}
		}

		if(train.type == .time) {
			distanceLabel.setText(TimerManager().secondsToHoursMinutesSeconds(seconds: elapsedSeconds))

			let currentProgress = Int((Double(elapsedSeconds) / Double(train.targuet))*100)

			if(currentProgress >= 100) {
				backgroundGroup.setBackgroundImageNamed("Progress-101")
				endWorkout()
				session.end()
				mensureLabel.setText("Parabéns!")
				distanceLabel.setText("✓")
			}
			else {
				backgroundGroup.setBackgroundImageNamed("Progress-\(currentProgress)")
			}
		}
	}

	func startPedometer() {
		pedometer.startUpdates(from: Date()) { (data, error) in
			self.stepCounter.setText("\(data?.numberOfSteps ?? 0) passos")
			if(self.train.type == .paces) {
				self.distanceLabel.setText("\(data?.numberOfSteps ?? 0) passos")

				let numberOfSteps = data?.numberOfSteps ?? 0
				let currentProgress = Int((Double(truncating: numberOfSteps) / Double(self.train.targuet))*100)

				if(currentProgress >= 100) {
					self.backgroundGroup.setBackgroundImageNamed("Progress-101")
					self.endWorkout()
					self.session.end()
					self.mensureLabel.setText("Parabéns!")
					self.distanceLabel.setText("✓")
				}
				else {
					self.backgroundGroup.setBackgroundImageNamed("Progress-\(currentProgress)")
				}
			}
		}
	}

	func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) { }

	func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) { }
}
