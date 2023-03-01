//
//  Procotol.swift
//  ZZCache
//
//  Created by Zjt on 2023/2/7.
//

import Foundation
public protocol ZZCacheProtocol {
    associatedtype Element
    func get(_ key: String)throws->Element
    func set(_ key: String, value: Element, cost: UInt, completion: (()->Void)?)throws
    func remove(_ key: String, completion: (()->Void)?)throws
    func removeAll(_ completion: (()->Void)?)throws
    func update(key: String, newValue: Element, newCost: UInt)throws
}
public extension ZZCacheProtocol {
    func update(key: String, newValue: Element, newCost: UInt)throws {
        do {
            try remove(key, completion: nil)
            try set(key, value: newValue, cost: newCost, completion: nil)
        } catch {
            throw CacheError.updateError
        }
    }
}

public extension ZZCacheProtocol {
    func contains(_ key: String)->Bool {
        if let _ = try? get(key) {
            return true
        }
        return false
    }
}

public protocol ZZCacheClearProtocol {
    func clearToTime(_ time: Double, completion: (()->Void)?)
    func clearToCount(_ count: UInt, completion: (()->Void)?)
    func clearToCost(_ cost: UInt, completion: (()->Void)?)
    func clearAll(completion: (()->Void)?)
}
public protocol ValueDatable {
    associatedtype Element
    static func valueToData(_ value: Element)->Data
    static func valueFromData(_ data: Data)->Element
}
public protocol Sizable {
    associatedtype Element
    static func sizeOf(value: Element)->UInt
}
enum CacheError: Error {
    case setError
    case getError
    case updateError
    case removeError
}
extension Int: Sizable, ValueDatable {
    public static func valueToData(_ value: Int) -> Data {
        var v = value
        return Data(bytes: &v, count: 8)
    }
    
    public static func valueFromData(_ data: Data) -> Int {
        var value = 0
        (data as NSData).getBytes(&value, length: 8)
        return value
    }
    
    public typealias Element = Int
    public static func sizeOf(value: Int) -> UInt {
        return 4
    }
}
public protocol Cacheable: Sizable, ValueDatable, Equatable {}

