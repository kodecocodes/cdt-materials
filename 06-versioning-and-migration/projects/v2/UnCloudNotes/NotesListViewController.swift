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

class NotesListViewController: UITableViewController {

  // MARK: - Properties
  fileprivate lazy var stack: CoreDataStack = CoreDataStack(modelName: "UnCloudNotesDataModel")

  fileprivate lazy var notes: NSFetchedResultsController<Note> = {
    let context = self.stack.managedContext
    let request = Note.fetchRequest() as! NSFetchRequest<Note>
    request.sortDescriptors = [NSSortDescriptor(key: #keyPath(Note.dateCreated), ascending: false)]

    let notes = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    notes.delegate = self
    return notes
  }()

  // MARK: - View Life Cycle
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    do {
      try notes.performFetch()
    } catch {
      print("Error: \(error)")
    }

    tableView.reloadData()
  }

  // MARK: - Navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let navController = segue.destination as? UINavigationController,
      let viewController = navController.topViewController as? UsesCoreDataObjects {
        viewController.managedObjectContext = stack.savingContext
    }

    if let detailView = segue.destination as? NoteDisplayable,
      let selectedIndex = tableView.indexPathForSelectedRow {
        detailView.note = notes.object(at: selectedIndex)
    }
  }
}

// MARK: - IBActions
extension NotesListViewController {

  @IBAction func unwindToNotesList(_ segue: UIStoryboardSegue) {
    print("Unwinding to Notes List")

    stack.saveContext()
  }
}

// MARK: - UITableViewDataSource
extension NotesListViewController {

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let objects = notes.fetchedObjects
    return objects?.count ?? 0
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let note = notes.object(at: indexPath)
    let cell: NoteTableViewCell
    if note.image == nil {
      cell = tableView.dequeueReusableCell(withIdentifier: "NoteCell", for: indexPath) as! NoteTableViewCell
    } else {
      cell = tableView.dequeueReusableCell(withIdentifier: "NoteCellWithImage", for: indexPath) as! NoteImageTableViewCell
    }
    cell.note = note
    return cell
  }
}

// MARK: - NSFetchedResultsControllerDelegate
extension NotesListViewController: NSFetchedResultsControllerDelegate {

  func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
  }

  func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
    let wrapIndexPath: (IndexPath?) -> [IndexPath] = { $0.map { [$0] } ?? [] }

    switch type {
    case .insert:
      tableView.insertRows(at: wrapIndexPath(newIndexPath), with: .automatic)
    case .delete:
      tableView.deleteRows(at: wrapIndexPath(indexPath), with: .automatic)
    case .update:
      tableView.reloadRows(at: wrapIndexPath(indexPath), with: .none)
    default:
      break
    }
  }

  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
  }
}
