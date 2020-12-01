//
//  TrainOptionsController.swift
//  WatchHealthKitPOC Extension
//
//  Created by Joao Flores on 29/11/20.
//

import WatchKit

class TrainOptionsController: WKInterfaceController {

	@IBAction func playPauseAction() {
		print("clicou")
		let teams = [Team(id: 1, name: "team1", shortname: "t1"), Team(id: 2, name: "team2", shortname: "t2")]

		var userDefaults = UserDefaults.standard
		let encodedData: Data = NSKeyedArchiver.archivedData(withRootObject: teams)
		userDefaults.set(encodedData, forKey: "teams")
		userDefaults.synchronize()

		let decoded  = userDefaults.data(forKey: "teams")
		let decodedTeams = NSKeyedUnarchiver.unarchiveObject(with: decoded!) as! [Team]

		for tea in decodedTeams {
			print(tea.id)
			print(tea.name)
			print(tea.shortname)
		}
	}

	@IBAction func finishTrainAction() {
		WKInterfaceController.reloadRootPageControllers(withNames: ["OptionsController"], contexts: [], orientation: .horizontal, pageIndex: 0)
	}
}

class Team: NSObject, NSCoding {
	var currentProgress: Int
	var isPaused: Bool
	var type: TrainType
	var targuet: Int
	var title: String
	var subtitle: String

	init(currentProgress: Int, isPaused: Bool, type: TrainType, targuet: Int, title: String, subtitle: String) {
		self.currentProgress = currentProgress
		self.isPaused = isPaused
		self.type = type
		self.targuet = targuet
		self.title = title
		self.subtitle = subtitle
	}

	required convenience init(coder aDecoder: NSCoder) {
		let id = aDecoder.decodeInteger(forKey: "id")
		let name = aDecoder.decodeObject(forKey: "name") as! String
		let shortname = aDecoder.decodeObject(forKey: "shortname") as! String

		let id = aDecoder.decodeInteger(forKey: "id")
		let name = aDecoder.decodeObject(forKey: "name") as! String
		let shortname = aDecoder.decodeObject(forKey: "shortname") as! String
		
		self.init(id: id, name: name, shortname: shortname)
	}

	func encode(with aCoder: NSCoder) {
		aCoder.encode(id, forKey: "id")
		aCoder.encode(name, forKey: "name")
		aCoder.encode(shortname, forKey: "shortname")
	}
}
