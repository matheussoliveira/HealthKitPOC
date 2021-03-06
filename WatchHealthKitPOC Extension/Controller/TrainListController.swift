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
import SwiftyJSON

class TrainListController: WKInterfaceController, WCSessionDelegate {

	var lastMessage: CFAbsoluteTime = 0

	//	MARK: - Variables
	var trains = [
		TrainStruct(type: .distance, targuet: 30, title: "Vida em movimento", subtitle: "Ande 30 metros", currentProgress: 0.0, currentTime: 0, isPaused: false),

//		TrainStruct(type: .distance, targuet: 100, title: "Vida em movimento", subtitle: "Ande 100 metros", currentProgress: 0.0, currentTime: 0, isPaused: false),
//
//		TrainStruct(type: .paces, targuet: 300, title: "Vida em movimento", subtitle: "Ande 300 passos", currentProgress: 10.0, currentTime: 0, isPaused: false),
//
//		TrainStruct(type: .time, targuet: 60, title: "Vida em movimento", subtitle: "Corra 1 minuto", currentProgress: 0.0, currentTime: 0, isPaused: false),
	]
	
	//	MARK: - IBOutlet
	@IBOutlet weak var trainsTable: WKInterfaceTable!
	@IBOutlet weak var textLabel: WKInterfaceLabel!
	
	//	MARK: - IBActions
	@IBAction func requestLocalNotification() {
		print("requestLocalNotification")
		NotificationManager().singleNotification(title: "Beba agua", text: "Lembre-se de tomar 2 litros de água diariamente")
	}
	
	//	MARK: - Life Cycle
	override func awake(withContext context: Any?) {
		super.awake(withContext: context)
		NotificationManager().setupNotifications()
		
		trainsTable.setNumberOfRows(trains.count, withRowType: "RowController")
		
		for index in 0...(trains.count-1) {
			if let row = trainsTable.rowController(at: index) as? RowController {
				row.titleLabel.setText(trains[index].title)
				row.subtitleLabel.setText(trains[index].subtitle)
			}
		}

		textLabel.setText(String(UserDefaults.standard.integer(forKey: "lastUpdate")))
	}
	
	override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
		UserDefaults.standard.set(false, forKey: "Paused")
		WKInterfaceController.reloadRootPageControllers(withNames: ["TrainOptionsController", "InterfaceController"], contexts: [trains[rowIndex],trains[rowIndex]], orientation: .horizontal, pageIndex: 1)
	}

//	MARK: - WatchConnectivity

	// MARK: Variables
	var wcSession : WCSession!

	override func willActivate() {
		super.willActivate()

		wcSession = WCSession.default
		wcSession.delegate = self
		wcSession.activate()
	}

	// MARK: - WCSession Methods
	func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {

		let text = message["message"] as! [[String : Any]]

		for x in text {
			print(x["type"] as! String)
			print(x["targuet"] as! Int)
			print(x["title"] as! String)
			print(x["subtitle"] as! String)
			print("-------")

			trains.append(
				TrainStruct(type: .distance, targuet: x["targuet"] as! Int, title: x["title"] as! String, subtitle: x["subtitle"] as! String, currentProgress: 0.0, currentTime: 0, isPaused: false)
			)
		}

		trainsTable.setNumberOfRows(trains.count, withRowType: "RowController")

		for index in 0...(trains.count-1) {
			if let row = trainsTable.rowController(at: index) as? RowController {
				row.titleLabel.setText(trains[index].title)
				row.subtitleLabel.setText(trains[index].subtitle)
			}
		}

		let date = Date()
		let calendar = Calendar.current
//		let hour = calendar.component(.hour, from: date)
		let minutes = calendar.component(.minute, from: date)

		print(minutes)

		UserDefaults.standard.set(minutes,forKey: "lastUpdate")
		textLabel.setText(String(UserDefaults.standard.integer(forKey: "lastUpdate")))
	}

	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
}

