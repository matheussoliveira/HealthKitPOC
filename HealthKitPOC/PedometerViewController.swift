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
    var counter: Int = 0
    
    override func viewWillAppear(_ animated: Bool) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        startPedometer()
    }
    
    private func startPedometer() {
        DispatchQueue.background {
            self.pedometer.startUpdates(from: Date()) { (data, error) in
                self.counter = Int(truncating: data?.numberOfSteps ?? 0)
                DispatchQueue.main.async {
                    self.stepCounter.text = String(self.counter)
                }
            }
        }
    }
}

extension DispatchQueue {

    static func background(_ task: @escaping () -> ()) {
        DispatchQueue.global(qos: .background).async {
            task()
        }
    }

    static func main(_ task: @escaping () -> ()) {
        DispatchQueue.main.async {
            task()
        }
    }
}
