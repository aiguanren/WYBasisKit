//
//  WYArchivedController.swift
//  WYBasisKitVerify
//
//  Created by 官人 on 2025/7/7.
//

import UIKit
import WYBasisKit

class Address: NSObject, Codable {
    var city: String
    var zip:  String
    
    init(city: String, zip: String) {
        self.city = city
        self.zip = zip
    }
}

class User: NSObject, Codable {
    var name:     String
    var age:      Int
    var birthday: Date
    var tags:     [String]
    var address:  Address
    
    
    init(name: String, age: Int, birthday: Date, tags: [String], address: Address) {
        self.name = name
        self.age = age
        self.birthday = birthday
        self.tags = tags
        self.address = address
    }
}

class WYArchivedController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let user = User(
            name: "张三",
            age:  30,
            birthday: Date(),
            tags: ["跑步", "摄影"],
            address: Address(city: "上海", zip: "200000")
        )
        
        let codable: WYCodable = WYCodable()
        do {
            let data = try codable.encode(Data.self, from: user)
            let back = try codable.decode(User.self, from: data)
            wy_print(back)
        } catch {
            print("归档或解档失败：", error)
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
