/// Copyright (c) 2019 Razeware LLC
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
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit
import CoreData

class ViewController: UIViewController {

  // MARK: - Properties
  private let filterViewControllerSegueIdentifier = "toFilterViewController"
  private let venueCellIdentifier = "VenueCell"

  lazy var coreDataStack = CoreDataStack(modelName: "BubbleTeaFinder")

  // MARK: - IBOutlets
  @IBOutlet weak var tableView: UITableView!

  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()

    importJSONSeedDataIfNeeded()
  }

  // MARK: - Navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == filterViewControllerSegueIdentifier {

    }
  }
}

// MARK: - IBActions
extension ViewController {

  @IBAction func unwindToVenueListViewController(_ segue: UIStoryboardSegue) {
  }
}

// MARK: - UITableViewDataSource
extension ViewController: UITableViewDataSource {

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 10
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: venueCellIdentifier, for: indexPath)
    cell.textLabel?.text = "Bubble Tea Venue"
    cell.detailTextLabel?.text = "Price Info"
    return cell
  }
}

// MARK - Data loading
extension ViewController {
  
  func importJSONSeedDataIfNeeded() {
    let fetchRequest = NSFetchRequest<Venue>(entityName: "Venue")
    let count = try! coreDataStack.managedContext.count(for: fetchRequest)

    guard count == 0 else { return }

    do {
      let results = try coreDataStack.managedContext.fetch(fetchRequest)
      results.forEach { coreDataStack.managedContext.delete($0) }

      coreDataStack.saveContext()
      importJSONSeedData()
    } catch let error as NSError {
      print("Error fetching: \(error), \(error.userInfo)")
    }
  }

  func importJSONSeedData() {
    let jsonURL = Bundle.main.url(forResource: "seed", withExtension: "json")!
    let jsonData = try! Data(contentsOf: jsonURL)

    let jsonDict = try! JSONSerialization.jsonObject(with: jsonData, options: [.allowFragments]) as! [String: Any]
    let responseDict = jsonDict["response"] as! [String: Any]
    let jsonArray = responseDict["venues"] as! [[String: Any]]

    for jsonDictionary in jsonArray {
      let venueName = jsonDictionary["name"] as? String
      let contactDict = jsonDictionary["contact"] as! [String: String]

      let venuePhone = contactDict["phone"]

      let specialsDict = jsonDictionary["specials"] as! [String: Any]
      let specialCount = specialsDict["count"] as? NSNumber

      let locationDict = jsonDictionary["location"] as! [String: Any]
      let priceDict = jsonDictionary["price"] as! [String: Any]
      let statsDict =  jsonDictionary["stats"] as! [String: Any]

      let location = Location(context: coreDataStack.managedContext)
      location.address = locationDict["address"] as? String
      location.city = locationDict["city"] as? String
      location.state = locationDict["state"] as? String
      location.zipcode = locationDict["postalCode"] as? String
      let distance = locationDict["distance"] as? NSNumber
      location.distance = distance!.floatValue

      let category = Category(context: coreDataStack.managedContext)

      let priceInfo = PriceInfo(context: coreDataStack.managedContext)
      priceInfo.priceCategory = priceDict["currency"] as? String

      let stats = Stats(context: coreDataStack.managedContext)
      let checkins = statsDict["checkinsCount"] as? NSNumber
      stats.checkinsCount = checkins!.int32Value
      let tipCount = statsDict["tipCount"] as? NSNumber
      stats.tipCount = tipCount!.int32Value

      let venue = Venue(context: coreDataStack.managedContext)
      venue.name = venueName
      venue.phone = venuePhone
      venue.specialCount = specialCount!.int32Value
      venue.location = location
      venue.category = category
      venue.priceInfo = priceInfo
      venue.stats = stats
    }

    coreDataStack.saveContext()
  }
}
