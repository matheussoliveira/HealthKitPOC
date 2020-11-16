//
//  PedometerViewController.swift
//  HealthKitPOC
//
//  Created by Matheus Oliveira on 16/11/20.
//

import UIKit
import CoreMotion

class PedometerViewController: UIViewController {

    @IBOutlet weak var stepCounter: UILabel!
    
    let pedometer = CMPedometer()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        startPedometer()
    }
    
    private func startPedometer() {
        pedometer.startUpdates(from: Date()) { (data, error) in
            DispatchQueue.main.async {
                self.stepCounter.text = "\(data?.numberOfSteps ?? 0)"
            }
        }
    }

}
