//
//  TrainsListViewController.swift
//  HealthKitPOC
//
//  Created by Joao Flores on 11/12/20.
//

import UIKit
import WatchConnectivity
import SwiftyJSON

class TrainsListViewController: UIViewController, WCSessionDelegate {

	// MARK: - Outlets
	@IBOutlet weak var textField: UITextField!

	// MARK: - Variables
	var wcSession : WCSession! = nil

	// MARK: - Lifecycle
	override func viewDidLoad() {
		super.viewDidLoad()

		wcSession = WCSession.default
		wcSession.delegate = self
		wcSession.activate()
	}

	// MARK: - Button Actions
	@IBAction func sendText(_ sender: Any) {
//		let jsonObject: [Any]  = [
//			[
//				"type": "distance",
//				"targuet": 30,
//				"title": "Vida em movimento",
//				"subtitle": "Ande 30 metros",
//			],
//			[
//				"type": "distance",
//				"targuet": 100,
//				"title": "Vida em movimento",
//				"subtitle": "Ande 100 metros",
//			],
//			[
//				"type": "paces",
//				"targuet": 300,
//				"title": "Vida em movimento",
//				"subtitle": "Ande 300 passos",
//			],
//			[
//				"type": "time",
//				"targuet": 60,
//				"title": "Vida em movimento",
//				"subtitle": "Corra 1 minuto",
//			]
//		]
//
//		let message = ["message" : jsonObject]
//
//		wcSession.sendMessage(message, replyHandler: nil) { (error) in
//			print(error.localizedDescription)
//		}

		transferFile(file, metadata: fileMetaData)
	}

	// MARK: - WCSession Methods
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }

	func sessionDidBecomeInactive(_ session: WCSession) { }

	func sessionDidDeactivate(_ session: WCSession) { }
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
	#if os(watchOS)
	if WatchSettings.sharedContainerID.isEmpty == false {
		let defaults = UserDefaults(suiteName: WatchSettings.sharedContainerID)
		if let enabled = defaults?.bool(forKey: WatchSettings.useLogFileForFileTransfer), enabled {
			return Logger.shared.getFileURL()
		}
	}
	#endif

	// Use Info.plist for file transfer.
	// Change this to a bigger file to make the file transfer progress more obvious.
	//
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
