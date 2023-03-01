//
//  ZZLinkedMap.swift
//  ZZCache
//
//  Created by l on 2023/2/7.
//

import Foundation
internal class ZZLinkedMap<E> where E: Equatable {
    var dic: [String: ZZLinkNode<E>] = [:]
    var totalCost: UInt = 0
    var totalCount: UInt = 0
    var releaseOnMainThread: Bool = true
    var releaseGlobalAsync: Bool = true
    var head: ZZLinkNode<E>?
    var tail: ZZLinkNode<E>?
}
internal extension ZZLinkedMap {
    //将节点插入到链表头部
    func insert(_ node: ZZLinkNode<E>) {
        dic[node.key] = node
        if let _head = head {
            node.next = _head
            _head.pre = node
            head = node
        }
        else {
            head = node
            tail = node
            
        }
        totalCost += node.cost
        totalCount += 1
    }
    
    //将链表中的节点插入表头
    func bringNodeToHead(_ node: ZZLinkNode<E>) {
        let key = node.key
        guard let _node=dic[key] else { return }
        if !(_node==node) { return }
        if(head == node) { return }
        if(tail == node) {
            node.pre?.next = nil
            tail = node.pre
        }
        else {
            node.pre?.next = node.next
            node.next?.pre = node.pre
        }
        head?.pre = node
        node.next = head
        node.pre = nil
        head = node
    }
    
    func removeNode(_ node: ZZLinkNode<E>) {
        let key = node.key
        if !dic.keys.contains(key) { return }
        dic.removeValue(forKey: key)
        if let next = node.next {
            next.pre = node.pre
        }
        if let pre = node.pre {
            pre.next = node.next
        }
        if head == node {
            head = node.next
        }
        if tail == node {
            tail = node.pre
        }
        totalCost -= node.cost
        totalCount -= 1
    }
    
    func removeTail() -> ZZLinkNode<E>? {
        guard var _tail = tail else { return nil }
        dic.removeValue(forKey: _tail.key)
        if head == tail {
            head = nil
            tail = nil
        } else {
            tail = _tail.pre
            tail?.next = nil
        }
        totalCost -= _tail.cost
        totalCount -= 1
        
        return _tail
    }
    
    func removeAll() {
        if dic.count == 0 { return }
        totalCost = 0
        totalCount = 0
        head = nil
        tail = nil
        //dic.removeAll()
        var tmp = dic
        dic = [:]
        if releaseOnMainThread {
            DispatchQueue.main.async {
                tmp.removeAll()
            }
        } else if releaseGlobalAsync {
            DispatchQueue.global(qos: .background).async {
                tmp.removeAll()
                //print("OK")
            }
        } else {
            tmp.removeAll()
        }
        //print("return")
    }
    
}
