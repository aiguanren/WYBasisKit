//
//  WYTestView.swift
//  WYBasisKit
//
//  Created by 官人 on 2020/12/10.
//  Copyright © 2020 官人. All rights reserved.
//

import UIKit

class WYTestView: UIView {
    
    var result: Int = 0
    
    convenience init(_ result: Int) {
        
        self.init()
        self.result = result
    }
    
    @discardableResult
    func add(num: Int) -> WYTestView {
        
        result += num
        
        return self
    }
    
    @discardableResult
    func subtract(num: Int) -> WYTestView {
        
        result -= num
        
        return self
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

extension WYTestView {
    
    public static func sequencing(testView: (WYTestView) -> Void) -> Int {

        let test = WYTestView()
        testView(test)
        
        return test.result
    }
}
