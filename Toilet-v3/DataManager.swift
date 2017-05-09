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
                DispatchQueue.main.sync(execute: completionClosure)
            } catch {
                fatalError("Error migrating store: \(error)")
            }
        }
    }

    func initToilets() {
        let fetch = NSFetchRequest<ToiletObj>(entityName: "ToiletObj")
        let fetchedToilets = try? managedObjectContext.fetch(fetch)

        guard (fetchedToilets?.count)! < 2 else { return }

        let _ = createToilet(with: 1)
        let _ = createToilet(with: 2)
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

        let toiletObj1 = fetchToilet(number: 1)
        let toiletObj2 = fetchToilet(number: 2)

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
                    let something = hours[date]!.flatMap{$0.hours?.array}.flatMap{$0} as! [HourObj]
                    for hour in something {
                        let dayIndex = Int(date)!
                        toilet.occupiedHours[dayIndex] += hour.occupied
                        toilet.vacantHours[dayIndex] += hour.vacant
                        toilet.offlineHours[dayIndex] += hour.offline
                    }
                }
            }

            populateValues(toiletObj1, toilet1)
            populateValues(toiletObj2, toilet2)

            print("")

        case .hourly:
            let populateValues: (ToiletObj, Toilet) -> () = { (toiletObj, toilet) in
                let dates = toiletObj.dates?.array as! [DateObj]
                let hours = dates.flatMap{$0.hours?.array}.flatMap{$0} as! [HourObj]

                for hour in hours {
                    let hourIndex = Int(hour.hour!)!
                    toilet.occupiedHours[hourIndex] += hour.occupied
                    toilet.vacantHours[hourIndex] += hour.vacant
                    toilet.offlineHours[hourIndex] += hour.offline
                }
            }

            populateValues(toiletObj1, toilet1)
            populateValues(toiletObj2, toilet2)

        case .monthly: break

        }

        var model = BarGraphModel(toilets: [toilet1, toilet2])
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
