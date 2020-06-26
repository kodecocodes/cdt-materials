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

import Foundation
import CoreData

protocol UsesCoreDataObjects: class {
  var managedObjectContext: NSManagedObjectContext? { get set }
}

class CoreDataStack {

  private let modelName: String

  init(modelName: String) {
    self.modelName = modelName
  }

  lazy var managedContext: NSManagedObjectContext = self.storeContainer.viewContext
  var savingContext: NSManagedObjectContext {
    return storeContainer.newBackgroundContext()
  }
  
  var storeName: String = "UnCloudNotesDataModel"
  var storeURL : URL {
    let storePaths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
    let storePath = storePaths[0] as NSString
    let fileManager = FileManager.default
    
    do {
      try fileManager.createDirectory(
        atPath: storePath as String,
        withIntermediateDirectories: true,
        attributes: nil)
    } catch {
      print("Error creating storePath \(storePath): \(error)")
    }
    
    let sqliteFilePath = storePath
      .appendingPathComponent(storeName + ".sqlite")
    return URL(fileURLWithPath: sqliteFilePath)
  }

  lazy var storeDescription: NSPersistentStoreDescription = {
    let description = NSPersistentStoreDescription(url: self.storeURL)
    description.shouldMigrateStoreAutomatically = true
    description.shouldInferMappingModelAutomatically = false
    return description
  }()
  
  private lazy var storeContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: self.modelName)
    container.persistentStoreDescriptions = [self.storeDescription]
    container.loadPersistentStores { (storeDescription, error) in
      if let error = error {
        fatalError("Unresolved error \(error)")
      }
    }
    container.viewContext.automaticallyMergesChangesFromParent = true
    return container
  }()

  func saveContext () {
    guard managedContext.hasChanges else { return }

    do {
      try managedContext.save()
    } catch let error as NSError {
      fatalError("Unresolved error \(error), \(error.userInfo)")
    }
  }
}
