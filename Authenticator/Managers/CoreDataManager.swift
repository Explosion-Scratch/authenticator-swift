import Foundation
import CoreData

class CoreDataManager {
    let persistentContainer: NSPersistentContainer
    
    static let shared: CoreDataManager = CoreDataManager()
    private init() {
        persistentContainer = NSPersistentContainer(name: "Authenticator")
        persistentContainer.loadPersistentStores {description, error in
            if let error = error {
                fatalError("Unable to create Core Data \(error)")
            }
        }
    }
}

extension NSPersistentContainer {
    func destroyPersistentStores() throws {
        for store in persistentStoreCoordinator.persistentStores {
            let type = NSPersistentStore.StoreType(rawValue: store.type)
            try persistentStoreCoordinator.destroyPersistentStore(at: store.url!, type: type)
        }
        loadPersistentStores()
    }
    
    func loadPersistentStores() {
        loadPersistentStores { _, error in
            if let error { fatalError(error.localizedDescription) }
        }
    }
}
