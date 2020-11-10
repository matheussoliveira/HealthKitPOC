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

private enum ProfileDataError: Error {
  
    case missingBodyMassIndex
  
    var localizedDescription: String {
        switch self {
            case .missingBodyMassIndex:
            return "Unable to calculate body mass index with available profile data."
        }
    }
}

class HomeTableViewController: UITableViewController, WCSessionDelegate, UNUserNotificationCenterDelegate {
    
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userAge: UILabel!
    @IBOutlet weak var userBloodType: UILabel!
    @IBOutlet weak var userHeight: UILabel!
    @IBOutlet weak var userBiologicalSex: UILabel!
    @IBOutlet weak var userWeight: UILabel!
    @IBOutlet weak var userBodyMassIndex: UILabel!
    @IBOutlet weak var sleep: UILabel!
    
    private let userHealthProfile: UserHealthProfile = UserHealthProfile()
    
    let name = "Matheus Oliveira"
    
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
        loadAndDisplayAgeSexAndBloodType()
        loadAndDisplayMostRecentWeight()
        loadAndDisplayMostRecentHeight()
        loadAndDisplayMostRecentBMI()
        loadMostRecentSleepInfo()

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
    
    // MARK: - Load and display HealthKit information
    
    /// Retrieve age, biological sex and blood type from
    /// HealthKit and update labels.
    private func loadAndDisplayAgeSexAndBloodType() {
        
        do {
            userHealthProfile.age = try ProfileDataStore.getAge()
            userHealthProfile.biologicalSex = try ProfileDataStore.getBiologicalSex()
            userHealthProfile.bloodType = try ProfileDataStore.getBloodType()
        } catch let error {
            self.displayAlert(for: error)
        }
        self.updateLabels()
    }
    
    /// Query last height information from HealthKit and
    /// uptade labels.
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
    
    /// Query last weight information from HealthKit and
    /// uptade labels.
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
    
    /// Query last BMI information from HealthKit and
    /// uptade labels.
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
    
    /// Query last night sleep information from HealthKit
    private func loadMostRecentSleepInfo() {
        guard let sleepAnalysis = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            print("Sleep Analysis is not available")
            return
        }
        
        ProfileDataStore.getDayBeforeSample(for: sleepAnalysis) { [self] (samples, error) in
            guard let samples = samples else {
                if let error = error {
                    self.displayAlert(for: error)
                }
                return
            }
            
            self.buildAndUpdateSleepInfo(samples: samples)
        }
    }
    
    /// Transform sleep information on a redable string and update labels
    /// - Parameter samples: An array of samples containing sleep
    /// information with inBed and asleep values.
    private func buildAndUpdateSleepInfo(samples: [HKSample]) {
        var totalHours: Int = 0
        var totalMinutes: Int = 0
        
        for sample in samples {
            if let sample = sample as? HKCategorySample {
                if sample.value == HKCategoryValueSleepAnalysis.asleep.rawValue {
                    let diffComponents = Calendar.current.dateComponents([.hour, .minute],
                                                                         from: sample.startDate,
                                                                         to: sample.endDate)
                    let hours = diffComponents.hour
                    let minutes = diffComponents.minute
                    totalHours += hours ?? 0
                    totalMinutes += minutes ?? 0
                }
            }
        }
        
        let hours = totalMinutes / 60
        totalHours += hours
        totalMinutes -= hours * 60
        self.userHealthProfile.lastnightSleepDuration = "\(totalHours) horas e \(totalMinutes) minutos"
        self.updateLabels()
    }
    
    // MARK: - Update labels
    
    /// Update all labels with loaded HealthKit information
    private func updateLabels() {
        userName.text = name
        
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
        
        if let lastnightSleepDuration = userHealthProfile.lastnightSleepDuration {
            sleep.text = String(lastnightSleepDuration)
        }
    }
    
    // MARK: - Calculate BMI
    @IBAction func calculateBMI(_ sender: Any) {
        guard let bodyMassIndex = userHealthProfile.bodyMassIndex else {
          displayAlert(for: ProfileDataError.missingBodyMassIndex)
          return
        }
            
        ProfileDataStore.saveBodyMassIndexSample(bodyMassIndex: bodyMassIndex,
                                                 date: Date())
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
      
      alert.addAction(UIAlertAction(title: "Ok",
                                    style: .default,
                                    handler: nil))
      
      present(alert, animated: true, completion: nil)
    }

	func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
		completionHandler([.alert])
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
}
