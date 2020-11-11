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

class InterfaceController: WKInterfaceController {

//	MARK: - IBOutlets
	@IBOutlet weak var heartRateLabel: WKInterfaceLabel!
	@IBOutlet weak var startButton: WKInterfaceButton!
	@IBOutlet weak var cronometerLabel: WKInterfaceLabel!

	//	MARK: - IBActions
	@IBAction func requestLocalNotification() {
		singleNotification()
	}

	@IBAction func startAction() {
		startStopButtonPressed()
		print(#function)
		if self.workoutSession == nil {
			let config = HKWorkoutConfiguration()
			config.activityType = .other
			do {
				self.workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: config)
				self.workoutSession?.delegate = self
				self.workoutSession?.startActivity(with: nil)
				heartRateLabel.setText("loading...")
			}
			catch let e {
				print(e)
			}
			beginWorkout()
		}
		else {
			self.workoutSession?.stopActivity(with: nil)
			finishWorkout()
			guard let currentWorkout = session.completeWorkout else {
				fatalError("Shouldn't be able to press the done button without a saved workout.")
			}
			WorkoutDataStore.save(prancerciseWorkout: currentWorkout) { (success, error) in
				print("erro!!!!!!")
			}
			print("totalEnergyBurned")
			print(currentWorkout.totalEnergyBurned)
			print("-----------------")
		}
		cronometerLabel.setText("0")
		timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
			self.timeCurrent += 1
			self.cronometerLabel.setText(String(self.timeCurrent))
		}
	}

	private class func samples(for workout: PrancerciseWorkout) -> [HKSample] {
		//1. Verify that the energy quantity type is still available to HealthKit.
		guard let energyQuantityType = HKSampleType.quantityType(
				forIdentifier: .activeEnergyBurned) else {
			fatalError("*** Energy Burned Type Not Available ***")
		}

		//2. Create a sample for each PrancerciseWorkoutInterval
		let samples: [HKSample] = workout.intervals.map { interval in
			let calorieQuantity = HKQuantity(unit: .kilocalorie(),
											 doubleValue: interval.totalEnergyBurned)

			return HKCumulativeQuantitySeriesSample(type: energyQuantityType,
													quantity: calorieQuantity,
													start: interval.start,
													end: interval.end)
		}

		return samples
	}
	
//	MARK: - Variables

	let healthStore = HKHealthStore()
	let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
	let heartRateUnit = HKUnit(from: "count/min")
	var heartRateQuery: HKQuery?

	var workoutSession: HKWorkoutSession?

	private var timer: Timer!

	var session = WorkoutSession()

	var timeCurrent = 0

//	MARK: - Life Cycle
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		print(#function)

		guard HKHealthStore.isHealthDataAvailable() else {
			heartRateLabel.setText("HealthKit is not available ")
			print("HealthKit is not available on this device.")
			return
		}

		let dataTypes = Set([heartRateType])
		self.healthStore.requestAuthorization(toShare: nil, read: dataTypes) { (success, error) in
			guard success else {
				self.heartRateLabel.setText("Requests permission is not allowed.")
				print("Requests permission is not allowed.")
				return
			}
		}

		setupNotifications()
		reminderNotification()
		session.clear()
	}

	private lazy var startTimeFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "HH:mm"
		return formatter
	}()

	private lazy var durationFormatter: DateComponentsFormatter = {
		let formatter = DateComponentsFormatter()
		formatter.unitsStyle = .positional
		formatter.allowedUnits = [.minute, .second]
		formatter.zeroFormattingBehavior = [.pad]
		return formatter
	}()

	func beginWorkout() {
		session.start()
	}

	func finishWorkout() {
		session.end()
	}

	func startStopButtonPressed() {
		switch session.state {
			case .notStarted, .finished:
				print("asd")
			case .active:
				finishWorkout()
		}
	}

	override func willActivate() {
		super.willActivate()
		print(#function)
	}

	override func didDeactivate() {
		super.didDeactivate()
		print(#function)
	}

//	MARK: - Notifications
	fileprivate func reminderNotification() {
		let content = UNMutableNotificationContent()
		content.title = "Beba Água"
		content.body = "Atalinha recomenda 2 litros de água diariamente"
		content.sound = UNNotificationSound.default

		let gregorian = Calendar(identifier: .gregorian)
		let now = Date()
		var components = gregorian.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)

		// Change the time to 7:00:00 in your locale
		components.hour = 18
		components.minute = 0
		components.second = 0

		let date = gregorian.date(from: components)!

		let triggerDaily = Calendar.current.dateComponents([.hour,.minute,.second,], from: date)
		let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDaily, repeats: true)


		let request = UNNotificationRequest(identifier: "reminder", content: content, trigger: trigger)
		print("INSIDE NOTIFICATION")

		UNUserNotificationCenter.current().add(request, withCompletionHandler: {(error) in
			if let error = error {
				print("SOMETHING WENT WRONG")
			}
		})
	}

	fileprivate func singleNotification() {
		let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
		let content = UNMutableNotificationContent()
		content.title = NSLocalizedString("Beba Água", comment: "Local Notification Title")
		content.body = NSLocalizedString("Atalinha recomenda 2 litros de água diariamente", comment: "Local Notification Body")
		content.categoryIdentifier = "Local"

		let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

		UNUserNotificationCenter.current().add(request)
	}

	fileprivate func setupNotifications() {
		UNUserNotificationCenter.current()

		let center = UNUserNotificationCenter.current()
		center.requestAuthorization(options: [.alert, .sound, .badge, .provisional]) { granted, error in

			if let error = error {
				print(error.localizedDescription)
			}
		}
	}
}

extension InterfaceController {

	private func createStreamingQuery() -> HKQuery {
		print(#function)
		let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: [])
		let query = HKAnchoredObjectQuery(type: heartRateType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, samples, deletedObjects, anchor, error) in
			self.addSamples(samples: samples)
		}
		query.updateHandler = { (query, samples, deletedObjects, anchor, error) in
			self.addSamples(samples: samples)
		}
		return query
	}

	private func addSamples(samples: [HKSample]?) {
		print(#function)
		guard let samples = samples as? [HKQuantitySample] else { return }
		guard let quantity = samples.last?.quantity else { return }

		let text = String(quantity.doubleValue(for: self.heartRateUnit))

		let attrStr = NSAttributedString(string: text)
		DispatchQueue.main.async {
			self.heartRateLabel.setAttributedText(attrStr)
		}
	}
}

extension InterfaceController: HKWorkoutSessionDelegate {

	func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
		print(#function)
		switch toState {
			case .running:
				print("Session status to running")
				self.startQuery()
			case .stopped:
				print("Session status to stopped")
				self.stopQuery()
				self.workoutSession?.end()
			case .ended:
				print("Session status to ended")
				self.workoutSession = nil
			default:
				print("Other status \(toState.rawValue)")
		}
	}

	func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
		print("workoutSession delegate didFailWithError \(error.localizedDescription)")
	}

	func startQuery() {
		print(#function)
		heartRateQuery = self.createStreamingQuery()
		healthStore.execute(self.heartRateQuery!)
		DispatchQueue.main.async {
			self.startButton.setTitle("Stop")
		}
	}

	func stopQuery() {
		print(#function)
		healthStore.stop(self.heartRateQuery!)
		heartRateQuery = nil
		DispatchQueue.main.async {
			self.startButton.setTitle("Start")
			self.heartRateLabel.setText("")
		}
	}
}
