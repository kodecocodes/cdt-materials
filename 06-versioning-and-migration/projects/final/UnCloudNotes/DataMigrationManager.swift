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

class DataMigrationManager {
  let enableMigrations: Bool
  let modelName: String
  let storeName: String = "UnCloudNotesDataModel"
  var stack: CoreDataStack {
    guard enableMigrations,
      !store(at: storeURL,
                  isCompatibleWithModel: currentModel)
      else { return CoreDataStack(modelName: modelName) }

    performMigration()
    return CoreDataStack(modelName: modelName)
  }
  
  init(modelNamed: String, enableMigrations: Bool = false) {
    self.modelName = modelNamed
    self.enableMigrations = enableMigrations
  }
  
  private func store(at storeURL: URL,
                     isCompatibleWithModel model: NSManagedObjectModel) -> Bool {
    let storeMetadata = metadataForStoreAtURL(storeURL: storeURL)
    return model.isConfiguration(withName: nil, compatibleWithStoreMetadata:storeMetadata)
  }
  
  private func metadataForStoreAtURL(storeURL: URL)
    -> [String: Any] {
      let metadata: [String: Any]
      do {
        metadata = try NSPersistentStoreCoordinator
          .metadataForPersistentStore(ofType: NSSQLiteStoreType,
                                      at: storeURL, options: nil)
      } catch {
        metadata = [:]
        print("Error retrieving metadata for store at URL:\(storeURL): \(error)")
      }
      return metadata
  }
  
  private var applicationSupportURL: URL {
    let path = NSSearchPathForDirectoriesInDomains(
      .applicationSupportDirectory,
      .userDomainMask, true)
      .first
    return URL(fileURLWithPath: path!)
  }
  
  private lazy var storeURL: URL = {
    let storeFileName = "\(self.storeName).sqlite"
    return URL(fileURLWithPath: storeFileName,
               relativeTo: self.applicationSupportURL)
  }()
  
  private var storeModel: NSManagedObjectModel? {
    return
      NSManagedObjectModel.modelVersionsFor(modelNamed: modelName)
        .filter {
          self.store(at: storeURL, isCompatibleWithModel: $0) }
        .first
  }
  
  private lazy var currentModel: NSManagedObjectModel = .model(named: self.modelName)
  
  func performMigration() {
    if !currentModel.isVersion4 {
      fatalError("Can only handle migrations to version 4!")
    }
    if let storeModel = self.storeModel {
      if storeModel.isVersion1 {
        let destinationModel = NSManagedObjectModel.version2
        
        migrateStoreAt(URL: storeURL,
                       fromModel: storeModel,
                       toModel: destinationModel)
        
        performMigration()
      } else if storeModel.isVersion2 {
        let destinationModel = NSManagedObjectModel.version3
        let mappingModel = NSMappingModel(from: nil,
                                          forSourceModel: storeModel,
                                          destinationModel: destinationModel)
        
        migrateStoreAt(URL: storeURL,
                       fromModel: storeModel,
                       toModel: destinationModel,
                       mappingModel: mappingModel)
        
        performMigration()
      } else if storeModel.isVersion3 {
        let destinationModel = NSManagedObjectModel.version4
        let mappingModel = NSMappingModel(from: nil,
                                          forSourceModel: storeModel,
                                          destinationModel: destinationModel)
        
        migrateStoreAt(URL: storeURL,
                       fromModel: storeModel,
                       toModel: destinationModel,
                       mappingModel: mappingModel)
      }
    }
  }
  
  private func migrateStoreAt(URL storeURL: URL,
                              fromModel from:NSManagedObjectModel,
                              toModel to:NSManagedObjectModel,
                              mappingModel:NSMappingModel? = nil) {
    
    // 1
    let migrationManager = NSMigrationManager(sourceModel: from, destinationModel: to)
    
    // 2
    var migrationMappingModel: NSMappingModel
    if let mappingModel = mappingModel {
      migrationMappingModel = mappingModel
    } else {
      migrationMappingModel = try! NSMappingModel
        .inferredMappingModel(
          forSourceModel: from, destinationModel: to)
    }
    
    // 3
    let targetURL = storeURL.deletingLastPathComponent()
    let destinationName = storeURL.lastPathComponent + "~1"
    let destinationURL = targetURL
      .appendingPathComponent(destinationName)
    
    print("From Model: \(from.entityVersionHashesByName)")
    print("To Model: \(to.entityVersionHashesByName)")
    print("Migrating store \(storeURL) to \(destinationURL)")
    print("Mapping model: \(String(describing: mappingModel))")
    
    // 4
    let success: Bool
    do {
      try migrationManager.migrateStore(from: storeURL,
                                        sourceType:NSSQLiteStoreType,
                                        options:nil,
                                        with:migrationMappingModel,
                                        toDestinationURL:destinationURL,
                                        destinationType:NSSQLiteStoreType,
                                        destinationOptions:nil)
      success = true
    } catch {
      success = false
      print("Migration failed: \(error)")
    }
    
    // 5
    if success {
      print("Migration Completed Successfully")
      
      let fileManager = FileManager.default
      do {
        try fileManager.removeItem(at: storeURL)
        try fileManager.moveItem(at: destinationURL,
                                 to: storeURL)
      } catch {
        print("Error migrating \(error)")
      }
    }
  }
}

extension NSManagedObjectModel {
  class func model(named modelName: String,
                   in bundle: Bundle = .main) -> NSManagedObjectModel {
    return
      bundle
        .url(forResource: modelName, withExtension: "momd")
        .flatMap(NSManagedObjectModel.init)
        ?? NSManagedObjectModel()
  }
  
  class var version1: NSManagedObjectModel {
    return uncloudNotesModel(named: "UnCloudNotesDataModel")
  }
  var isVersion1: Bool {
    return self == type(of: self).version1
  }
  class var version2: NSManagedObjectModel {
    return uncloudNotesModel(named: "UnCloudNotesDataModel v2")
  }
  
  var isVersion2: Bool {
    return self == type(of: self).version2
  }
  
  class var version3: NSManagedObjectModel {
    return uncloudNotesModel(named: "UnCloudNotesDataModel v3")
  }
  
  var isVersion3: Bool {
    return self == type(of: self).version3
  }
  
  class var version4: NSManagedObjectModel {
    return uncloudNotesModel(named: "UnCloudNotesDataModel v4")
  }
  
  var isVersion4: Bool {
    return self == type(of: self).version4
  }
  
  private class func modelURLs(
    in modelFolder: String) -> [URL] {
    
    return Bundle.main
      .urls(forResourcesWithExtension: "mom",
                        subdirectory:"\(modelFolder).momd") ?? []
  }
  
  class func modelVersionsFor(
    modelNamed modelName: String) -> [NSManagedObjectModel] {
    
    return modelURLs(in: modelName)
      .compactMap(NSManagedObjectModel.init)
  }
  
  class func uncloudNotesModel(
    named modelName: String) -> NSManagedObjectModel {
    
    let model = modelURLs(in: "UnCloudNotesDataModel")
      .filter { $0.lastPathComponent == "\(modelName).mom" }
      .first
      .flatMap(NSManagedObjectModel.init)
    return model ?? NSManagedObjectModel()
  }
}
