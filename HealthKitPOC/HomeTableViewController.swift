//
//  ViewController.swift
//  HealthKitPOC
//
//  Created by Matheus Oliveira on 04/11/20.
//

import UIKit

class HomeTableViewController: UITableViewController {
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        requestHKAutorization()
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


}

