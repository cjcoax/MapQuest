import SwiftUI

struct ShopView: View {
  var shop: Store

  var body: some View {
    List(shop.inventory, id: \.name) { item in
      HStack {
        Game.shared.image(for: item)?.resizable().frame(width: 32, height: 32)
        Text(item.name)
        Spacer()
        Text("\u{1F4B0}\(item.cost)")
      }
    }.navigationTitle(shop.name)
  }
}

struct ShopView_Previews: PreviewProvider {
  static var previews: some View {
    if let shop = Game.shared.pointsOfInterest.compactMap({ $0 as? Store }).first {
      ShopView(shop: shop)
    } else {
      ShopView(shop: Store(name: "Shop", items: []))
    }
  }
}
