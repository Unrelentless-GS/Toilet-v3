//
//  DataManager.swift
//  iQ2P
//
//  Created by Pavel Boryseiko on 8/5/17.
//  Copyright © 2017 GRIDSTONE. All rights reserved.
//

import Cocoa

class DataManager: NSObject {

    var managedObjectContext: NSManagedObjectContext

    init(completionClosure: @escaping () -> ()) {
        //This resource is the same name as your xcdatamodeld contained in your project
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
            let storeURL = urlPath.appendingPathComponent("Model.sqlite")

            try? FileManager.default.createDirectory(at: urlPath, withIntermediateDirectories: true, attributes: nil)

            do {
                try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil)
                //The callback block is expected to complete the User Interface and therefore should be presented back on the main queue so that the user interface does not need to be concerned with which queue this call is coming from.
                DispatchQueue.main.sync(execute: completionClosure)
            } catch {
                fatalError("Error migrating store: \(error)")
            }
        }
    }

    func initToilets() {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "ToiletObj")
        let fetchedToilets = try? managedObjectContext.fetch(fetch) as! [ToiletObj]

        guard (fetchedToilets?.count)! < 2 else { return }

        createToilet(with: 1)
        createToilet(with: 2)
    }

    func initHour() {
        
    }

    func createToilet(with id: Int) {
        let toilet = NSEntityDescription.insertNewObject(forEntityName: "ToiletObj", into: managedObjectContext) as! ToiletObj
        toilet.number = String(id)
        save()
    }

    func createDate(with date: Date) {

    }
    
    func save() {
        try? managedObjectContext.save()
    }
    
}
