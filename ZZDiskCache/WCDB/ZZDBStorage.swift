//
//  ZZDBStorager.swift
//  ZZCache
//
//  Created by Zjt on 2023/2/8.
//

import Foundation
import WCDBSwift
public class ZZDBStorage<E> where E: ValueDatable, E: Sizable {
    private var database: Database!
    // private let PathLengthMax = PATH_MAX - 64
    var name: String
    var tableName: String {
        return name + "Table"
    }

    private lazy var dbUrl: URL = {
        var url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appendingPathComponent("com.zz.disk.cache").appendingPathComponent("db").appendingPathComponent(name + ".db")
        print(url)
        return url
    }()

    init(name: String) throws {
        self.name = name
        database = Database(withFileURL: dbUrl)
        do {
            try database.create(table: tableName, of: ZZStorageItem.self)
        } catch {
            throw (error)
        }
    }
}

extension ZZDBStorage {
    // 更新最近访问时间
    private func updateAccessTime(_ key: String) throws {
        let item = ZZStorageItem()
        do {
            try database.update(table: tableName, on: ZZStorageItem.Properties.accessTime, with: item, where: ZZStorageItem.Properties.key == key)
        } catch {
            throw error
        }
    }

    // 更新修改时间
    private func updateModTime(_ key: String) throws {
        let item = ZZStorageItem()
        do {
            try database.update(table: tableName, on: ZZStorageItem.Properties.modTime, with: item, where: ZZStorageItem.Properties.key == key)
        } catch {
            throw error
        }
    }

    // 获取全部缓存数量
    func getTotalCount() -> UInt {
        if let items: [ZZStorageItem] = try? database.getObjects(fromTable: tableName) {
            return UInt(items.count)
        }
        return 0
    }

    // 获取全部缓存内存
    func getTotalCost() -> UInt {
        if let items: [ZZStorageItem] = try? database.getObjects(fromTable: tableName) {
            return items.reduce(0) {
                $0 + $1.size
            }
        }
        return 0
    }

    // debug
    func printAll() {
        if let items: [ZZStorageItem] = try? database.getObjects(fromTable: tableName) {
            for item in items {
                print("key: " + item.key + " size: " + item.size + " accessTime: " + item.accessTime + " modTime: " + item.modTime)
            }
        }
    }
}

extension ZZDBStorage: ZZCacheProtocol {
    public typealias Element = E.Element
    /// 根据key获取缓存元素并更新访问时间
    public func get(_ key: String) throws -> E.Element {
        do {
            if let item: ZZStorageItem = try database.getObject(fromTable: tableName, where: ZZStorageItem.Properties.key == key) {
                DispatchQueue.global(qos: .background).async {
                    try? self.updateAccessTime(key)
                }
                return E.valueFromData(item.value)
            }
            throw CacheError.getError
        }
    }
    
    // 添加缓存元素
    public func set(_ key: String, value: E.Element, cost: UInt, completion: (() -> Void)?) throws {
        let valueData = E.valueToData(value)
        let item = ZZStorageItem(key: key, value: valueData, size: cost)
        do {
            try database.insert(objects: item, intoTable: tableName)
            completion?()
        } catch {
            throw error
        }
    }

    // 删除缓存元素
    public func remove(_ key: String, completion: (() -> Void)?) throws {
        do {
            try database.delete(fromTable: tableName, where: ZZStorageItem.Properties.key == key)
            completion?()
        } catch {
            throw error
        }
    }

    // 删除所有缓存
    public func removeAll(_ completion: (() -> Void)?) throws {
        do {
            try database.delete(fromTable: tableName)
            completion?()
        } catch {
            throw error
        }
    }

    // 更新缓存元素
    public func update(key: String, newValue: E.Element, newCost: UInt) throws {
        let newValueData = E.valueToData(newValue)
        let item = ZZStorageItem(key: key, value: newValueData, size: newCost)
        do {
            try database.update(table: tableName, with: item, where: ZZStorageItem.Properties.key == key)
        } catch {
            throw error
        }
    }
}

extension ZZDBStorage: ZZCacheClearProtocol {
    // 清理所有缓存
    public func clearAll(completion: (() -> Void)?) {
        try? database.delete(fromTable: tableName)
        completion?()
    }

    // 清理time之前的所有缓存
    public func clearToTime(_ time: Double, completion: (() -> Void)?) {
        try? database.delete(fromTable: tableName, where: ZZStorageItem.Properties.modTime < time)
        completion?()
    }

    // 根据最后访问时间清理到count
    public func clearToCount(_ count: UInt, completion: (() -> Void)?) {
        var totalCount = getTotalCount()
        guard var items: [ZZStorageItem] = try? database.getObjects(fromTable: tableName, orderBy: [ZZStorageItem.Properties.accessTime]) else { return }
        while totalCount>count {
            let key = items[0].key
            try? database.delete(fromTable: tableName, where: ZZStorageItem.Properties.key == key)
            totalCount -= 1
            items.remove(at: 0)
        }
        completion?()
    }

    // 根据最后访问时间清理到cost
    public func clearToCost(_ cost: UInt, completion: (() -> Void)?) {
        var totalCost = getTotalCost()
        guard var items: [ZZStorageItem] = try? database.getObjects(fromTable: tableName, orderBy: [ZZStorageItem.Properties.accessTime]) else { return }
        while totalCost>cost {
            let key = items[0].key
            totalCost -= items[0].size
            try? database.delete(fromTable: tableName, where: ZZStorageItem.Properties.key == key)
            items.remove(at: 0)
        }
        completion?()
    }
}
