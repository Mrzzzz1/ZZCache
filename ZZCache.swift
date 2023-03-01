//
//  ZZCache.swift
//  ZZCache
//
//  Created by Zjt on 2023/2/26.
//

import Foundation
class ZZCache<Element> where Element: Cacheable {
    var name = ""
    lazy var memoryCache = ZZMemoryCache<Element>()
    lazy var diskCache: ZZDBStorage<Element>
    init(name:String) throws {
        do {
            try diskCache = ZZDBStorage<Element>(name: name)
        } catch let error {
            throw error
        }
    }
    
}
extension ZZCache: ZZCacheProtocol {
    func get(_ key: String) throws -> Element {
        do {
           let value = try memoryCache.get(key)
            return value
        } catch {
            do{
                let value = try diskCache.get(key)
                DispatchQueue.global(qos: .background).async {
                    memoryCache.set(key, value: value, cost: Element.sizeOf(value: value), completion: nil)
                }
                return value
            } catch let error{
                throw error
            }
            
        }
    }
    
    func set(_ key: String, value: Element, cost: UInt, completion: (() -> Void)?) throws {
        do {
            try memoryCache.set(key, value: value, cost: cost, completion: nil)
            try diskCache.set(key, value: value, cost: cost, completion: completion)
        } catch let error {
            throw error
        }
    }
    
    func remove(_ key: String, completion: (() -> Void)?) throws {
        try? memoryCache.remove(key, completion: nil)
        do {
            try diskCache.remove(key, completion: completion)
        } catch let error {
            throw error
        }
    }
    
    func removeAll(_ completion: (() -> Void)?) throws {
        try? memoryCache.removeAll(nil)
        do {
            try diskCache.removeAll(completion)
        }
    }
    
    
}
