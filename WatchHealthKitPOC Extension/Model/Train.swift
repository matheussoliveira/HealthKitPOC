//
//  Train.swift
//  WatchHealthKitPOC Extension
//
//  Created by Joao Flores on 23/11/20.
//

import Foundation

enum TrainType {
	case paces //units
	case distance //meters
	case time //seconds
}

// caso seja necessário acrescentar um tipo de treino, é necessário aceescentá-lo também ao stringToTrainType e trainTypeToString em TypeExerciseManager
struct Train {
	var type: TrainType
	var targuet: Int
	var title: String
	var subtitle: String
	var currentProgress: Int
	var currentTime: Int //seconds
	var isPaused: Bool
}

//class persistenceData {
class Team: NSObject, NSCoding {
	var currentProgress: Int
	var targuet: Int
	var type: String
	var title: String
	var subtitle: String
	var currentTime: Int //seconds
	var isPaused: Bool

	init(currentProgress: Int, type: String, targuet: Int, title: String, subtitle: String, currentTime: Int, isPaused: Bool) {
		self.currentProgress = currentProgress
		self.type = type
		self.targuet = targuet
		self.title = title
		self.subtitle = subtitle
		self.currentTime = currentTime
		self.isPaused = isPaused
	}

	required convenience init(coder aDecoder: NSCoder) {
		let currentProgress = aDecoder.decodeInteger(forKey: "currentProgress")
		let targuet = aDecoder.decodeInteger(forKey: "targuet")
		let currentTime = aDecoder.decodeInteger(forKey: "currentTime")

		let isPaused = aDecoder.decodeBool(forKey: "isPaused")

		let type = aDecoder.decodeObject(forKey: "type") as! String
		let subtitle = aDecoder.decodeObject(forKey: "subtitle") as! String
		let title = aDecoder.decodeObject(forKey: "title") as! String

		self.init(currentProgress: currentProgress, type: type, targuet: targuet, title: title, subtitle: subtitle, currentTime: currentTime, isPaused: isPaused)
	}

	func encode(with aCoder: NSCoder) {
		aCoder.encode(currentProgress, forKey: "currentProgress")
		aCoder.encode(type, forKey: "type")
		aCoder.encode(targuet, forKey: "targuet")
		aCoder.encode(title, forKey: "title")
		aCoder.encode(subtitle, forKey: "subtitle")
		aCoder.encode(title, forKey: "title")
		aCoder.encode(currentTime, forKey: "currentTime")
		aCoder.encode(isPaused, forKey: "isPaused")
	}
}
