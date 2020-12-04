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

class TrainInterfaceController: WKInterfaceController {
	//	MARK: - IBOutlets
	@IBOutlet weak var heartrateLabel: WKInterfaceLabel!
	@IBOutlet weak var distanceLabel: WKInterfaceLabel!
	@IBOutlet weak var backgroundGroup: WKInterfaceGroup!
	@IBOutlet weak var mensureLabel: WKInterfaceLabel!
	@IBOutlet weak var target: WKInterfaceLabel!
	@IBOutlet weak var timerLabel: WKInterfaceLabel!

	//	MARK: - IBActions
	@IBAction func startWorkoutAction() {
		if !train.isPaused {
			running = true
			let startLabels = TypeExerciseManager().initialLabels(train: train)
			distanceLabel.setText(startLabels.distance)
			mensureLabel.setText(startLabels.mensure)

			endWorkout()
			resetWorkout()

			startWorkout()
			startTimer()
		}
	}

	//	MARK: - Variables
	let healthStore = HKHealthStore()
	var session: HKWorkoutSession!
	var builder: HKLiveWorkoutBuilder!

	var heartrate: Double = 0
	var activeCalories: Double = 0
	var distance: Double = 0
	var timerCounter = 0
	var timer = Timer()

	var running: Bool = false
	var start: Date = Date()
	var cancellable: Cancellable?

	let pedometer = CMPedometer()
	var steps: Int = 0
	
	var train = TrainStruct(type: .distance, targuet: 1, title: "----", subtitle: "----", currentProgress: 0, currentTime: 0, isPaused: false)

	//	MARK: - Life Cycle
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)

		requestAuthorization()

		if let getTrain = context as? TrainStruct { train = getTrain }

		target.setText("meta: \(TypeExerciseManager().populateTargetLabel(train: train))")
		mensureLabel.setText("")

		if(train.isPaused) {
			distanceLabel.setText("Pausado")
		}
		else if(train.currentTime == 0) {
			distanceLabel.setText("Começar")
		}
		else {
			distanceLabel.setText("Retomando")
		}

		if (train.type == TrainType.paces) { startPedometer() }

		startWorkout()
	}

	override func willDisappear() {
		if !train.isPaused {
			let team = TrainPersistenceData(
				currentProgress: distance,
				type: TypeExerciseManager().trainTypeToString(type: train.type),
				targuet: train.targuet,
				title: train.title,
				subtitle: train.subtitle,
				currentTime: timerCounter,
				isPaused: train.isPaused
			)

			team.saveTrain()
		}
	}

	//	MARK: - HealthKit
	func requestAuthorization() {
		guard HKHealthStore.isHealthDataAvailable() else {
			heartrateLabel.setText("HealthKit is not available ")
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
	func startTimer() {
		timer.invalidate()

		timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
	}

	@objc func timerAction() {
		timerCounter += 1
		timerLabel.setText(TimerManager().secondsToHoursMinutesSeconds(seconds: timerCounter))

		if(train.type == .time && running) {
			distanceLabel.setText(TimerManager().secondsToHoursMinutesSeconds(seconds: timerCounter))

			let currentProgress = Int((Double(timerCounter) / Double(train.targuet))*100)

			if(currentProgress >= 100) {
				finishTrain()
			}
			else {
				backgroundGroup.setBackgroundImageNamed("Progress-\(currentProgress)")
			}
		}
	}
}

// MARK: - Workout Manager
extension TrainInterfaceController: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {

	func startWorkout() {
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
		session?.end()
		cancellable?.cancel()
	}

	func resetWorkout() {
		DispatchQueue.main.async {
			self.timerCounter = 0
			self.activeCalories = 0
			self.distance = 0
		}
	}

	// MARK: - Update the UI
	func updateForStatistics(_ statistics: HKStatistics?) {
		guard let statistics = statistics else { return }

		DispatchQueue.main.async {
			switch statistics.quantityType {
				case HKQuantityType.quantityType(forIdentifier: .heartRate):

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

		if(train.type == .distance && running) {
			distanceLabel.setText("\(distance)")

			let currentProgress = Int((distance / Double(train.targuet))*100)

			if(currentProgress >= 100) {
				finishTrain()
			}
			else {
				backgroundGroup.setBackgroundImageNamed("Progress-\(currentProgress)")
			}
		}

		heartrateLabel.setText("\(heartrate)")
	}

	func startPedometer() {
		pedometer.startUpdates(from: Date()) { (data, error) in
			if(self.train.type == .paces && self.running) {
				self.distanceLabel.setText("\(data?.numberOfSteps ?? 0)")

				let numberOfSteps = data?.numberOfSteps ?? 0
				let currentProgress = Int((Double(truncating: numberOfSteps) / Double(self.train.targuet))*100)

				if(currentProgress >= 100) {
					self.finishTrain()
				}
				else {
					self.backgroundGroup.setBackgroundImageNamed("Progress-\(currentProgress)")
				}
			}
		}
	}

	func finishTrain() {
		backgroundGroup.setBackgroundImageNamed("Progress-101")
		endWorkout()
		session.end()
		mensureLabel.setText("Parabéns!")
		distanceLabel.setText("✓")
		timer.invalidate()
		NotificationManager().singleNotification(title: "Treino concluído!",text: train.title)
	}

	func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) { }

	func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) { }
}
