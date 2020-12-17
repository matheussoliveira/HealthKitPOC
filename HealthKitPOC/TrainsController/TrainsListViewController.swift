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
				"type": "distance",
				"targuet": 30,
				"title": "Vida em movimento",
				"subtitle": "Ande 30 metros",
			],
			[
				"type": "distance",
				"targuet": 100,
				"title": "Vida em movimento",
				"subtitle": "Ande 100 metros",
			],
			[
				"type": "paces",
				"targuet": 300,
				"title": "Vida em movimento",
				"subtitle": "Ande 300 passos",
			],
			[
				"type": "time",
				"targuet": 60,
				"title": "Vida em movimento",
				"subtitle": "Corra 1 minuto",
			]
		]

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
