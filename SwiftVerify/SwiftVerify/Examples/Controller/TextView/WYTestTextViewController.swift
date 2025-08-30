//
//  WYTestTextViewController.swift
//  SwiftVerify
//
//  Created by guanren on 2025/8/26.
//

import UIKit

class WYTestTextViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet weak var textView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let attributedText: NSMutableAttributedString = NSMutableAttributedString(string: "占位文本占位文本占位文本占位文本占位文本占位文本占位文本占位文本占位文本")
        attributedText.wy_lineSpacing(lineSpacing: 5)
        textView.wy_placeholderLabel.attributedText = attributedText
        textView.textContainerInset = UIEdgeInsets(top: UIDevice.wy_screenWidth(5), left: UIDevice.wy_screenWidth(10), bottom: UIDevice.wy_screenWidth(5), right: UIDevice.wy_screenWidth(10))
        textView.wy_allowCopyPaste = true
        textView.delegate = self
    }
    
    func textViewDidChange(_ textView: UITextView) {
        
        let maximumLimit: Int = 0
        
        textView.wy_maximumLimit(maximumLimit)
        
        let contentText: String = textView.text ?? ""
        
        WYLogManager.output("contentText = \(contentText)")
        
        if contentText.count == maximumLimit && maximumLimit > 0 {
            self.textView.textContainerInset = UIEdgeInsets(top: UIDevice.wy_screenWidth(5), left: UIDevice.wy_screenWidth(50), bottom: UIDevice.wy_screenWidth(5), right: UIDevice.wy_screenWidth(10))
        }else {
            self.textView.textContainerInset = UIEdgeInsets(top: UIDevice.wy_screenWidth(5), left: UIDevice.wy_screenWidth(10), bottom: UIDevice.wy_screenWidth(5), right: UIDevice.wy_screenWidth(10))
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
