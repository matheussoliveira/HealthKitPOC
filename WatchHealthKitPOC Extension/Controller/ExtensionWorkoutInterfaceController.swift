//
//  ExtensionWorkoutInterfaceController.swift
//  WatchHealthKitPOC Extension
//
//  Created by Joao Flores on 06/11/20.
//

import Foundation
import HealthKit
import Combine

extension InterfaceController: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
	func workoutConfiguration() -> HKWorkoutConfiguration {
		let configuration = HKWorkoutConfiguration()
		configuration.activityType = .running
		configuration.locationType = .outdoor

		return configuration
	}

	//	MARK: - Workout
	func startWorkout() {
		setUpTimer()

		self.running = true

		do {
			session = try HKWorkoutSession(healthStore: healthStore, configuration: workoutConfiguration())
			builder = session.associatedWorkoutBuilder()
		} catch {
			return
		}

		session.delegate = self
		builder.delegate = self

		builder.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
													 workoutConfiguration: workoutConfiguration())

		session.startActivity(with: Date())
		builder.beginCollection(withStart: Date()) { (success, error) in
			print(error.debugDescription)
		}
	}

	func endWorkout() {
		session.end()
		cancellable?.cancel()
	}

	func resetWorkout() {
		DispatchQueue.main.async {
			self.elapsedSeconds = 0
			self.activeCalories = 0
			self.heartrate = 0
			self.distance = 0
		}
	}

	// MARK: - Update the UI
	func updateForStatistics(_ statistics: HKStatistics?) {
		guard let statistics = statistics else { return }

		DispatchQueue.main.async {
			switch statistics.quantityType {
				case HKQuantityType.quantityType(forIdentifier: .heartRate):
					/// - Tag: SetLabel
					let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
					let value = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit)
					let roundedValue = Double( round( 1 * value! ) / 1 )
					self.heartrate = roundedValue
				case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
					let energyUnit = HKUnit.kilocalorie()
					let value = statistics.sumQuantity()?.doubleValue(for: energyUnit)
					self.activeCalories = Double( round( 1 * value! ) / 1 )
					return
				case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
					let meterUnit = HKUnit.meter()
					let value = statistics.sumQuantity()?.doubleValue(for: meterUnit)
					let roundedValue = Double( round( 1 * value! ) / 1 )
					self.distance = roundedValue
					return
				default:
					return
			}
		}
	}

	func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
						from fromState: HKWorkoutSessionState, date: Date) {
		if toState == .ended {
			builder.endCollection(withEnd: Date()) { (success, error) in
				self.builder.finishWorkout { (workout, error) in
					self.resetWorkout()
				}
			}
		}
	}

	func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
		for type in collectedTypes {
			guard let quantityType = type as? HKQuantityType else {
				return
			}

			let statistics = workoutBuilder.statistics(for: quantityType)

			updateForStatistics(statistics)
		}

		heartrateLabel.setText("\(heartrate) bpm")
		activeCaloriesLabel.setText("\(activeCalories) cal")
		distanceLabel.setText("\(distance) m")
		timerLabel.setText(secondsToHoursMinutesSeconds(seconds: elapsedSeconds))
	}

	func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) { }

	func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) { }
}
