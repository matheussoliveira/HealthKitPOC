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
		let minutes = calendar.component(.minute, from: date)

		print(minutes)

		UserDefaults.standard.set(minutes,forKey: "lastUpdate")
		textLabel.setText(String(UserDefaults.standard.integer(forKey: "lastUpdate")))

		transferFile(file, metadata: fileMetaData)
	}

	func transferFile(_ file: URL, metadata: [String: Any]) {
		print("transferFile")
		var commandStatus = CommandStatus(command: .transferFile, phrase: .transferring)
//		commandStatus.timedColor = TimedColor(metadata)

		guard WCSession.default.activationState == .activated else {
			return handleSessionUnactivated(with: commandStatus)
		}
		commandStatus.fileTransfer = WCSession.default.transferFile(file, metadata: metadata)
		postNotificationOnMainQueueAsync(name: Notification.Name("DataDidFlow"), object: commandStatus)
	}

	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }
}

struct CommandStatus {
	var command: Command
	var phrase: Phrase
	var timedColor: TimedColor?
	var fileTransfer: WCSessionFileTransfer?
	var file: WCSessionFile?
	var userInfoTranser: WCSessionUserInfoTransfer?
	var errorMessage: String?

	init(command: Command, phrase: Phrase) {
		self.command = command
		self.phrase = phrase
	}
}

enum Command: String {
	case updateAppContext = "UpdateAppContext"
	case sendMessage = "SendMessage"
	case sendMessageData = "SendMessageData"
	case transferUserInfo = "TransferUserInfo"
	case transferFile = "TransferFile"
	case transferCurrentComplicationUserInfo = "TransferComplicationUserInfo"
}

enum Phrase: String {
	case updated = "Updated"
	case sent = "Sent"
	case received = "Received"
	case replied = "Replied"
	case transferring = "Transferring"
	case canceled = "Canceled"
	case finished = "Finished"
	case failed = "Failed"
}

private func handleSessionUnactivated(with commandStatus: CommandStatus) {
	var mutableStatus = commandStatus
	mutableStatus.phrase = .failed
	mutableStatus.errorMessage =  "WCSession is not activeted yet!"
	postNotificationOnMainQueueAsync(name: Notification.Name("DataDidFlow"), object: commandStatus)
}

private func postNotificationOnMainQueueAsync(name: NSNotification.Name, object: CommandStatus) {
	DispatchQueue.main.async {
		NotificationCenter.default.post(name: name, object: object)
	}
}

// Wrap a timed color payload dictionary with a stronger type.
struct TimedColor {
	var timeStamp: String
	var colorData: Data

//	var color: UIColor {
//		let optional = try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [UIColor.self], from: colorData)
//		guard let color = optional as? UIColor else {
//			fatalError("Failed to unarchive a UIClor object!")
//		}
//		return color
//	}
//	var timedColor: [String: Any] {
//		return [PayloadKey.timeStamp: timeStamp, PayloadKey.colorData: colorData]
//	}
//
//	init(_ timedColor: [String: Any]) {
//		guard let timeStamp = timedColor[PayloadKey.timeStamp] as? String,
//			  let colorData = timedColor[PayloadKey.colorData] as? Data else {
//			fatalError("Timed color dictionary doesn't have right keys!")
//		}
//		self.timeStamp = timeStamp
//		self.colorData = colorData
//	}
//
//	init(_ timedColor: Data) {
//		let data = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(timedColor)
//		guard let dictionary = data as? [String: Any] else {
//			fatalError("Failed to unarchive a timedColor dictionary!")
//		}
//		self.init(dictionary)
//	}
}

var file: URL {

	// Use Info.plist for file transfer.
	// Change this to a bigger file to make the file transfer progress more obvious.
	guard let url = Bundle.main.url(forResource: "Info", withExtension: "plist") else {
		fatalError("Failed to find Info.plist in current bundle!")
	}
	return url
}

var fileMetaData: [String: Any] {
	return timedColor()
}

private func timedColor() -> [String: Any] {
	let red = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
	let green = CGFloat(Float(arc4random()) / Float(UINT32_MAX))
	let blue = CGFloat(Float(arc4random()) / Float(UINT32_MAX))

	let randomColor = UIColor(red: red, green: green, blue: blue, alpha: 1)

	let data = try? NSKeyedArchiver.archivedData(withRootObject: randomColor, requiringSecureCoding: false)
	guard let colorData = data else { fatalError("Failed to archive a UIColor!") }

	let dateFormatter = DateFormatter()
	dateFormatter.timeStyle = .medium
	let timeString = dateFormatter.string(from: Date())

	return [PayloadKey.timeStamp: timeString, PayloadKey.colorData: colorData]
}

struct PayloadKey {
	static let timeStamp = "timeStamp"
	static let colorData = "colorData"
	static let isCurrentComplicationInfo = "isCurrentComplicationInfo"
}
