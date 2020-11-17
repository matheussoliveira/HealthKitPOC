//
//  OptionsController.swift
//  WatchHealthKitPOC Extension
//
//  Created by Joao Flores on 17/11/20.
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

class OptionsController: WKInterfaceController {

	//	MARK: - IBActions
	@IBAction func requestLocalNotification() {
		NotificationManager().singleNotification()
	}

	//	MARK: - Life Cycle
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)

		NotificationManager().setupNotifications()

	}
	
}
