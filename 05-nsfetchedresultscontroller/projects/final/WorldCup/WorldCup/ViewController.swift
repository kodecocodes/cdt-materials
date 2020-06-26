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
  fileprivate let teamCellIdentifier = "teamCellReuseIdentifier"
  lazy var  coreDataStack = CoreDataStack(modelName: "WorldCup")
  var dataSource: UITableViewDiffableDataSource<String, Team>?

  lazy var fetchedResultsController: NSFetchedResultsController<Team> = {
    let fetchRequest: NSFetchRequest<Team> = Team.fetchRequest()
    let sort = NSSortDescriptor(key: #keyPath(Team.teamName), ascending: true)
    let zoneSort = NSSortDescriptor(key: #keyPath(Team.qualifyingZone), ascending: true)
    let scoreSort = NSSortDescriptor(key: #keyPath(Team.wins), ascending: false)
    let nameSort = NSSortDescriptor(key: #keyPath(Team.teamName), ascending: true)

    fetchRequest.sortDescriptors = [zoneSort, scoreSort, nameSort]

    let fetchedResultsController = NSFetchedResultsController(
      fetchRequest: fetchRequest,
      managedObjectContext: coreDataStack.managedContext,
      sectionNameKeyPath: #keyPath(Team.qualifyingZone),
      cacheName: "worldCup")

    fetchedResultsController.delegate = self
    return fetchedResultsController
  }()

  // MARK: - IBOutlets
  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var addButton: UIBarButtonItem!

  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()

    importJSONSeedDataIfNeeded()
    dataSource = setupDataSource()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    UIView.performWithoutAnimation {
      do {
        try fetchedResultsController.performFetch()
      } catch let error as NSError {
        print("Fetching error: \(error), \(error.userInfo)")
      }
    }
  }

  override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
    if motion == .motionShake {
      addButton.isEnabled = true
    }
  }
}

// MARK: - IBActions
extension ViewController {

  @IBAction func addTeam(_ sender: Any) {

    let alertController = UIAlertController(title: "Secret Team", message: "Add a new team", preferredStyle: .alert)

    alertController.addTextField { textField in
      textField.placeholder = "Team Name"
    }

    alertController.addTextField { textField in
      textField.placeholder = "Qualifying Zone"
    }

    let saveAction = UIAlertAction(title: "Save", style: .default) { [unowned self] action in

      guard let nameTextField = alertController.textFields?.first,
        let zoneTextField = alertController.textFields?.last else {
          return
      }

      let team = Team(context: self.coreDataStack.managedContext)
      team.teamName = nameTextField.text
      team.qualifyingZone = zoneTextField.text
      team.imageName = "wenderland-flag"
      self.coreDataStack.saveContext()
    }

    alertController.addAction(saveAction)
    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))

    present(alertController, animated: true)
  }
}

// MARK: - Internal
extension ViewController {

  func setupDataSource() -> UITableViewDiffableDataSource<String, Team> {
    return UITableViewDiffableDataSource(tableView: tableView) { [unowned self](tableView, indexPath, team) -> UITableViewCell? in
      let cell = tableView.dequeueReusableCell(withIdentifier: self.teamCellIdentifier, for: indexPath)
      self.configure(cell: cell, for: team)
      return cell
    }
  }

  func configure(cell: UITableViewCell, for team: Team) {

    guard let cell = cell as? TeamCell else {
      return
    }

    cell.teamLabel.text = team.teamName
    cell.scoreLabel.text = "Wins: \(team.wins)"

    if let imageName = team.imageName {
      cell.flagImageView.image = UIImage(named: imageName)
    } else {
      cell.flagImageView.image = nil
    }
  }
}

// MARK: - UITableViewDelegate
extension ViewController: UITableViewDelegate {

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    let team = fetchedResultsController.object(at: indexPath)
    team.wins = team.wins + 1

    let cell = tableView.cellForRow(at: indexPath) as! TeamCell
    configure(cell: cell, for: team)

    coreDataStack.saveContext()
  }

  func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

    let sectionInfo = fetchedResultsController.sections?[section]

    let titleLabel = UILabel()
    titleLabel.backgroundColor = .white
    titleLabel.text = sectionInfo?.name

    return titleLabel
  }

  func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return 20
  }
}

// MARK: - Helper methods
extension ViewController {

  func importJSONSeedDataIfNeeded() {

    let fetchRequest: NSFetchRequest<Team> = Team.fetchRequest()
    let count = try? coreDataStack.managedContext.count(for: fetchRequest)

    guard let teamCount = count,
      teamCount == 0 else {
        return
    }

    importJSONSeedData()
  }

  func importJSONSeedData() {

    let jsonURL = Bundle.main.url(forResource: "seed", withExtension: "json")!
    let jsonData = try! Data(contentsOf: jsonURL)

    do {
      let jsonArray = try JSONSerialization.jsonObject(with: jsonData, options: [.allowFragments]) as! [[String: Any]]

      for jsonDictionary in jsonArray {
        let teamName = jsonDictionary["teamName"] as! String
        let zone = jsonDictionary["qualifyingZone"] as! String
        let imageName = jsonDictionary["imageName"] as! String
        let wins = jsonDictionary["wins"] as! NSNumber

        let team = Team(context: coreDataStack.managedContext)
        team.teamName = teamName
        team.imageName = imageName
        team.qualifyingZone = zone
        team.wins = wins.int32Value
      }

      coreDataStack.saveContext()
      print("Imported \(jsonArray.count) teams")

    } catch let error as NSError {
      print("Error importing teams: \(error)")
    }
  }
}

// MARK: - NSFetchedResultsControllerDelegate
extension ViewController: NSFetchedResultsControllerDelegate {

  func controller(
    _ controller: NSFetchedResultsController<NSFetchRequestResult>,
    didChangeContentWith
    snapshot: NSDiffableDataSourceSnapshotReference) {

    var diff = NSDiffableDataSourceSnapshot<String, Team>()
    snapshot.sectionIdentifiers.forEach { section in

      //1
      diff.appendSections([section as! String])

      //2
      let items = snapshot.itemIdentifiersInSection(withIdentifier: section)
        .map { (objectId: Any) -> Team in
          let oid =  objectId as! NSManagedObjectID
          return controller.managedObjectContext.object(with: oid) as! Team
      }

      //3
      diff.appendItems(items, toSection: section as? String)
    }

    dataSource?.apply(diff)
  }
}
