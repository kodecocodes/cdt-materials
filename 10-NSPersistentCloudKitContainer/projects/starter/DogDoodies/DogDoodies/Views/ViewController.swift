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
  @IBOutlet weak var petNameLabel: UILabel!
  @IBOutlet weak var poopLabel: UILabel!
  @IBOutlet weak var peeLabel: UILabel!
  @IBOutlet weak var walkLabel: UILabel!

  let coreDataStack: CoreDataStack = {
    //swiftlint:disable:next force_cast
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let coreDataStack = appDelegate.coreDataStack
    return coreDataStack
  }()

  var poopFRC: NSFetchedResultsController<Activity>?
  var peeFRC: NSFetchedResultsController<Activity>?
  var walkFRC: NSFetchedResultsController<Activity>?

  var timer: Timer?

  var selectedPet: Pet? {
    didSet {
      if selectedPet != nil {
        petNameLabel.text = selectedPet?.name
      }
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    loadSelectedPet()
    timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
      self?.updateButtonsWithTime()
    }
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if
      segue.identifier == "SelectPet",
      let viewController = segue.destination as? PetsTableViewController {
      viewController.coreDataStack = coreDataStack
    } else if
      segue.identifier == "Activities",
      let viewController = segue.destination as? ActivitiesTableViewController {
      viewController.coreDataStack = coreDataStack
      viewController.pet = selectedPet
    }
  }

  func updateButtonsWithTime() {
    let currentPoop = poopFRC?.fetchedObjects?.first
    let currentPee = peeFRC?.fetchedObjects?.first
    let currentWalk = walkFRC?.fetchedObjects?.first

    let poopText = timeDifferenceFromNow(currentPoop?.date)
    let peeText = timeDifferenceFromNow(currentPee?.date)
    let walkText = timeDifferenceFromNow(currentWalk?.date)

    poopLabel.text = poopText
    peeLabel.text = peeText
    walkLabel.text = walkText
  }

  func timeDifferenceFromNow(_ date: Date?) -> String {
    guard let date = date else {
      return "00:00:00"
    }

    let calendar = Calendar.current
    let components: Set<Calendar.Component> = [.day, .hour, .minute, .second]
    let difference = calendar.dateComponents(components, from: date, to: Date())

    if let day = difference.day, day > 0 {
      return "Over 1 Day"
    }

    let dateDifference = calendar.date(from: difference)

    if let dateDifference = dateDifference {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "HH:mm:ss"

      return dateFormatter.string(from: dateDifference)
    }

    return "00:00:00"
  }
}

extension ViewController {
  @IBAction func selectedAction(sender: UIButton) {
    let activity = Activity(context: coreDataStack.managedContext)
    activity.date = Date()
    activity.pet = selectedPet

    switch sender.tag {
    case 0:
      activity.activityType = "poop"
      poopLabel.text = "00:00:00"
    case 1:
      activity.activityType = "pee"
      peeLabel.text = "00:00:00"
    case 2:
      activity.activityType = "walk"
      walkLabel.text = "00:00:00"
    default:
      activity.activityType = nil
    }

    coreDataStack.saveContext()
  }

  @IBAction func doneSelectingPet(unwindSegue: UIStoryboardSegue) {
    loadSelectedPet()
  }
}

extension ViewController {
  func loadSelectedPet() {
    let petService = PetService(context: coreDataStack.managedContext)
    selectedPet = petService.selectedPet()

    guard selectedPet != nil else {
      return
    }

    poopFRC = NSFetchedResultsController(
      fetchRequest: petService.latestActivity(for: .poop),
      managedObjectContext: coreDataStack.managedContext,
      sectionNameKeyPath: nil,
      cacheName: nil)
    poopFRC?.delegate = self
    try? poopFRC?.performFetch()
    peeFRC = NSFetchedResultsController(
      fetchRequest: petService.latestActivity(for: .pee),
      managedObjectContext: coreDataStack.managedContext,
      sectionNameKeyPath: nil,
      cacheName: nil)
    peeFRC?.delegate = self
    try? peeFRC?.performFetch()
    walkFRC = NSFetchedResultsController(
      fetchRequest: petService.latestActivity(for: .walk),
      managedObjectContext: coreDataStack.managedContext,
      sectionNameKeyPath: nil,
      cacheName: nil)
    walkFRC?.delegate = self
    try? walkFRC?.performFetch()
  }
}

extension ViewController: NSFetchedResultsControllerDelegate {
  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
  }
}
