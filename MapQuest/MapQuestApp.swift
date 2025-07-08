import SwiftUI

@main
struct MapQuestApp: App {
  @StateObject private var locationListener = LocationListener()

  init() {
    Game.shared.adventurer = Adventurer(name: "Hero", hitPoints: 10, strength: 10, gold: 40)
  }

  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}
