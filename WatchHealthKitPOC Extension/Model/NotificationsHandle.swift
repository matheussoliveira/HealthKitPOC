//
//  NotificationsHandle.swift
//  WatchHealthKitPOC Extension
//
//  Created by Joao Flores on 11/11/20.
//

import Foundation
import WatchKit
import Foundation
import HealthKit
import UserNotifications
import WatchConnectivity

class NotificationsHandle {

	func setupNotifications() {
		UNUserNotificationCenter.current()

		let center = UNUserNotificationCenter.current()
		center.requestAuthorization(options: [.alert, .sound, .badge, .provisional]) { granted, error in

			if let error = error {
				print(error.localizedDescription)
			}
		}
	}
}
