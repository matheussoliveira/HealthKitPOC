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

	//	MARK: - Variables

	var timerCounterAnimation = 0
	var timerAnimation = Timer()

	let healthStore = HKHealthStore()
	var session: HKWorkoutSession!
	var builder: HKLiveWorkoutBuilder!

	var heartrate: Double = 0
	var distance: Double = 0
	var timerCounter = 0
	var steps: Int = 0
	var timer = Timer()

	var running: Bool = false
	var finished: Bool = false

	var start: Date = Date()
	var cancellable: Cancellable?

	let pedometer = CMPedometer()

	var train = TrainStruct(type: .distance, targuet: 0, title: "----", subtitle: "----", currentProgress: 0, currentTime: 0, isPaused: false)

	//	MARK: - IBOutlets
	@IBOutlet weak var heartrateLabel: WKInterfaceLabel!
	@IBOutlet weak var distanceLabel: WKInterfaceLabel!
	@IBOutlet weak var backgroundGroup: WKInterfaceGroup!
	@IBOutlet weak var mensureLabel: WKInterfaceLabel!
	@IBOutlet weak var target: WKInterfaceLabel!
	@IBOutlet weak var timerLabel: WKInterfaceLabel!
	
	//	MARK: - IBActions
	@IBAction func startWorkoutAction() {
		if !train.isPaused && !running {
			let startLabels = TypeExerciseManager().initialLabels(train: train)
			mensureLabel.setText(startLabels.mensure)

			running = true
			
			endWorkout()
			startWorkout()
			startTimer()
			resetWorkout()
		}
	}

	//	MARK: - Life Cycle
	
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		
		if let errorMsg = HealthKitManager().requestAuthorization() { heartrateLabel.setText(errorMsg) }

		if let getTrain = context as? TrainStruct { train = getTrain }
		
		target.setText("meta: \(TypeExerciseManager().populateTargetLabel(train: train))")
		mensureLabel.setText("")
		
		if(train.isPaused) {
			resetWorkout()
			mensureLabel.setText("Pause")
			startWorkout()
		}
		else if(train.currentTime == 0 && train.currentTime == 0) {
			distanceLabel.setText("Começar")
			startWorkout()
		}
		else {
			resetWorkout()
			let startLabels = TypeExerciseManager().initialLabels(train: train)
			mensureLabel.setText(startLabels.mensure)
			startWorkoutAction()
		}
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
	
	//	MARK: - Timer
	func startTimer() {
		timer.invalidate()
		
		timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
	}
	
	@objc func timerAction() {
		print("--------222222---------")
		timerCounter += 1
		timerLabel.setText(TimerManager().secondsToHoursMinutesSeconds(seconds: timerCounter))
		
		if(train.type == .time && running) {
			
			updateRing(currentProgress: Double(timerCounter),
					   text: TimerManager().secondsToHoursMinutesSeconds(seconds: timerCounter))
		}
	}

	func startTimerAnimation() {
		print("--------111111---------")
		timerCounterAnimation = 0
		timer.invalidate()
		timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerAction), userInfo: nil, repeats: true)
	}

	@objc func timerActionAnimation() {
		print("--------222222---------")
		timerCounterAnimation += 1
		backgroundGroup.setBackgroundImageNamed("DoneAnimation\(timerCounterAnimation)")
	}
	
	// MARK: - Ring
	func updateRing(currentProgress: Double, text: String) {
		distanceLabel.setText("\(currentProgress)")
		print(currentProgress)
		let currentPercentage = Int((currentProgress / Double(train.targuet))*100)
		
		if(currentPercentage >= 100) {
			finishTrain()
		}
		else {
			backgroundGroup.setBackgroundImageNamed("Progress-\(currentPercentage)")
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
		
		if (train.type == TrainType.paces) { startPedometer() }
	}
	
	func endWorkout() {
		session?.end()
		cancellable?.cancel()
	}
	
	func resetWorkout() {
		DispatchQueue.main.async {
			self.distance = self.train.currentProgress
			self.timerCounter = self.train.currentTime
			self.timerLabel.setText(TimerManager().secondsToHoursMinutesSeconds(seconds: self.timerCounter))
			self.updateRing(currentProgress: self.distance, text: "\(self.distance)")
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
					
				case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
					let meterUnit = HKUnit.meter()
					let value = statistics.sumQuantity()?.doubleValue(for: meterUnit)
					let roundedValue = Double( round( 1 * value! ) / 1 )
					self.distance = roundedValue + self.train.currentProgress
					return
					
				default:
					return
			}
		}
	}
	
	func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
		
		for type in collectedTypes {
			guard let quantityType = type as? HKQuantityType else { return }
			
			let statistics = workoutBuilder.statistics(for: quantityType)
			updateForStatistics(statistics)
		}
		
		updateMetersAndHeartRate()
	}
	
	func startPedometer() {
		pedometer.startUpdates(from: Date()) { (data, error) in self.updatePedometer(data) }
	}
	
	func updateMetersAndHeartRate() {
		if(train.type == .distance && running && !self.finished) { updateRing(currentProgress: distance, text: "\(distance)") }
		heartrateLabel.setText("\(heartrate)")
	}
	
	func updatePedometer(_ data: CMPedometerData?) {
		if(self.train.type == .paces && self.running && !self.finished) {
			let numberOfSteps = Double(truncating:data?.numberOfSteps ?? 0)
			let numberOfStepsCurrent = numberOfSteps + train.currentProgress
			self.updateRing(currentProgress: numberOfStepsCurrent, text: "\(numberOfSteps)")
		}
	}
	
	func finishTrain() {
		backgroundGroup.setBackgroundImageNamed("Progress-101")
		endWorkout()
		mensureLabel.setText("Parabéns!")
		distanceLabel.setText("✓")
		timer.invalidate()
		NotificationManager().singleNotification(title: "Treino concluído!",text: train.title)
		finished = true
		startTimerAnimation()
	}


	
	func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) { }
	func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) { }
	func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) { }
}
