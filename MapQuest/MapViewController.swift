/// Copyright (c) 2020 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// This project and source code may use libraries or frameworks that are
/// released under various Open-Source licenses. Use of those libraries and
/// frameworks are governed by their own individual licenses.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import MapKit

class MapViewController: UIViewController {
  // MARK: - IBOutlets
  @IBOutlet weak var mapView: MKMapView!
  @IBOutlet weak var heartsLabel: UILabel!

  // MARK: - Properties
  // swiftlint:disable implicitly_unwrapped_optional
  var tileRenderer: MKTileOverlayRenderer!
  var shimmerRenderer: ShimmerRenderer!
  // swiftlint:enable implicitly_unwrapped_optional

  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()

    setupTileRenderer()
    setupLakeOverlay()

    let initialRegion = MKCoordinateRegion(
      center: CLLocationCoordinate2D(latitude: 40.774669555422349, longitude: -73.964170794293238),
      span: MKCoordinateSpan(latitudeDelta: 0.16405544070813249, longitudeDelta: 0.1232528799585566))

    mapView.cameraZoomRange = MKMapView.CameraZoomRange(
      minCenterCoordinateDistance: 7000,
      maxCenterCoordinateDistance: 60000)
    mapView.cameraBoundary = MKMapView.CameraBoundary(coordinateRegion: initialRegion)

    mapView.region = initialRegion
    mapView.showsUserLocation = true
    mapView.showsCompass = true
    mapView.setUserTrackingMode(.followWithHeading, animated: true)

    Game.shared.delegate = self

    NotificationCenter.default
      .addObserver(self, selector: #selector(gameUpdated(notification:)), name: gameStateNotification, object: nil)
    mapView.delegate = self

    mapView.addAnnotations(Game.shared.warps)
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    renderGame()
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "shop",
      let shopController = segue.destination as? ShopViewController,
      let store = sender as? Store {
      shopController.shop = store
    }
  }

  private func setupTileRenderer() {
    let overlay = AdventureMapOverlay()

    overlay.canReplaceMapContent = true
    mapView.addOverlay(overlay, level: .aboveLabels)
    tileRenderer = MKTileOverlayRenderer(tileOverlay: overlay)

    overlay.minimumZ = 13
    overlay.maximumZ = 16
  }

  private func setupLakeOverlay() {
    let lake = MKPolygon(coordinates: &Game.shared.reservoir, count: Game.shared.reservoir.count)
    mapView.addOverlay(lake)

    shimmerRenderer = ShimmerRenderer(overlay: lake)
    shimmerRenderer.fillColor = #colorLiteral(red: 0.2431372549, green: 0.5803921569, blue: 0.9764705882, alpha: 1)
    // swiftlint:disable:previous discouraged_object_literal
    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
      self?.shimmerRenderer.updateLocations()
      self?.shimmerRenderer.setNeedsDisplay()
    }
  }

  @objc func gameUpdated(notification: Notification) {
    renderGame()
  }
}

// MARK: - MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
  // Add delegates here
  func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    if overlay is AdventureMapOverlay {
      return tileRenderer
    } else {
      return shimmerRenderer
    }
  }

  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    switch annotation {
    case let user as MKUserLocation:
      if let existingView = mapView.dequeueReusableAnnotationView(withIdentifier: "user") {
        return existingView
      } else {
        let view = MKAnnotationView(annotation: user, reuseIdentifier: "user")
        // swiftlint:disable:next discouraged_object_literal
        view.image = #imageLiteral(resourceName: "user")
        return view
      }
    case let warp as WarpZone:
      if let existingView = mapView.dequeueReusableAnnotationView(
        withIdentifier: WarpAnnotationView.identifier) {
        existingView.annotation = annotation
        return existingView
      } else {
        return WarpAnnotationView(annotation: warp, reuseIdentifier: WarpAnnotationView.identifier)
      }
    default:
      return nil
    }
  }
}

// MARK: - Game UI
extension MapViewController {
  private func heartsString() -> String {
    // swiftlint:disable:next identifier_name
    guard let hp = Game.shared.adventurer?.hitPoints else { return "☠️" }
    return String(repeating: "❤️", count: hp / 2)
  }

  private func goldString() -> String {
    guard let gold = Game.shared.adventurer?.gold else { return "" }
    return "💰\(gold)"
  }

  private func renderGame() {
    heartsLabel.text = heartsString() + "\n" + goldString()
  }
}

// MARK: - GameDelegate
extension MapViewController: GameDelegate {
  func encounteredMonster(monster: Monster) {
    showFight(monster: monster)
  }

  func showFight(monster: Monster, subtitle: String = "Fight?") {
    let alertController = UIAlertController()

    let runAction = UIAlertAction(title: "Run", style: .cancel) { _ in
      self.showFight(monster: monster, subtitle: "I think you should really fight this.")
    }

    let fightAction = UIAlertAction(title: "Fight", style: .default) { _ in
      guard let result = Game.shared.fight(monster: monster) else { return }

      switch result {
      case .heroLost:
        print("loss!")
      case .heroWon:
        print("win!")
      case .tie:
        self.showFight(monster: monster, subtitle: "A good row, but you are both still in the fight!")
      }
    }

    alertController.title = "A wild \(monster.name) appeared!"
    alertController.addActions(actions: [runAction, fightAction])
    present(alertController, animated: true)
  }

  func encounteredNPC(npc: NPC) {
    let alertController = UIAlertController()

    let noThanksAction = UIAlertAction(title: "No Thanks", style: .cancel) { _ in
      print("done with encounter")
    }

    let onMyWayAction = UIAlertAction(title: "On My Way", style: .default) { _ in
      print("did not buy anything")
    }

    alertController.title = npc.name
    alertController.addActions(actions: [noThanksAction, onMyWayAction])
    present(alertController, animated: true)
  }

  func enteredStore(store: Store) {
    let alertController = UIAlertController()

    let backOutAction = UIAlertAction(title: "Back Out", style: .cancel) { _ in
      print("did not buy anything")
    }

    let takeMoneyAction = UIAlertAction(title: "Take My 💰", style: .default) { _ in
      self.performSegue(withIdentifier: "shop", sender: store)
    }

    alertController.title = store.name
    alertController.addActions(actions: [backOutAction, takeMoneyAction])
    present(alertController, animated: true)
  }
}
