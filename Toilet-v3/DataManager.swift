//
//  DataManager.swift
//  iQ2P
//
//  Created by Pavel Boryseiko on 8/5/17.
//  Copyright © 2017 GRIDSTONE. All rights reserved.
//

import Cocoa

class DataManager: NSObject {

    private var managedObjectContext: NSManagedObjectContext

    lazy var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd"
        return dateFormatter
    }()

    init(completionClosure: @escaping () -> ()) {
        guard let modelURL = Bundle.main.url(forResource: "Model", withExtension:"momd") else {
            fatalError("Error loading model from bundle")
        }
        guard let mom = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Error initializing mom from: \(modelURL)")
        }

        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)

        managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = psc

        let queue = DispatchQueue.global(qos: DispatchQoS.QoSClass.background)
        queue.async {
            guard let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last else {
                fatalError("Unable to resolve document directory")
            }

            let urlPath = docURL.appendingPathComponent("iQ2P/")
            let storeURL = urlPath.appendingPathComponent("yourPoopData.sqlite")

            try? FileManager.default.createDirectory(at: urlPath, withIntermediateDirectories: true, attributes: nil)

            do {
                try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
                DispatchQueue.global(qos: .background).sync(execute: completionClosure)
            } catch {
                fatalError("Error migrating store: \(error)")
            }
        }
    }

    func initToilets(count: Int) {
        let fetch = NSFetchRequest<ToiletObj>(entityName: "ToiletObj")
        let fetchedToilets = try? managedObjectContext.fetch(fetch)

        guard (fetchedToilets?.count)! < 4 else { return }

        for i in 0..<count {
            let _ = createToilet(with: i+1)
        }
    }

    func updateToilet(number: Int, date: Date, hour: Int, value: Double, status: ToiletStatus) {
        let toilet = fetchToilet(number: number)
        let date = fetchDate(date: date, toilet: toilet)
        let hour = fetchHour(hour: hour, date: date, toilet: toilet)

        switch status {
        case .occupied:
            hour.occupied += value
        case .vacant:
            hour.vacant += value
        case .offline:
            hour.offline += value
        }
        save()
    }

    func barData(for segment: BarSegement) -> BarGraphModel {
        let toilet1 = Toilet(number: 1)
        let toilet2 = Toilet(number: 2)
        let toilet3 = Toilet(number: 3)
        let toilet4 = Toilet(number: 4)

        let toiletObj1 = fetchToilet(number: 1)
        let toiletObj2 = fetchToilet(number: 2)
        let toiletObj3 = fetchToilet(number: 3)
        let toiletObj4 = fetchToilet(number: 4)

        switch segment {
        case .daily:
            let populateValues: (ToiletObj, Toilet) -> () = { (toiletObj, toilet) in
                var hours = [String: [DateObj]]()
                let dates = toiletObj.dates?.array as! [DateObj]

                for date in dates {
                    if hours[date.day!] != nil {
                        hours[date.day!]?.append(date)
                    } else {
                        hours[date.day!] = [date]
                    }
                }

                for date in Array(hours.keys) {
                    let hourObjs = hours[date]!.flatMap{$0.hours?.array}.flatMap{$0} as! [HourObj]
                    let filteredHours = hourObjs.filter{Int($0.hour!)! >= 7 && Int($0.hour!)! <= 19}
                    for hour in filteredHours {
                        let dayIndex = Int(date)!
                        toilet.occupiedHours[dayIndex] += hour.occupied
                        toilet.vacantHours[dayIndex] += hour.vacant
                        toilet.offlineHours[dayIndex] += hour.offline
                    }
                }
            }

            populateValues(toiletObj1, toilet1)
            populateValues(toiletObj2, toilet2)
            populateValues(toiletObj3, toilet3)
            populateValues(toiletObj4, toilet4)

        case .hourly:
            let populateValues: (ToiletObj, Toilet) -> () = { (toiletObj, toilet) in
                let dates = toiletObj.dates?.array as! [DateObj]
                let filteredDates = dates.filter{Int($0.day!)! >= 2 && Int($0.day!)! <= 6}

                let hours = filteredDates.flatMap{$0.hours?.array}.flatMap{$0} as! [HourObj]

                for hour in hours {
                    let hourIndex = Int(hour.hour!)!
                    toilet.occupiedHours[hourIndex] += hour.occupied
                    toilet.vacantHours[hourIndex] += hour.vacant
                    toilet.offlineHours[hourIndex] += hour.offline
                }
            }

            populateValues(toiletObj1, toilet1)
            populateValues(toiletObj2, toilet2)
            populateValues(toiletObj3, toilet3)
            populateValues(toiletObj4, toilet4)

        case .monthly:
        let populateValues: (ToiletObj, Toilet) -> () = { (toiletObj, toilet) in
            var hours = [String: [DateObj]]()
            let dates = toiletObj.dates?.array as! [DateObj]
            let filteredDates = dates.filter{Int($0.day!)! >= 2 && Int($0.day!)! <= 6}

            for date in filteredDates {
                if hours[date.month!] != nil {
                    hours[date.month!]?.append(date)
                } else {
                    hours[date.month!] = [date]
                }
            }

            for date in Array(hours.keys) {
                let hourObjs = hours[date]!.flatMap{$0.hours?.array}.flatMap{$0} as! [HourObj]
                let filteredHours = hourObjs.filter{Int($0.hour!)! >= 7 && Int($0.hour!)! <= 19}
                for hour in filteredHours {
                    let dayIndex = Int(date)!
                    toilet.occupiedHours[dayIndex] += hour.occupied
                    toilet.vacantHours[dayIndex] += hour.vacant
                    toilet.offlineHours[dayIndex] += hour.offline
                }
            }
        }

        populateValues(toiletObj1, toilet1)
        populateValues(toiletObj2, toilet2)
        populateValues(toiletObj3, toilet3)
        populateValues(toiletObj4, toilet4)

        }

        var model = BarGraphModel(toilets: [toilet1, toilet2, toilet3, toilet4])
        model.segment = segment

        return model
    }

    private func createToilet(with id: Int) -> ToiletObj {
        let toilet = NSEntityDescription.insertNewObject(forEntityName: "ToiletObj", into: managedObjectContext) as! ToiletObj
        toilet.number = String(id)

        save()
        return toilet
    }

    private func createDate(date: Date, toilet: ToiletObj) -> DateObj {
        let day = Calendar.current.component(.weekday, from: date)
        let month = Calendar.current.component(.month, from: date)

        let dateString = dateFormatter.string(from: date)
        let date = NSEntityDescription.insertNewObject(forEntityName: "DateObj", into: managedObjectContext) as! DateObj
        date.date = dateString
        date.day = "\(day-1)"
        date.month = "\(month-1)"

        toilet.addToDates(date)

        save()
        return date
    }

    private func createHour(hour: Int, date: DateObj) -> HourObj {
        let hourObj = NSEntityDescription.insertNewObject(forEntityName: "HourObj", into: managedObjectContext) as! HourObj
        hourObj.hour = "\(hour)"
        date.addToHours(hourObj)

        save()
        return hourObj
    }

    private func fetchToilet(number: Int) -> ToiletObj  {
        let toiletFetch = NSFetchRequest<ToiletObj>(entityName: "ToiletObj")
        toiletFetch.predicate = NSPredicate(format: "number == %@", String(number))
        let fetchedToilet = try! managedObjectContext.fetch(toiletFetch).first

        return fetchedToilet!
    }

    private func fetchDate(date: Date, toilet: ToiletObj) -> DateObj {
        let dateString = dateFormatter.string(from: date)
        let predicate = NSPredicate(format: "date == %@", dateString)

        let dates = toilet.dates?.filtered(using: predicate)

        if dates?.count == 0 {
            return createDate(date: date, toilet: toilet)
        } else {
            return dates?.firstObject as! DateObj
        }
    }

    private func fetchHour(hour: Int, date: DateObj, toilet: ToiletObj) -> HourObj {
        let hourPredicate = NSPredicate(format: "hour == %@", "\(hour)")
        let hours = date.hours?.filtered(using: hourPredicate)
        
        if hours?.count == 0 {
            return createHour(hour: hour, date: date)
        } else {
            return hours?.firstObject as! HourObj
        }
    }
    
    private func save() {
        do { try managedObjectContext.save() } catch {
            fatalError("Failed to save: \(error)")
        }
    }
    
}
