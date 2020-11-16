//
//  ViewController.swift
//  HealthKitPOC
//
//  Created by Matheus Oliveira on 04/11/20.
//

import UIKit
import HealthKit
import UserNotifications
import WatchConnectivity
import CoreMotion
    
class HomeTableViewController: UITableViewController {

//	MARK: - IBOutlets
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userAge: UILabel!
    @IBOutlet weak var userBloodType: UILabel!
    @IBOutlet weak var userHeight: UILabel!
    @IBOutlet weak var userBiologicalSex: UILabel!
    @IBOutlet weak var userWeight: UILabel!
    @IBOutlet weak var userBodyMassIndex: UILabel!

//	MARK: - IBActions
	@IBAction func notificationAction(_ sender: Any) {
		sendSimpleNotification()
	}

//	MARK: - Variables

    private let userHealthProfile: UserHealthProfile = UserHealthProfile()

    let name = "Matheus Oliveira"
    
    
    let pedometer = CMPedometer()

	var wcSession : WCSession! = nil

//	MARK: - LifeCycle
	override func viewDidLoad() {
		super.viewDidLoad()

		requestHKAutorization()
		loadAndDisplayAgeSexAndBloodType()
		loadAndDisplayMostRecentWeight()
		loadAndDisplayMostRecentHeight()
		loadAndDisplayMostRecentBMI()

		// Setup WatchConnectivity
		wcSession = WCSession.default
		wcSession.delegate = self
		wcSession.activate()

		// Setup Notifictions
		UNUserNotificationCenter.current().delegate = self
		authorizeNotification()
        
        startPedometer()
	}
    
    
    private func startPedometer() {
        pedometer.startUpdates(from: Date()) { (data, error) in
            DispatchQueue.main.async {
                self.userName.text = "\(data?.numberOfSteps ?? 0)"
            }
        }
    }
    
    private func loadAndDisplayAgeSexAndBloodType() {
        
        do {
            let userAgeSexAndBloodType = try ProfileDataStore.getAgeSexAndBloodType()
            userHealthProfile.age = userAgeSexAndBloodType.age
            userHealthProfile.biologicalSex = userAgeSexAndBloodType.biologicalSex
            userHealthProfile.bloodType = userAgeSexAndBloodType.bloodType
            updateLabels()
        } catch let error {
            self.displayAlert(for: error)
        }
    }
    
    private func loadAndDisplayMostRecentHeight() {
        
        guard let heightSampleType = HKSampleType.quantityType(forIdentifier: .height) else {
            print("Height Sample Type is no longer available in HealthKit")
            return
        }
            
        ProfileDataStore.getMostRecentSample(for: heightSampleType) { (sample, error) in
              
            guard let sample = sample else {
                
                if let error = error {
                    self.displayAlert(for: error)
                }
                
                return
            }
              
            let heightInMeters = sample.quantity.doubleValue(for: HKUnit.meter())
            self.userHealthProfile.height = heightInMeters
            self.updateLabels()
        }
    }
    
    private func loadAndDisplayMostRecentWeight() {
        
        guard let weightSampleType = HKSampleType.quantityType(forIdentifier: .bodyMass) else {
            print("Body Mass Sample Type is no longer available in HealthKit")
            return
        }
            
        ProfileDataStore.getMostRecentSample(for: weightSampleType) { (sample, error) in
              
            guard let sample = sample else {
                
                if let error = error {
                    self.displayAlert(for: error)
                }
                return
            }
              
            let weightInKilograms = sample.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
            self.userHealthProfile.weight = weightInKilograms
            self.updateLabels()
        }
    }
    
    private func loadAndDisplayMostRecentBMI() {
        guard let bmiSampleType = HKSampleType.quantityType(forIdentifier: .bodyMassIndex) else {
            print("Body mass is not available")
            return
        }
        
        ProfileDataStore.getMostRecentSample(for: bmiSampleType) { (sample, error) in
            guard let sample = sample else {
                if let error = error {
                    self.displayAlert(for: error)
                }
                return
            }
            let bodyMassIndex = sample.quantity.doubleValue(for: HKUnit.count())
            self.userHealthProfile.bodyMassIndex = bodyMassIndex
            self.updateLabels()
            
        }
    }
    
    // MARK: - Update labels
    private func updateLabels() {
        
        if let age = userHealthProfile.age {
          userAge.text = "\(age)"
        }

        if let biologicalSex = userHealthProfile.biologicalSex {
            userBiologicalSex.text = biologicalSex.stringRepresentation
        }

        if let bloodType = userHealthProfile.bloodType {
            userBloodType.text = bloodType.stringRepresentation
        }
        
        if let height = userHealthProfile.height {
            let heightFormatter = LengthFormatter()
            userHeight.text = heightFormatter.string(for: height)
        }
        
        if let weight = userHealthProfile.weight {
            let weightFormatter = MassFormatter()
            weightFormatter.isForPersonMassUse = true
            userWeight.text = weightFormatter.string(for: weight)
        }
        
        if let bodyMassIndex = userHealthProfile.bodyMassIndex {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = NumberFormatter.Style.decimal
            numberFormatter.roundingMode = NumberFormatter.RoundingMode.halfUp
            numberFormatter.maximumFractionDigits = 2
            userBodyMassIndex.text = numberFormatter.string(from: NSNumber(value: bodyMassIndex))
        }
        
        userName.text = name
    }
    
    // MARK: - HealthKit authorization
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
    
    // MARK: - Display alerts
    private func displayAlert(for error: Error) {
      
      let alert = UIAlertController(title: nil,
                                    message: error.localizedDescription,
                                    preferredStyle: .alert)
      
      alert.addAction(UIAlertAction(title: "O.K.",
                                    style: .default,
                                    handler: nil))
      
      present(alert, animated: true, completion: nil)
    }
}

//	MARK: - WCSessionDelegate Handle Extension
extension HomeTableViewController: WCSessionDelegate {
	func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) { }

	func sessionDidBecomeInactive(_ session: WCSession) { }

	func sessionDidDeactivate(_ session: WCSession) { }
}

//	MARK: - UNUserNotificationCenterDelegate Handle Extension
extension HomeTableViewController: UNUserNotificationCenterDelegate {
	fileprivate func sendSimpleNotification() {
		// Create Notification Content
		let notificationContent = UNMutableNotificationContent()

		// Configure Notification Content
		notificationContent.title = "TITLE"
		notificationContent.subtitle = "Subtitle"
		notificationContent.body = "Body"
		notificationContent.categoryIdentifier = "com.poc.HealthKitPOC2"

		// Add Trigger
		let notificationTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)

		// Create Notification Request
		let request = UNNotificationRequest(identifier: "com.poc.HealthKitPOC2",
											content: notificationContent, trigger: notificationTrigger)
		UNUserNotificationCenter.current().add(request, withCompletionHandler: { (error) in
			if let error = error {
				print("Error \(error)")
			}
		})
	}

	func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
		completionHandler([.alert])
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
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
}


