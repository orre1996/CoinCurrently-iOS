import Foundation
@preconcurrency import CoreData

private final class CoreDataBlockBox<T>: @unchecked Sendable {
    let block: @Sendable (NSManagedObjectContext) throws -> T
    init(_ block: @escaping @Sendable (NSManagedObjectContext) throws -> T) { self.block = block }
    func call(_ context: NSManagedObjectContext) throws -> T { try block(context) }
}

private let _isRunningTests: Bool = {
    ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    || NSClassFromString("XCTestCase") != nil
}()

private let _coreDataAppGroupMigrationKey = "coreDataMigratedToAppGroup"

enum CoreDataKeys: Keyable {
    case portfolio
    case favorites
    case portfolioPies
    case portfolioPrices
    case walletRefreshDate
    case networkCache
    
    func key() -> String {
        switch self {
        case .portfolio: return "portfolio"
        case .favorites: return "favorites"
        case .portfolioPies: return "portfolioPies"
        case .portfolioPrices: return "portfolioPrices"
        case .walletRefreshDate: return "walletRefreshDate"
        case .networkCache: return "networkCache"
        }
    }
}

final class CoreDataManager: @unchecked Sendable {
    static let shared = CoreDataManager()
    
    private let container: NSPersistentContainer
    private let modelName = "KeyValueModel"
    private let entityName = "KeyValueEntry"
    
    private init() {
        // 🔑 Load model programmatically
        let model = Self.makeModel(entityName: entityName)
        
        container = NSPersistentContainer(
            name: modelName,
            managedObjectModel: model
        )
        
        guard let storeDescription = container.persistentStoreDescriptions.first else {
            fatalError("Missing store description")
        }
        
        if _isRunningTests {
            storeDescription.url = URL(fileURLWithPath: "/dev/null")
        } else if let storeURL = Self.resolveStoreURL(modelName: modelName) {
            storeDescription.url = storeURL
        } else {
            // Widget/watch before the main app has migrated — avoid creating an empty shared store.
            storeDescription.type = NSInMemoryStoreType
        }
        
        storeDescription.setOption(
            true as NSNumber,
            forKey: NSPersistentHistoryTrackingKey
        )
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Unresolved error: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Store Location
    
    private static func legacyStoreURL(modelName: String) -> URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("\(modelName).sqlite")
    }
    
    private static func appGroupStoreURL(modelName: String) -> URL? {
        FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: String.groupIdentifier
        )?.appendingPathComponent("\(modelName).sqlite")
    }
    
    private static func resolveStoreURL(modelName: String) -> URL? {
        guard let appGroupStoreURL = appGroupStoreURL(modelName: modelName) else {
            return legacyStoreURL(modelName: modelName)
        }
        
        #if IS_APP
        migrateLegacyStoreIfNeeded(
            legacyStoreURL: legacyStoreURL(modelName: modelName),
            appGroupStoreURL: appGroupStoreURL
        )
        return appGroupStoreURL
        #else
        if FileManager.default.fileExists(atPath: appGroupStoreURL.path) {
            return appGroupStoreURL
        }
        return nil
        #endif
    }
    
    #if IS_APP
    private static func migrateLegacyStoreIfNeeded(
        legacyStoreURL: URL?,
        appGroupStoreURL: URL
    ) {
        let defaults = UserDefaults(suiteName: String.groupIdentifier)
        if defaults?.bool(forKey: _coreDataAppGroupMigrationKey) == true {
            return
        }
        
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: appGroupStoreURL.path) {
            defaults?.set(true, forKey: _coreDataAppGroupMigrationKey)
            return
        }
        
        guard
            let legacyStoreURL,
            fileManager.fileExists(atPath: legacyStoreURL.path)
        else {
            defaults?.set(true, forKey: _coreDataAppGroupMigrationKey)
            return
        }
        
        do {
            try copyStoreFiles(from: legacyStoreURL, to: appGroupStoreURL, fileManager: fileManager)
            defaults?.set(true, forKey: _coreDataAppGroupMigrationKey)
        } catch {
            print("Core Data app group migration failed:", error)
        }
    }
    #endif
    
    private static func copyStoreFiles(
        from sourceBase: URL,
        to destinationBase: URL,
        fileManager: FileManager
    ) throws {
        let directory = destinationBase.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: directory.path) {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        
        for suffix in ["", "-wal", "-shm"] {
            let source = URL(fileURLWithPath: sourceBase.path + suffix)
            guard fileManager.fileExists(atPath: source.path) else { continue }
            
            let destination = URL(fileURLWithPath: destinationBase.path + suffix)
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.copyItem(at: source, to: destination)
        }
    }
    
    // MARK: - Model
    
    private static func makeModel(
        entityName: String
    ) -> NSManagedObjectModel {
        
        let model = NSManagedObjectModel()
        
        let entity = NSEntityDescription()
        entity.name = entityName
        entity.managedObjectClassName =
        String(describing: KeyValueEntry.self)
        
        let keyAttr = NSAttributeDescription()
        keyAttr.name = "key"
        keyAttr.attributeType = .stringAttributeType
        keyAttr.isOptional = true
        
        let valueAttr = NSAttributeDescription()
        valueAttr.name = "valueData"
        valueAttr.attributeType = .binaryDataAttributeType
        valueAttr.allowsExternalBinaryDataStorage = true
        valueAttr.isOptional = true
        
        let typeAttr = NSAttributeDescription()
        typeAttr.name = "typeIdentifier"
        typeAttr.attributeType = .stringAttributeType
        typeAttr.isOptional = true
        
        let dateAttr = NSAttributeDescription()
        dateAttr.name = "updatedAt"
        dateAttr.attributeType = .dateAttributeType
        dateAttr.isOptional = true
        
        entity.properties = [
            keyAttr,
            valueAttr,
            typeAttr,
            dateAttr
        ]
        
        let index =
        NSFetchIndexDescription(
            name: "idx_key",
            elements: [
                NSFetchIndexElementDescription(
                    property: keyAttr,
                    collationType: .binary
                )
            ])
        
        entity.indexes = [index]
        
        model.entities = [entity]
        return model
    }
    
    // MARK: - Helpers
    
    private func performBackground<T>(
        _ block: @escaping @Sendable (NSManagedObjectContext) throws -> T
    ) async throws -> T {
        
        let box = CoreDataBlockBox(block)
        
        return try await withCheckedThrowingContinuation {
            continuation in

            container.performBackgroundTask {
                context in
                
                context.mergePolicy =
                NSMergeByPropertyObjectTrumpMergePolicy
                
                do {
                    let result = try box.call(context)
                    if context.hasChanges {
                        try context.save()
                    }
                    continuation.resume(returning: result)
                } catch {
                    context.rollback()
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Public API
    
    func set<T: Codable & Sendable>(
        _ value: T,
        forKey key: CoreDataKeys
    ) async {
        
        do {
            let data =
            try JSONEncoder().encode(value)
            
            try await performBackground { context in
                
                let fr =
                NSFetchRequest<KeyValueEntry>(
                    entityName: self.entityName
                )
                
                fr.predicate =
                NSPredicate(
                    format: "key == %@",
                    key.key()
                )
                
                fr.fetchLimit = 1
                
                let existing =
                try context.fetch(fr).first
                
                let obj: KeyValueEntry
                if let existing {
                    obj = existing
                } else if let entity = NSEntityDescription.entity(forEntityName: self.entityName, in: context) {
                    obj = KeyValueEntry(entity: entity, insertInto: context)
                } else {
                    return
                }
                
                obj.key = key.key()
                obj.valueData = data
                obj.typeIdentifier =
                String(describing: T.self)
                obj.updatedAt = Date()
            }
            
        } catch {
            print("CoreData error:", error)
        }
    }
    
    func get<T: Codable & Sendable>(
        forKey key: CoreDataKeys
    ) async -> T? {
        
        do {
            return try await performBackground {
                context in
                
                let fr =
                NSFetchRequest<KeyValueEntry>(
                    entityName: self.entityName
                )
                
                fr.predicate =
                NSPredicate(
                    format: "key == %@",
                    key.key()
                )
                
                fr.fetchLimit = 1
                
                guard
                    let obj =
                        try context.fetch(fr).first,
                    let data = obj.valueData
                else { return nil }
                
                return try JSONDecoder()
                    .decode(T.self, from: data)
            }
            
        } catch {
            return nil
        }
    }
    
    func removeValue(
        forKey key: CoreDataKeys
    ) async {
        
        do {
            try await performBackground {
                context in
                
                let fr =
                NSFetchRequest<KeyValueEntry>(
                    entityName: self.entityName
                )
                
                fr.predicate =
                NSPredicate(
                    format: "key == %@",
                    key.key()
                )
                
                let matches =
                try context.fetch(fr)
                
                for obj in matches {
                    context.delete(obj)
                }
            }
            
        } catch {
            print("CoreData error:", error)
        }
    }
    
    func contains(
        key: CoreDataKeys
    ) async -> Bool {
        
        do {
            return try await performBackground {
                context in
                
                let fr =
                NSFetchRequest<KeyValueEntry>(
                    entityName: self.entityName
                )
                
                fr.predicate =
                NSPredicate(
                    format: "key == %@",
                    key.key()
                )
                
                fr.fetchLimit = 1
                
                return try context.count(for: fr) > 0
            }
            
        } catch {
            return false
        }
    }
}
