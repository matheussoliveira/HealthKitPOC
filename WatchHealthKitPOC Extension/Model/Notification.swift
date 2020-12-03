//
//  NotificationManager.swift
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

/// Handle notifications to reminder or to alert exercise finished

class NotificationManager {
	func singleNotification(title: String, text: String) {
		let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
		let content = UNMutableNotificationContent()
		content.title = NSLocalizedString(title, comment: "title")
		content.body = NSLocalizedString(text, comment: "text")
		content.categoryIdentifier = "Local"

		let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

		UNUserNotificationCenter.current().add(request)
	}

	func setupNotifications() {
		UNUserNotificationCenter.current()

		let center = UNUserNotificationCenter.current()
		center.requestAuthorization(options: [.alert, .sound, .badge, .provisional]) { granted, error in

			if let error = error {
				print(error.localizedDescription)
			}
		}
	}

	func setReminderNotification() {
		let content = UNMutableNotificationContent()
		content.title = "Beba Água"
		content.body = "Atalinha recomenda 2 litros de água diariamente"
		content.sound = UNNotificationSound.default

		let gregorian = Calendar(identifier: .gregorian)
		let now = Date()
		var components = gregorian.dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)

		components.hour = 13
		components.minute = 27
		components.second = 0

		let date = gregorian.date(from: components)!

		let triggerDaily = Calendar.current.dateComponents([.hour,.minute,.second,], from: date)
		let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDaily, repeats: true)


		let request = UNNotificationRequest(identifier: "reminder", content: content, trigger: trigger)

		UNUserNotificationCenter.current().add(request, withCompletionHandler: {(error) in
			if error != nil {
				print(error.debugDescription)
			}
		})
	}
}

