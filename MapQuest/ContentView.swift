import SwiftUI
import MapKit

struct ContentView: View {
  @State private var region = MKCoordinateRegion(
    center: CLLocationCoordinate2D(latitude: 40.774669555422349, longitude: -73.964170794293238),
    span: MKCoordinateSpan(latitudeDelta: 0.16405544070813249, longitudeDelta: 0.1232528799585566))

  var heartsString: String {
    guard let hp = Game.shared.adventurer?.hitPoints else { return "\u{2620}\u{FE0F}" }
    return String(repeating: "\u{2764}\u{FE0F}", count: hp / 2)
  }

  var goldString: String {
    guard let gold = Game.shared.adventurer?.gold else { return "" }
    return "\u{1F4B0}\(gold)"
  }

  var body: some View {
    ZStack(alignment: .topLeading) {
      Map(coordinateRegion: $region, showsUserLocation: true)
        .ignoresSafeArea()
      Text(heartsString + "\n" + goldString)
        .padding(8)
        .background(Color.white.opacity(0.8))
        .cornerRadius(8)
        .padding()
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
