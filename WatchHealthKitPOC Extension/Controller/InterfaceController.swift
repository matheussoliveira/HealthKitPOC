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

class InterfaceController: WKInterfaceController, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {

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

	//	MARK: - Life Cycle
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)

		guard HKHealthStore.isHealthDataAvailable() else {
			heartrateLabel.setText("HealthKit is not available ")
			print("HealthKit is not available on this device.")
			return
		}

		NotificationManager().setupNotifications()
		NotificationManager().setReminderNotification()

		requestAuthorization()
		startWorkout()
        
        
        pedometer.startUpdates(from: Date()) { (data, error) in
            self.stepCounter.setText("\(data?.numberOfSteps ?? 0) passos")
        }
	}

	override func willActivate() {
		print(#function)
	}

	override func didDeactivate() {
		super.didDeactivate()
	}

//
//	fileprivate func singleNotification() {
//		print("single notification pressed")
//		let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
//		let content = UNMutableNotificationContent()
//		content.title = NSLocalizedString("Beba Água", comment: "Local Notification Title")
//		content.body = NSLocalizedString("Atalinha recomenda 2 litros de água diariamente", comment: "Local Notification Body")
//		content.categoryIdentifier = "Local"
//
//		let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
//
//		UNUserNotificationCenter.current().add(request)
//	}
//
//	fileprivate func setupNotifications() {
//		UNUserNotificationCenter.current()
//
//		let center = UNUserNotificationCenter.current()
//		center.requestAuthorization(options: [.alert, .sound, .badge, .provisional]) { granted, error in
//
//			if let error = error {
//				print(error.localizedDescription)
//			}
//		}
//	}

//	MARK: - Workout
	// Set up and start the timer.
	func setUpTimer() {
		start = Date()
		cancellable = Timer.publish(every: 0.1, on: .main, in: .default)
			.autoconnect()
			.sink { [weak self] _ in
				guard let self = self else { return }
				self.elapsedSeconds = self.incrementElapsedTime()
			}
	}

	// Calculate the elapsed time.
	func incrementElapsedTime() -> Int {
		let runningTime: Int = Int(-1 * (self.start.timeIntervalSinceNow))
		return self.accumulatedTime + runningTime
	}

	// Request authorization to access HealthKit.
	func requestAuthorization() {
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

	// Provide the workout configuration.
	func workoutConfiguration() -> HKWorkoutConfiguration {
		/// - Tag: WorkoutConfiguration
		let configuration = HKWorkoutConfiguration()
		configuration.activityType = .running
		configuration.locationType = .outdoor

		return configuration
	}

	// Start the workout.
	func startWorkout() {
		// Start the timer.
		setUpTimer()
		self.running = true

		// Create the session and obtain the workout builder.
		/// - Tag: CreateWorkout
		do {
			session = try HKWorkoutSession(healthStore: healthStore, configuration: self.workoutConfiguration())
			builder = session.associatedWorkoutBuilder()
		} catch {
			// Handle any exceptions.
			return
		}

		// Setup session and builder.
		session.delegate = self
		builder.delegate = self

		// Set the workout builder's data source.
		/// - Tag: SetDataSource
		builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
													 workoutConfiguration: workoutConfiguration())

		// Start the workout session and begin data collection.
		/// - Tag: StartSession
		session.startActivity(with: Date())
		builder.beginCollection(withStart: Date()) { (success, error) in
			// The workout has started.
			print("1")
		}
	}

	// MARK: - State Control
	func togglePause() {
		// If you have a timer, then the workout is in progress, so pause it.
		if running == true {
			self.pauseWorkout()
		} else {// if session.state == .paused { // Otherwise, resume the workout.
			resumeWorkout()
		}
	}

	func pauseWorkout() {
		// Pause the workout.
		session.pause()
		// Stop the timer.
		cancellable?.cancel()
		// Save the elapsed time.
		accumulatedTime = elapsedSeconds
		running = false
	}

	func resumeWorkout() {
		// Resume the workout.
		session.resume()
		// Start the timer.
		setUpTimer()
		running = true
	}

	func endWorkout() {
		// End the workout session.
		session.end()
		cancellable?.cancel()
	}

	func resetWorkout() {
		// Reset the published values.
		DispatchQueue.main.async {
			self.elapsedSeconds = 0
			self.activeCalories = 0
			self.heartrate = 0
			self.distance = 0
		}
	}

	// MARK: - Update the UI
	// Update the published values.
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
		// Wait for the session to transition states before ending the builder.
		/// - Tag: SaveWorkout
		if toState == .ended {
			print("The workout has now ended.")
			builder.endCollection(withEnd: Date()) { (success, error) in
				self.builder.finishWorkout { (workout, error) in
					// Optionally display a workout summary to the user.
					self.resetWorkout()
				}
			}
		}
	}

	func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) { }

	func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
		for type in collectedTypes {
			guard let quantityType = type as? HKQuantityType else {
				return // Nothing to do.
			}

			/// - Tag: GetStatistics
			let statistics = workoutBuilder.statistics(for: quantityType)

			// Update the published values.
			updateForStatistics(statistics)
		}

		heartrateLabel.setText("\(heartrate) bpm")
		activeCaloriesLabel.setText("\(activeCalories) cal")
		distanceLabel.setText("\(distance) m")
		timerLabel.setText(secondsToHoursMinutesSeconds(seconds: elapsedSeconds))
	}

	func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) { }

	func secondsToHoursMinutesSeconds (seconds : Int) -> String {

		let hours = String(format: "%02d", seconds / 3600)
		let minuts = String(format: "%02d", (seconds % 3600) / 60)
		let seconds = String(format: "%02d", (seconds % 3600) % 60)
		return hours + ":" + minuts + ":" + seconds
	}
}
