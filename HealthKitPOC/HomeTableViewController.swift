//
//  ViewController.swift
//  HealthKitPOC
//
//  Created by Matheus Oliveira on 04/11/20.
//

import UIKit
import UserNotifications
import WatchConnectivity

class HomeTableViewController: UITableViewController, WCSessionDelegate, UNUserNotificationCenterDelegate {

	var wcSession : WCSession! = nil

	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {

	}

	func sessionDidBecomeInactive(_ session: WCSession) {

	}

	func sessionDidDeactivate(_ session: WCSession) {

	}

	@IBAction func notificationAction(_ sender: Any) {
		print("notificação mandada")
		// Create Notification Content
		let notificationContent = UNMutableNotificationContent()

		// Configure Notification Content
		notificationContent.title = "TITLE"
		notificationContent.subtitle = "Subtitle"
		notificationContent.body = "Body"
		notificationContent.categoryIdentifier = "app.likedislike.ios10"

		// Add Trigger
		let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)

		// Create Notification Request
		let request = UNNotificationRequest(identifier: "app.likedislike.ios10",
											content: notificationContent, trigger: notificationTrigger)
		UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
			if let error = error {
				print("Error \(error)")
				// Something went wrong
			}
		})
	}

    override func viewDidLoad() {
        super.viewDidLoad()
        requestHKAutorization()

		wcSession = WCSession.default
		wcSession.delegate = self
		wcSession.activate()

		UNUserNotificationCenter.current().delegate = self

		authorizeNotification()
    }

	func authorizeNotification() {
		UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (success, error) in
			if let error = error {
				print("Error:- \(error)")
			} else if success == true {
				print("Permission Granted")
			}
		}
	}
    
    private func requestHKAutorization() {
        
        HealthKitSetupAssistant.authorizeHealthKit { (authorized, error) in
              
          guard authorized else {
                
            let baseMessage = "HealthKit authorization failed"
                
            if let error = error {
              print("\(baseMessage). Reason: \(error.localizedDescription)")
            } else {
              print(baseMessage)
            }
                
            return
          }
              
          print("HealthKit Successfully Authorized.")
        }
    }

	func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
		completionHandler([.alert])
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}

