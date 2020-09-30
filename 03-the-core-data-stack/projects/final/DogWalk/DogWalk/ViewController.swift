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

class ViewController: UIViewController {
  // MARK: - Properties
  lazy var dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
  }()

  lazy var coreDataStack = CoreDataStack(modelName: "DogWalk")

  var currentDog: Dog?

  // MARK: - IBOutlets
  @IBOutlet var tableView: UITableView!

  // MARK: - View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")

    let dogName = "Fido"
    let dogFetch: NSFetchRequest<Dog> = Dog.fetchRequest()
    dogFetch.predicate = NSPredicate(format: "%K == %@", #keyPath(Dog.name), dogName)

    do {
      let results = try coreDataStack.managedContext.fetch(dogFetch)
      if results.isEmpty {
        // Fido not found, create Fido
        currentDog = Dog(context: coreDataStack.managedContext)
        currentDog?.name = dogName
        coreDataStack.saveContext()
      } else {
        // Fido found, use Fido
        currentDog = results.first
      }
    } catch let error as NSError {
      print("Fetch error: \(error) description: \(error.userInfo)")
    }
  }
}

// MARK: - IBActions
extension ViewController {
  @IBAction func add(_ sender: UIBarButtonItem) {
    let walk = Walk(context: coreDataStack.managedContext)
    walk.date = Date()

    if let dog = currentDog,
      let walks = dog.walks?.mutableCopy()
        as? NSMutableOrderedSet {
        walks.add(walk)
        dog.walks = walks
    }

    coreDataStack.saveContext()
    tableView.reloadData()
  }
}

// MARK: UITableViewDataSource
extension ViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    currentDog?.walks?.count ?? 0
  }

  func tableView(
    _ tableView: UITableView,
    cellForRowAt indexPath: IndexPath
  ) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: "Cell", for: indexPath)

    guard let walk = currentDog?.walks?[indexPath.row] as? Walk,
      let walkDate = walk.date as Date? else {
        return cell
    }

    cell.textLabel?.text = dateFormatter.string(from: walkDate)
    return cell
  }

  func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
    "List of Walks"
  }

  func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
    true
  }

  func tableView(
    _ tableView: UITableView,
    commit editingStyle: UITableViewCell.EditingStyle,
    forRowAt indexPath: IndexPath
  ) {
    guard let walkToRemove =
      currentDog?.walks?[indexPath.row] as? Walk,
      editingStyle == .delete else {
      return
    }

    coreDataStack.managedContext.delete(walkToRemove)
    coreDataStack.saveContext()
    tableView.deleteRows(at: [indexPath], with: .automatic)
  }
}
