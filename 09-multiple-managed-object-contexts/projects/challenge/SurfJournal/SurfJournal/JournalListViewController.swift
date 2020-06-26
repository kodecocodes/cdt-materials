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

class JournalListViewController: UITableViewController {

  // MARK: Properties
  var coreDataStack: CoreDataStack!
  var fetchedResultsController: NSFetchedResultsController<JournalEntry> = NSFetchedResultsController()

  // MARK: IBOutlets
  @IBOutlet weak var exportButton: UIBarButtonItem!
  
  // MARK: View Life Cycle
  override func viewDidLoad() {
    super.viewDidLoad()

    configureView()
  }

  // MARK: Navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    // 1
    if segue.identifier == "SegueListToDetail" {
      // 2
      guard let navigationController = segue.destination as? UINavigationController,
        let detailViewController = navigationController.topViewController as? JournalEntryViewController,
        let indexPath = tableView.indexPathForSelectedRow else {
          fatalError("Application storyboard mis-configuration")
      }
      // 3
      let surfJournalEntry = fetchedResultsController.object(at: indexPath)

      let childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
      childContext.parent = coreDataStack.mainContext

      let childEntry = childContext.object(with: surfJournalEntry.objectID) as? JournalEntry

      detailViewController.journalEntry = childEntry
      detailViewController.context = childContext
      detailViewController.delegate = self

    } else if segue.identifier == "SegueListToDetailAdd" {

      guard let navigationController = segue.destination as? UINavigationController,
        let detailViewController = navigationController.topViewController as? JournalEntryViewController else {
          fatalError("Application storyboard mis-configuration")
      }

      let childContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
      childContext.parent = coreDataStack.mainContext

      let newJournalEntry = JournalEntry(context: childContext)

      detailViewController.journalEntry = newJournalEntry
      detailViewController.context = newJournalEntry.managedObjectContext
      detailViewController.delegate = self
    }
  }
}

// MARK: IBActions
extension JournalListViewController {

  @IBAction func exportButtonTapped(_ sender: UIBarButtonItem) {
    exportCSVFile()
  }
}

// MARK: Private
private extension JournalListViewController {

  func configureView() {
    fetchedResultsController = journalListFetchedResultsController()
  }
  
  func exportCSVFile() {
    navigationItem.leftBarButtonItem = activityIndicatorBarButtonItem()
    // 1
    coreDataStack.storeContainer.performBackgroundTask { context in
      var results: [JournalEntry] = []
      do {
        results = try context.fetch(self.surfJournalFetchRequest())
      } catch let error as NSError {
        print("ERROR: \(error.localizedDescription)")
      }

      // 2
      let exportFilePath = NSTemporaryDirectory() + "export.csv"
      let exportFileURL = URL(fileURLWithPath: exportFilePath)
      FileManager.default.createFile(atPath: exportFilePath, contents: Data(), attributes: nil)

      // 3
      let fileHandle: FileHandle?
      do {
        fileHandle = try FileHandle(forWritingTo: exportFileURL)
      } catch let error as NSError {
        print("ERROR: \(error.localizedDescription)")
        fileHandle = nil
      }

      if let fileHandle = fileHandle {
        // 4
        for journalEntry in results {
          fileHandle.seekToEndOfFile()
          guard let csvData = journalEntry
            .csv()
            .data(using: .utf8, allowLossyConversion: false) else {
              continue
          }
          fileHandle.write(csvData)
        }

        // 5
        fileHandle.closeFile()

        print("Export Path: \(exportFilePath)")
        // 6
        DispatchQueue.main.async {
          self.navigationItem.leftBarButtonItem = self.exportBarButtonItem()
          self.showExportFinishedAlertView(exportFilePath)
        }
      } else {
        DispatchQueue.main.async {
          self.navigationItem.leftBarButtonItem = self.exportBarButtonItem()
        }
      }
    } // 7 Closing brace for performBackgroundTask
  }

  // MARK: Export

  func activityIndicatorBarButtonItem() -> UIBarButtonItem {
    let activityIndicator = UIActivityIndicatorView(style: .medium)
    let barButtonItem = UIBarButtonItem(customView: activityIndicator)
    activityIndicator.startAnimating()

    return barButtonItem
  }

  func exportBarButtonItem() -> UIBarButtonItem {
    return UIBarButtonItem(title: "Export", style: .plain, target: self, action: #selector(exportButtonTapped(_:)))
  }

  func showExportFinishedAlertView(_ exportPath: String) {
    let message = "The exported CSV file can be found at \(exportPath)"
    let alertController = UIAlertController(title: "Export Finished", message: message, preferredStyle: .alert)
    let dismissAction = UIAlertAction(title: "Dismiss", style: .default)
    alertController.addAction(dismissAction)

    present(alertController, animated: true)
  }
}

// MARK: NSFetchedResultsController
private extension JournalListViewController {

  func journalListFetchedResultsController() -> NSFetchedResultsController<JournalEntry> {
    let fetchedResultController = NSFetchedResultsController(fetchRequest: surfJournalFetchRequest(),
                                                             managedObjectContext: coreDataStack.mainContext,
                                                             sectionNameKeyPath: nil,
                                                             cacheName: nil)
    fetchedResultController.delegate = self

    do {
      try fetchedResultController.performFetch()
    } catch let error as NSError {
      fatalError("Error: \(error.localizedDescription)")
    }

    return fetchedResultController
  }

  func surfJournalFetchRequest() -> NSFetchRequest<JournalEntry> {
    let fetchRequest:NSFetchRequest<JournalEntry> = JournalEntry.fetchRequest()
    fetchRequest.fetchBatchSize = 20

    let sortDescriptor = NSSortDescriptor(key: #keyPath(JournalEntry.date), ascending: false)
    fetchRequest.sortDescriptors = [sortDescriptor]

    return fetchRequest
  }
}

// MARK: NSFetchedResultsControllerDelegate
extension JournalListViewController: NSFetchedResultsControllerDelegate {

  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    tableView.reloadData()
  }
}

// MARK: UITableViewDataSource
extension JournalListViewController {

  override func numberOfSections(in tableView: UITableView) -> Int {
    return fetchedResultsController.sections?.count ?? 0
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return fetchedResultsController.sections?[section].numberOfObjects ?? 0
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! SurfEntryTableViewCell
    configureCell(cell, indexPath: indexPath)
    return cell
  }

  private func configureCell(_ cell: SurfEntryTableViewCell, indexPath: IndexPath) {
    let surfJournalEntry = fetchedResultsController.object(at: indexPath)
    cell.dateLabel.text = surfJournalEntry.stringForDate()
    
    guard let rating = surfJournalEntry.rating?.int32Value else { return }

    switch rating {
    case 1:
      cell.starOneFilledImageView.isHidden = false
      cell.starTwoFilledImageView.isHidden = true
      cell.starThreeFilledImageView.isHidden = true
      cell.starFourFilledImageView.isHidden = true
      cell.starFiveFilledImageView.isHidden = true
    case 2:
      cell.starOneFilledImageView.isHidden = false
      cell.starTwoFilledImageView.isHidden = false
      cell.starThreeFilledImageView.isHidden = true
      cell.starFourFilledImageView.isHidden = true
      cell.starFiveFilledImageView.isHidden = true
    case 3:
      cell.starOneFilledImageView.isHidden = false
      cell.starTwoFilledImageView.isHidden = false
      cell.starThreeFilledImageView.isHidden = false
      cell.starFourFilledImageView.isHidden = true
      cell.starFiveFilledImageView.isHidden = true
    case 4:
      cell.starOneFilledImageView.isHidden = false
      cell.starTwoFilledImageView.isHidden = false
      cell.starThreeFilledImageView.isHidden = false
      cell.starFourFilledImageView.isHidden = false
      cell.starFiveFilledImageView.isHidden = true
    case 5:
      cell.starOneFilledImageView.isHidden = false
      cell.starTwoFilledImageView.isHidden = false
      cell.starThreeFilledImageView.isHidden = false
      cell.starFourFilledImageView.isHidden = false
      cell.starFiveFilledImageView.isHidden = false
    default:
      cell.starOneFilledImageView.isHidden = true
      cell.starTwoFilledImageView.isHidden = true
      cell.starThreeFilledImageView.isHidden = true
      cell.starFourFilledImageView.isHidden = true
      cell.starFiveFilledImageView.isHidden = true
    }
  }

  override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    guard case(.delete) = editingStyle else { return }

    let surfJournalEntry = fetchedResultsController.object(at: indexPath)
    coreDataStack.mainContext.delete(surfJournalEntry)
    coreDataStack.saveContext()
  }
}

// MARK: JournalEntryDelegate
extension JournalListViewController: JournalEntryDelegate {

  func didFinish(viewController: JournalEntryViewController, didSave: Bool) {
    // 1
    guard didSave,
      let context = viewController.context,
      context.hasChanges else {
        dismiss(animated: true)
        return
    }
    // 2
    context.perform {
      do {
        try context.save()
      } catch let error as NSError {
        fatalError("Error: \(error.localizedDescription)")
      }
      // 3
      self.coreDataStack.saveContext()
    }
    // 4
    dismiss(animated: true)
  }
}
