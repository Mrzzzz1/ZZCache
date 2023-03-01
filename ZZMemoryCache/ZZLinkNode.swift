//
//  _ZZLinkNode.swift
//  ZZCache
//
//  Created by Zjt on 2023/2/7.
//

import Foundation
internal class ZZLinkNode<E> where E: Equatable {
    
    var key: String
    var value: E
    weak var pre: ZZLinkNode<E>?
    weak var next: ZZLinkNode<E>?
    var cost: UInt = 0
    var time: Double = 0
    init(key: String, value: E, pre: ZZLinkNode<E>?, next: ZZLinkNode<E>?, cost: UInt, time: Double){
        self.key = key
        self.value = value
        self.pre = pre
        self.next = next
        self.cost = cost
        self.time = time
    }
}
extension ZZLinkNode: Equatable {
    static func == (lhs: ZZLinkNode<E>, rhs: ZZLinkNode<E>) -> Bool {
        return lhs.key == rhs.key && lhs.value == rhs.value
    }
    
    
}
