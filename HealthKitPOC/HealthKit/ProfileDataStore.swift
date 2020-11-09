//
//  ProfileDataStore.swift
//  HealthKitPOC
//
//  Created by Matheus Oliveira on 04/11/20.
//

import HealthKit

class ProfileDataStore {
    
    class func getAgeSexAndBloodType() throws -> (age: Int,
                                                  biologicalSex: HKBiologicalSex,
                                                  bloodType: HKBloodType) {
        
        let healthKitStore = HKHealthStore()
        
        do {
        
            let birthdayComponents = try healthKitStore.dateOfBirthComponents()
            let biologicalSex = try healthKitStore.biologicalSex()
            let bloodType = try healthKitStore.bloodType()
            
            let today = Date()
            let calendar = Calendar.current
            let todayDateComponents = calendar.dateComponents([.year],
                                                                from: today)
            let thisYear = todayDateComponents.year!
            let age = thisYear - birthdayComponents.year!
             
            let unwrappedBiologicalSex = biologicalSex.biologicalSex
            let unwrappedBloodType = bloodType.bloodType
              
            return (age, unwrappedBiologicalSex, unwrappedBloodType)
        }
    }
    
    
    class func getMostRecentSample(for sampleType: HKSampleType,
                                   completion: @escaping (HKQuantitySample?,
                                                          Error?) -> Swift.Void) {
      
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: Date.distantPast,
                                                              end: Date(),
                                                              options: .strictEndDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
                                              ascending: false)
        
        let limit = 1
        
        let sampleQuery = HKSampleQuery(sampleType: sampleType,
                                        predicate: mostRecentPredicate,
                                        limit: limit,
                                        sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            

            DispatchQueue.main.async {
                    
                guard let samples = samples,
                      let mostRecentSample = samples.first as? HKQuantitySample else {
                        completion(nil, error)
                        return
                }
                
                completion(mostRecentSample, nil)
            }
        }
         
        HKHealthStore().execute(sampleQuery)
    }
    
    
    class func getMostRecentCategorySample(for sampleType: HKSampleType,
                                   completion: @escaping ([HKSample]?,
                                                          Error?) -> Swift.Void) {
        
        //   Get the start of the day
        let date = Date()
        let cal = Calendar(identifier: Calendar.Identifier.gregorian)
        let newDate = cal.startOfDay(for: date)
      
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: newDate,
                                                              end: date,
                                                              options: .strictStartDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
                                              ascending: false)
        
        let limit: Int = 30
                
        let sampleQuery = HKSampleQuery(sampleType: sampleType,
                                        predicate: mostRecentPredicate,
                                        limit: limit,
                                        sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            

            DispatchQueue.main.async {
                    
                guard let samples = samples else {
                        completion(nil, error)
                        return
                }
                
                completion(samples, nil)
            }
        }
         
        HKHealthStore().execute(sampleQuery)
    }
    
    class func saveBodyMassIndexSample(bodyMassIndex: Double, date: Date) {
      
        guard let bodyMassIndexType = HKQuantityType.quantityType(forIdentifier: .bodyMassIndex) else {
            fatalError("Body Mass Index Type not available")
        }
        
        let bodyMassQuantity = HKQuantity(unit: HKUnit.count(),
                                          doubleValue: bodyMassIndex)
        
        let bodyMassIndexSample = HKQuantitySample(type: bodyMassIndexType,
                                                   quantity: bodyMassQuantity,
                                                   start: date,
                                                   end: date)
        
        HKHealthStore().save(bodyMassIndexSample) { (success, error) in
            if let error = error {
                print("Error Saving BMI Sample: \(error.localizedDescription)")
            } else {
                print("Successfully saved BMI Sample")
            }
        }
    }
}
