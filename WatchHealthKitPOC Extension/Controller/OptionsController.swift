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

	var trains = [
		Train(type: .distance, targuet: 30),
		Train(type: .distance, targuet: 100),
		Train(type: .paces, targuet: 300),
		Train(type: .time, targuet: 60)
	]

	@IBOutlet weak var trainsTable: WKInterfaceTable!

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

	@IBAction func run5min() {
		let train = Train(type: .time, targuet: 60)
		pushController(withName:"InterfaceController", context: train)
	}

	

	//	MARK: - Life Cycle
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		NotificationManager().setupNotifications()

		trainsTable.setNumberOfRows(1, withRowType: "TrainRow")

		for index in 0..<trainsTable.numberOfRows {
			print("1")
			guard let controller = trainsTable.rowController(at: index) as? RowController else { continue }

			print("2")
			controller.title.setText(String(trains[index].targuet))
		}
	}

//	override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
//		let flight = flights[rowIndex]
//		presentController(withName: "Flight", context: flight)
//	}
}
