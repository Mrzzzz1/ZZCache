//
//  File.swift
//  ZZCache
//
//  Created by Zjt on 2023/2/7.
//

import Foundation
import UIKit
public class ZZMemoryCache<E> where E: Equatable, E: Sizable {
    var queueLabel = "com.cache.memory"
    var costLimit: UInt = UInt.max
    var countLimit: UInt = UInt.max
    var timeLimit: Double = Double.greatestFiniteMagnitude
    var autoclearInterval: Double = 5
    var shouldRemoveAllOnMemoryWarning = true
    var shouldRemoveAllWhenEnteringBackground = true
    var receivedMemoryWarningBlock: ((_ cache: ZZMemoryCache)->Void)?
    var enteringBackgroundBlock: ((_ cache: ZZMemoryCache)->Void)?
    private var lock = pthread_mutex_t()
    private var lru = ZZLinkedMap<E>()
    lazy private var clearQueue = DispatchQueue(label: queueLabel, qos: .background, attributes: .concurrent, autoreleaseFrequency: .workItem, target: nil)
    
    //计算属性
    var totalCost: UInt {
        pthread_mutex_lock(&lock)
        let cost = lru.totalCost
        pthread_mutex_unlock(&lock)
        return cost
    }
    var totalCount: UInt {
        pthread_mutex_lock(&lock)
        let count = lru.totalCount
        pthread_mutex_unlock(&lock)
        return count
    }
    
    var releaseOnMainThread: Bool {
        get {
            pthread_mutex_lock(&lock)
            let flag = lru.releaseOnMainThread
            pthread_mutex_unlock(&lock)
            return flag
        }
        set {
            pthread_mutex_lock(&lock)
            lru.releaseOnMainThread = newValue
            pthread_mutex_unlock(&lock)
        }
    }
    var releaseGlobalAsync: Bool {
        get {
            pthread_mutex_lock(&lock)
            let flag = lru.releaseGlobalAsync
            pthread_mutex_unlock(&lock)
            return flag
        }
        set {
            pthread_mutex_lock(&lock)
            lru.releaseGlobalAsync = newValue
            pthread_mutex_unlock(&lock)
        }
    }
    init() {
        pthread_mutex_init(&lock, nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appReceivedMemoryWarning), name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appEnteringBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
    }
    @objc func appReceivedMemoryWarning() {
            receivedMemoryWarningBlock?(self)
            if shouldRemoveAllOnMemoryWarning {
               _ = try? removeAll(nil)
            }
    }
    @objc func appEnteringBackground() {
        enteringBackgroundBlock?(self)
        if shouldRemoveAllWhenEnteringBackground {
            _ = try? removeAll(nil)
        }
    }
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didReceiveMemoryWarningNotification, object: nil)
        //lru.removeAll()
        
    }
    
}
extension ZZMemoryCache: ZZCacheProtocol {
    
    public typealias Element = E
    
    
    public func get(_ key: String) throws -> E {
        pthread_mutex_lock(&lock)
        let node = lru.dic[key]
        if let _node = node {
            lru.bringNodeToHead(_node)
            _node.time = CACurrentMediaTime()
        }
        pthread_mutex_unlock(&lock)
        if let node = node {
            return node.value
        }
        throw CacheError.getError
    }
    
    public func set(_ key: String, value: Element, cost: UInt, completion: (() -> Void)?) throws {
        pthread_mutex_lock(&lock)
        var node = lru.dic[key]
        let now = CACurrentMediaTime()
        if let node = node {
            node.time = now
            node.value = value
            lru.totalCost -= node.cost
            lru.totalCost += cost
            node.cost = cost
            lru.bringNodeToHead(node)
        } else {
            node = ZZLinkNode(key: key, value: value, pre: nil, next: nil, cost: cost, time: now)
            lru.insert(node!)
        }
        pthread_mutex_unlock(&lock)
        if totalCost>costLimit {
            print("cost over")
            clearQueue.async {
                self.clearToCost(self.costLimit/2, completion: nil)
            }
        }else if totalCount>countLimit {
            print("count over")
            clearQueue.async {
                self.clearToCount(self.countLimit, completion: nil)
            }
        }
        pthread_mutex_unlock(&lock)
        completion?()
    }
    
    public func remove(_ key: String, completion: (() -> Void)?) throws {
        pthread_mutex_lock(&lock)
        let node = lru.dic[key]
        guard let node = node else {
        pthread_mutex_unlock(&lock)
        throw CacheError.removeError
        }
        lru.removeNode(node)
        pthread_mutex_unlock(&lock)
        completion?()
    }
    
    public func removeAll(_ completion: (() -> Void)?) throws {
        pthread_mutex_lock(&lock)
        lru.removeAll()
        pthread_mutex_unlock(&lock)
        completion?()
    }
    
}

extension ZZMemoryCache: ZZCacheClearProtocol {
    public func clearToTime(_ time: Double, completion: (() -> Void)?) {
        let now = CACurrentMediaTime()
        pthread_mutex_lock(&lock);
        var tailTime = lru.tail?.time ?? now;
        pthread_mutex_unlock(&lock);
        while(now-tailTime>time){
            if pthread_mutex_trylock(&lock)==0 {
                _ = lru.removeTail()
                tailTime = lru.tail?.time ?? now
                pthread_mutex_unlock(&lock)
            } else {
                usleep(10*1000)
            }
        }
        completion?()
    }
    
    public func clearToCount(_ count: UInt, completion: (() -> Void)?) {
        while totalCount>count {
            if pthread_mutex_trylock(&lock)==0 {
                _ = lru.removeTail()
                pthread_mutex_unlock(&lock)
            } else {
                usleep(10*1000)
            }
        }
        completion?()
    }
    
    public func clearToCost(_ cost: UInt, completion: (() -> Void)?) {
        while totalCost>cost {
            if pthread_mutex_trylock(&lock)==0 {
                _ = lru.removeTail()
                pthread_mutex_unlock(&lock)
            } else {
                usleep(10*1000)
            }
        }
        completion?()
    }
    
    public func clearAll(completion: (() -> Void)?) {
        pthread_mutex_lock(&lock)
        lru.removeAll()
        pthread_mutex_unlock(&lock)
        completion?()
        
    }
    
}
//下标方法
extension ZZMemoryCache {
    public subscript(key: String, cost: UInt) -> Element? {
        get {
            return try? get(key)
        }
        set {
            guard let newValue = newValue else { return }
            _ = try? set(key, value: newValue, cost: cost, completion: nil)
        }
    }
    public subscript(key: String) -> Element? {
        
        get {
            return self[key,0]
        }
        set {
            self[key,0] = newValue
        }
    }
}
                                               
    
