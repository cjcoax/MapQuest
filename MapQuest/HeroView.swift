import SwiftUI

struct HeroView: View {
  var inventory: [Item] { Game.shared.adventurer?.inventory ?? [] }

  var body: some View {
    List(inventory, id: \.name) { item in
      HStack {
        Game.shared.image(for: item)?.resizable().frame(width: 32, height: 32)
        Text(item.name)
      }
    }.navigationTitle("Hero")
  }
}

struct HeroView_Previews: PreviewProvider {
  static var previews: some View {
    HeroView()
  }
}
