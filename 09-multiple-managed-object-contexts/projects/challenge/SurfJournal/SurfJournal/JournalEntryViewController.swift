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

// MARK: JournalEntryDelegate
protocol JournalEntryDelegate {
  func didFinish(viewController: JournalEntryViewController, didSave: Bool)
}

class JournalEntryViewController: UITableViewController {

  // MARK: Properties
  var journalEntry: JournalEntry?
  var context: NSManagedObjectContext!
  var delegate:JournalEntryDelegate?

  // MARK: IBOutlets
  @IBOutlet weak var heightTextField: UITextField!
  @IBOutlet weak var periodTextField: UITextField!
  @IBOutlet weak var windTextField: UITextField!
  @IBOutlet weak var locationTextField: UITextField!
  @IBOutlet weak var ratingSegmentedControl: UISegmentedControl!

  // MARK: View Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()

    configureView()
  }
}

// MARK: Private
private extension JournalEntryViewController {

  func configureView() {
    guard let journalEntry = journalEntry else { return }

    title = journalEntry.stringForDate()

    heightTextField.text = journalEntry.height
    periodTextField.text = journalEntry.period
    windTextField.text = journalEntry.wind
    locationTextField.text = journalEntry.location

    guard let rating = journalEntry.rating else { return }

    ratingSegmentedControl.selectedSegmentIndex = rating.intValue - 1
  }

  func updateJournalEntry() {
    guard let entry = journalEntry else { return }

    entry.date = Date()
    entry.height = heightTextField.text
    entry.period = periodTextField.text
    entry.wind = windTextField.text
    entry.location = locationTextField.text
    entry.rating = NSNumber(value:ratingSegmentedControl.selectedSegmentIndex + 1)
  }
}

// MARK: IBActions
extension JournalEntryViewController {
  
  @IBAction func cancelButtonWasTapped(_ sender: UIBarButtonItem) {
    delegate?.didFinish(viewController: self, didSave: false)
  }
  
  @IBAction func saveButtonWasTapped(_ sender: UIBarButtonItem) {
    updateJournalEntry()
    delegate?.didFinish(viewController: self, didSave: true)
  }
}

