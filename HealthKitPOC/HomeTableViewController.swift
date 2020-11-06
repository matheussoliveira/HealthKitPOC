//
//  ViewController.swift
//  HealthKitPOC
//
//  Created by Matheus Oliveira on 04/11/20.
//

import UIKit
import HealthKit

class HomeTableViewController: UITableViewController {
    
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userAge: UILabel!
    @IBOutlet weak var userBloodType: UILabel!
    @IBOutlet weak var userHeight: UILabel!
    @IBOutlet weak var userBiologicalSex: UILabel!
    @IBOutlet weak var userWeight: UILabel!
    @IBOutlet weak var userBodyMassIndex: UILabel!
    
    private let userHealthProfile: UserHealthProfile = UserHealthProfile()
    
    let name = "Matheus Oliveira"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        requestHKAutorization()
        loadAndDisplayAgeSexAndBloodType()
        loadAndDisplayMostRecentWeight()
        loadAndDisplayMostRecentHeight()
        loadAndDisplayMostRecentBMI()
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
