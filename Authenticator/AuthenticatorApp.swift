//Created by Explosion-Scratch

import SwiftUI

@main
struct AuthenticatorApp: App {
    let persistentContainer = CoreDataManager.shared.persistentContainer
    
    var body: some Scene {
        WindowGroup {
            ContentView().environment(\.managedObjectContext, persistentContainer.viewContext)
        }.commands {
            SidebarCommands()
        }
    }
}
