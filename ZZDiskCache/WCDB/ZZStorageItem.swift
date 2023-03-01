//
//  ZZStorageItem.swift
//  ZZCache
//
//  Created by Zjt on 2023/2/8.
//

import Foundation
import WCDBSwift
class ZZStorageItem: TableCodable {
    var key: String = ""
    var size: UInt = 0
    //更新时间
    var modTime: Double = 0
    //访问时间
    var accessTime: Double = 0
    var value: Data = Data()
    enum CodingKeys: String, CodingTableKey {
        typealias Root = ZZStorageItem
        static let objectRelationalMapping = TableBinding(CodingKeys.self)
        case key
        case size
        case modTime
        case accessTime
        case value
        public static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
                    return [key: ColumnConstraintBinding(isPrimary: true, isNotNull: true, defaultTo: "")]
                }
        }
    init(key: String,value: Data, size: UInt = 0){
        self.key = key
        self.value = value
        self.size = size
        self.modTime = CACurrentMediaTime()
        self.accessTime = CACurrentMediaTime()
    }
    init(){}
    
    
    
}
