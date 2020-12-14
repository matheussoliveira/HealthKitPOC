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
		let jsonObject: [Any]  = [
			[
				"type_id": "oi",
				"model_id": "oi",
				"transfer": "oi",
				"hourly": "oi",
				"custom": "oi",
				"device_type":"iOS"
			]
		]

		print("--- enviando")
		let message = ["message" : jsonObject]

		wcSession.sendMessage(message, replyHandler: nil) { (error) in
			print(error.localizedDescription)
		}

	}

	// MARK: - WCSession Methods
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }

	func sessionDidBecomeInactive(_ session: WCSession) { }

	func sessionDidDeactivate(_ session: WCSession) { }
}
