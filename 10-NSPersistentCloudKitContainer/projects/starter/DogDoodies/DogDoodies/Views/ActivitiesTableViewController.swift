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
import CoreData

class ActivitiesTableViewController: UITableViewController {
  var pet: Pet?
  var dataSource: UITableViewDiffableDataSource<String, NSManagedObjectID>?
  //swiftlint:disable:next implicitly_unwrapped_optional
  var coreDataStack: CoreDataStack!

  lazy var fetchedResultsController: NSFetchedResultsController<Activity> = {
    let petService = PetService(context: coreDataStack.managedContext)
    let fetchRequest = petService.activitiesFetchRequest(for: pet)

    let fetchedResultsController = NSFetchedResultsController(
      fetchRequest: fetchRequest,
      managedObjectContext: coreDataStack.managedContext,
      sectionNameKeyPath: nil,
      cacheName: nil)

    fetchedResultsController.delegate = self
    return fetchedResultsController
  }()

  override func viewDidLoad() {
    super.viewDidLoad()

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
}

extension ActivitiesTableViewController {
  class DataSource: UITableViewDiffableDataSource<String, NSManagedObjectID> {
    var coreDataStack: CoreDataStack?

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
      true
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
      if
        editingStyle == .delete,
        let activityID = itemIdentifier(for: indexPath),
        let context = coreDataStack?.managedContext,
        let activity = try? context.existingObject(with: activityID) {
        context.delete(activity)
        coreDataStack?.saveContext()
      }
    }
  }

  func setupDataSource() -> DataSource {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale.current
    dateFormatter.dateStyle = .medium
    dateFormatter.timeStyle = .medium

    let dataSource = DataSource(tableView: tableView) { [unowned self] tableView, indexPath, _ in
      let cell = tableView.dequeueReusableCell(withIdentifier: "Activity", for: indexPath)
      let activity = self.fetchedResultsController.object(at: indexPath)
      switch activity.activityType {
      case "poop":
        cell.textLabel?.text = "💩"
      case "pee":
        cell.textLabel?.text = "💦"
      case "walk":
        cell.textLabel?.text = "🚶‍♂️"
      default:
        cell.textLabel?.text = ""
      }

      if let date = activity.date {
        let dateText = dateFormatter.string(from: date)
        cell.detailTextLabel?.text = dateText
      }

      return cell
    }
    dataSource.coreDataStack = coreDataStack

    return dataSource
  }
}

// MARK: - NSFetchedResultsControllerDelegate
extension ActivitiesTableViewController: NSFetchedResultsControllerDelegate {
  func controller(
    _ controller: NSFetchedResultsController<NSFetchRequestResult>,
    didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference
  ) {
    let snapshot = snapshot as NSDiffableDataSourceSnapshot<String, NSManagedObjectID>
    dataSource?.apply(snapshot)
  }
}
