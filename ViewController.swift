//
//  ViewController.swift
//  ZZCache
//
//  Created by Zjt on 2023/2/7.
//

import UIKit

class ViewController: UIViewController {
    var cache = ZZMemoryCache<Int>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        testFM()
    }
    func test () {
        print("set")
        for i in 0..<10000 {
           try? cache.set("\(i)", value: i, cost: 1){ [weak self] in
                guard let self = self else { return }
                if i%10000==0 {
                    print(self.cache.totalCount)
                    print(self.cache.totalCount)
                    sleep(1)
                }
                
            }
        }
        sleep(2)
        print("get")
        for i in 0..<100000 {
            if i%10000 == 0 {
                if let value = try? cache.get("\(i)") {
                    print("\(i)->\(value)")
                } else {
                    print("get\(i) error")
                }
            }
        }
        sleep(2)
        print("remove")
        for i in 0..<100000 {
            if i%10000 == 0 {
               try? cache.remove("\(i)", completion: nil)
            }
        }
        sleep(2)
        print("get again")
        for i in 0..<100000 {
            if i%10000 == 0 {
                if let value = try? cache.get("\(i)") {
                    print("\(i)->\(value)")
                } else {
                    print("get\(i) error")
                }
            }
        }
        sleep(2)
        print("clearToCount50000")
        cache.clearToCount(50000, completion: nil)
        print(cache.totalCount)
        print(cache.totalCost)
        sleep(2)
        print("clearToCost20000")
        cache.clearToCost(20000, completion: nil)
        print(cache.totalCount)
        print(cache.totalCost)
        //sleep(10)
        print("remove All")
        try? cache.removeAll(){
            print("have removeAll")
        }
        //sleep(2)
        print("over")
        
        
    }
    class People{
      var age: Int
        init(age: Int){
            self.age = age
        }
    }
    var dic: [Int:People] = [:]
    func test1() {
        
        for i in 0..<100000 {
            dic[i] = People(age: i)
        }
        sleep(5)
        print("removeAll")
        var tmp = dic
        dic=[:]
        DispatchQueue.global(qos: .background).async {
            sleep(2)
            tmp.removeAll()
            print("have remove")
        }
        print("return")
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print("touch")
        test()
    }
    func testWCDB(){
        guard let WCDB = try? ZZDBStorage<Int>(name: "test") else { return }
//        for i in 0..<500 {
//            try! WCDB.set("\(i)", value: i, cost: Int.sizeOf(value: i) , completion: nil)
//        }
        WCDB.printAll()
        print("count:\(WCDB.getTotalCount())")
        print("cost:\(WCDB.getTotalCost())")
        let a = try! WCDB.get("200")
        print(a)
//        let data = Int.valueToData(5)
//        let a = Int.valueFromData(data)
//        print(a)
    }


}

