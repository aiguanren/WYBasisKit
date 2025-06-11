//
//  WYMultilevelTableViewController.swift
//  WYBasisKit
//
//  Created by 官人 on 2021/1/28.
//  Copyright © 2021 官人. All rights reserved.
//

import UIKit

/**
 * 无限折叠的原理其实很简单
 * 1.不会新增section，只会新增row
 * 2.根据不同类型判断显示不同cell或利用视觉差拉开子级row与父级row之间的布局原点X，如一级页面有个label的原点X为10，二级页面就可以设置label的原点X为20，三级页面就可以设置label的原点X为30，以此类推，达到新增section一样的效果
 */

class WYMultilevelTableViewController: UIViewController {
    
    var dataSource: [WYMultilevelTable] = []

    lazy var tableView: UITableView = {

        let tableview = UITableView.wy_shared(style: .plain, separatorStyle: .singleLine, delegate: self, dataSource: self, superView: view)
        tableview.wy_register(UITableViewCell.self, .cell)
        tableview.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(wy_navViewHeight)
            make.left.right.bottom.equalToSuperview()
        }
        dataSource.append(WYMultilevelTable(superLevel: 0, level: 0))

        return tableview
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        navigationItem.title = "无限层折叠TableView"
        tableView.backgroundColor = .white
    }
    
    func expand(model: WYMultilevelTable, indexPath: IndexPath) {

        var reloadRows: [IndexPath] = []
        let insertLocation: Int = indexPath.row + 1
        let subLevel: Int = randomNumber()
        model.subLevel = subLevel
        for index in 0..<subLevel {

            let insertModel = WYMultilevelTable(superLevel: model.level, level: model.level+1)
            dataSource.insert(insertModel, at: insertLocation + Int(index))
            reloadRows.append(IndexPath(row: insertLocation + Int(index), section: 0))
        }

        tableView.beginUpdates()
        tableView.insertRows(at: reloadRows, with: .automatic)
        tableView.endUpdates()

        tableView.reloadRows(at: reloadRows, with: .none)
    }

    func fold(model: WYMultilevelTable, indexPath: IndexPath) {

        var reloadRows: [IndexPath] = []
        var length: Int = 0
        let location: Int = indexPath.row + 1
        for index in 0..<dataSource.count - location {
            let multilevelModel = dataSource[location + index]
            if multilevelModel.level > model.level {
                reloadRows.append(IndexPath(row: location + index, section: indexPath.section))
                length += 1
            }else{
                break
            }
        }
        dataSource.removeSubrange(Range(NSRange(location: location, length: length))!)
        tableView.beginUpdates()
        tableView.deleteRows(at: reloadRows, with: .automatic)
        tableView.endUpdates()

        tableView.reloadSections(IndexSet(integer: indexPath.section), with: .none)
    }

    func sharedLevelName(model: WYMultilevelTable) -> String {

        var offset: String = ""
        for _ in 0..<model.level {
            offset = offset + "    "
        }
        return offset + "第\(model.level)级"
    }

    func randomNumber(min: Int = 1, max: Int = 5) -> Int {
        return min + Int(arc4random_uniform(UInt32(max - min)))
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

extension WYMultilevelTableViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        
        cell.textLabel?.textColor = UIColor.wy_dynamic(.black, .white)
        cell.textLabel?.font = .systemFont(ofSize: wy_fontSize(15, WYBasisKitConfig.defaultScreenPixels))
        cell.textLabel?.text = sharedLevelName(model: dataSource[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        let model = dataSource[indexPath.row]
        model.expand = !model.expand
        if model.expand == true {
            expand(model: model, indexPath: indexPath)
        }else {
            fold(model: model, indexPath: indexPath)
        }
    }
}

class WYMultilevelTable: NSObject {
    
    /// 当前所属父层级
    private(set) var superLevel: Int = 0
    /// 当前所属层级
    private(set) var level: Int = 0
    /// 当前所属层级下的子层级数量
    var subLevel: Int = 0
    /// 当前层级是展开还是折叠状态
    var expand: Bool = false
    /// 当前层级名
    var levelName: String = ""
    /// 推荐初始化方法
    init(superLevel: Int, level: Int, subLevel: Int = 0) {
        self.subLevel = superLevel
        self.level = level
        self.subLevel = subLevel
    }
}
