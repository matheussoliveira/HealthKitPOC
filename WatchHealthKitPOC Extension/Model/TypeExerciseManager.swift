//
//  TypeExerciseManager.swift
//  WatchHealthKitPOC Extension
//
//  Created by Joao Flores on 03/12/20.
//

/// class to convert training texts to be plotted in the interface

class TypeExerciseManager {

	func initialLabels(train: TrainStruct) -> (distance: String, mensure: String) {

		var distance = ""
		var mensure = ""

		switch train.type {
			case TrainType.paces:
				distance = "0"
				mensure = "passos"

			case TrainType.time:
				distance = "00:00:00"
				mensure = ""

			default: // distance
				distance = "0.0"
				mensure = "metros"
		}

		return (distance, mensure)

	}

	func populateTargetLabel(train: TrainStruct) -> String {

		switch train.type {

			case TrainType.time:
				let time = TimerManager().secondsToHoursMinutesSeconds (seconds : train.targuet)
				return time

			case TrainType.paces:
				return "\(train.targuet) passos"

			default: //distance
				return "\(train.targuet)m"
		}
	}

	func stringToTrainType(type: String) -> TrainType {
		switch type {

			case "time":
				return TrainType.time

			case "paces":
				return TrainType.paces

			default: //distance
				return TrainType.distance
		}
	}

	func trainTypeToString(type: TrainType) -> String {
		switch type {

			case TrainType.time:
				return "time"

			case TrainType.paces:
				return "paces"

			default: //distance
				return "distance"
		}
	}
}
