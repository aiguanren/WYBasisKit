//
//  WYTableViewPlainController.swift
//  WYBasisKit
//
//  Created by 官人 on 2021/7/4.
//  Copyright © 2021 官人. All rights reserved.
//

import UIKit

class WYTableViewPlainController: UIViewController {
    
    lazy var tableView: UITableView = {

        let tableview = UITableView.wy_shared(style: .plain, separatorStyle: .singleLine, delegate: self, dataSource: self, superView: view)
        tableview.wy_register(UITableViewCell.self, .cell)
        tableview.wy_register([WYTestTableViewHeaderView.self, WYTestTableViewFooterView.self], [.headerFooterView, .headerFooterView])
        tableview.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(wy_navViewHeight)
            make.left.right.bottom.equalToSuperview()
        }
        return tableview
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.backgroundColor = .orange
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

extension WYTableViewPlainController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView: WYTestTableViewHeaderView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "WYTestTableViewHeaderView") as! WYTestTableViewHeaderView
        headerView.titleView.text = "header section = \(section)"
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        let footerView: WYTestTableViewFooterView = tableView.dequeueReusableHeaderFooterView(withIdentifier: "WYTestTableViewFooterView") as! WYTestTableViewFooterView
        footerView.titleView.text = "footer section = \(section)"
        
        return footerView
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        
        cell.textLabel?.text = "section = \(indexPath.section)  row = \(indexPath.row)"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 30
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 30
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return 50
    }
}
