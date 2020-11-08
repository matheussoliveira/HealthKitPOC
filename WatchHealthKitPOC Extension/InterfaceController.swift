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

class InterfaceController: WKInterfaceController {

//	MARK: - IBOutlets
	@IBOutlet weak var label: WKInterfaceLabel!
	@IBOutlet weak var button: WKInterfaceButton!

	//	MARK: - IBActions
	@IBAction func requestLocalNotification() {
		singleNotification()
	}

	@IBAction func startAction() {
		print(#function)
		if self.workoutSession == nil {
			let config = HKWorkoutConfiguration()
			config.activityType = .other
			do {
				self.workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: config)
				self.workoutSession?.delegate = self
				self.workoutSession?.startActivity(with: nil)
				label.setText("loading...")
			}
			catch let e {
				print(e)
			}
		}
		else {
			self.workoutSession?.stopActivity(with: nil)
		}
	}

//	MARK: - Variables
	let fontSize = UIFont.systemFont(ofSize: 60)

	let healthStore = HKHealthStore()
	let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
	let heartRateUnit = HKUnit(from: "count/min")
	var heartRateQuery: HKQuery?

	var workoutSession: HKWorkoutSession?

//	MARK: - Life Cycle
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		// Configure interface objects here.
		print(#function)

		guard HKHealthStore.isHealthDataAvailable() else {
			label.setText("HealthKit is not available ")
			print("HealthKit is not available on this device.")
			return
		}

		let dataTypes = Set([heartRateType])
		self.healthStore.requestAuthorization(toShare: nil, read: dataTypes) { (success, error) in
			guard success else {
				self.label.setText("Requests permission is not allowed.")
				print("Requests permission is not allowed.")
				return
			}
		}

		setupNotifications()
		reminderNotification()
	}

	override func willActivate() {
		// This method is called when watch view controller is about to be visible to user
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
		content.categoryIdentifier = UserNotificationCategory.primaryMode.rawValue

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
		let attrStr = NSAttributedString(string: text, attributes:[NSAttributedString.Key.font:self.fontSize])
		DispatchQueue.main.async {
			self.label.setAttributedText(attrStr)
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
			self.button.setTitle("Stop")
		}
	}

	func stopQuery() {
		print(#function)
		healthStore.stop(self.heartRateQuery!)
		heartRateQuery = nil
		DispatchQueue.main.async {
			self.button.setTitle("Start")
			self.label.setText("")
		}
	}
}
