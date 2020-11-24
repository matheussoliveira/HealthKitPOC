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

	@IBAction func walk30m() {
		let train = Train(type: .distance, targuet: 30)
		pushController(withName: "InterfaceController", context: train)

	}

	@IBAction func walk100m() {
		let train = Train(type: .distance, targuet: 100)
		pushController(withName:"InterfaceController", context: train)

	}

	@IBAction func walk300paces() {
		let train = Train(type: .paces, targuet: 300)
		pushController(withName:"InterfaceController", context: train)

	}


	//	MARK: - Life Cycle
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		NotificationManager().setupNotifications()

	}

	
}
