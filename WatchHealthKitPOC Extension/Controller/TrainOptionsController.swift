//
//  TrainOptionsController.swift
//  WatchHealthKitPOC Extension
//
//  Created by Joao Flores on 29/11/20.
//

import WatchKit

class TrainOptionsController: WKInterfaceController {

	var isPaused = false

	@IBOutlet weak var playPauseButton: WKInterfaceButton!
	@IBAction func playPauseAction() {
		let userDefaults = UserDefaults.standard
		let decoded  = userDefaults.data(forKey: "teams")
		let decodedTeams = NSKeyedUnarchiver.unarchiveObject(with: decoded!) as! TrainPersistenceData

		let train =
			TrainStruct(type: TypeExerciseManager().stringToTrainType(type: decodedTeams.type),
						targuet: decodedTeams.targuet,
						title: decodedTeams.title,
						subtitle: decodedTeams.subtitle,
						currentProgress: decodedTeams.currentProgress,
						currentTime: decodedTeams.currentTime,
						isPaused: decodedTeams.isPaused ? false : true
			)

		WKInterfaceController.reloadRootPageControllers(withNames: ["TrainOptionsController", "InterfaceController"], contexts: [train, train], orientation: .horizontal, pageIndex: 0)
	}

	@IBAction func finishTrainAction() {
		WKInterfaceController.reloadRootPageControllers(withNames: ["OptionsController"], contexts: [], orientation: .horizontal, pageIndex: 0)
	}

	override func awake(withContext context: Any?) {
		if let getTrain = context as? TrainStruct { isPaused = getTrain.isPaused }

		isPaused ? playPauseButton.setTitle("Play") : playPauseButton.setTitle("Pause")
	}
}
//