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
    var backgroundMode: Bool = false
    var counter: Int = 0 {
        didSet {
            if !backgroundMode {
                DispatchQueue.main.async {
                    self.stepCounter.text = String(self.counter)
                }
            }
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        // TODO: Remove observers
        NotificationCenter.default.addObserver(
            self,
            selector:#selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector:#selector(didResumeApp),
            name: UIApplication.didBecomeActiveNotification,
            object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        startPedometer()
    }
    
    private func startPedometer() {
        DispatchQueue.background {
            self.pedometer.startUpdates(from: Date()) { (data, error) in
                self.counter = Int(truncating: data?.numberOfSteps ?? 0)
            }
        }
    }
    
    @objc func didEnterBackground() {
        self.backgroundMode = true
    }
    
    @objc func didResumeApp() {
        self.backgroundMode = false
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
