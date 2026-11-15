import SwiftUI

@main
struct TabScreenApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup("TabScreen") {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 900, minHeight: 640)
        }
        MenuBarExtra {
            MenuContent().environmentObject(model)
        } label: {
            Image(systemName: model.sunshineRunning ? "display.2" : "display")
        }
    }
}
