//
//  ViewController.swift
//  TouchIdDeamSwift
//
//  Created by zengbailiang on 2018/5/12.
//  Copyright © 2018年 zengbailiang. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    @IBAction func touchIdAction(_ sender: Any) {
        if TouchIdManager.touchIdInfoDidChange() {
            let alert:UIAlertController =  UIAlertController.init(title: "tips", message: "fingerprint changed", preferredStyle: UIAlertControllerStyle.alert)
            let alertAction = UIAlertAction.init(title: "cannel", style: UIAlertActionStyle.cancel) { (kAlertAction) in
                
            }
            alert.addAction(alertAction)
            self.present(alert, animated: true, completion: nil)
        }
        else
        {
            TouchIdManager.showTouchId(title: "touch id test", fallbackTitle: "fallback", fallbackBlock: {
                
            }) { (ableUse, success, error) in
                var msg = ""
                if ableUse == false
                {
                    msg = "fingerprint  unable"
                }
                else if success
                {
                    msg = "fingerprint success"
                }
                else
                {
                    msg = "fingerprint failed"
                }
                
                let alert:UIAlertController =  UIAlertController.init(title: "tips", message: msg, preferredStyle: UIAlertControllerStyle.alert)
                let alertAction = UIAlertAction.init(title: "cannel", style: UIAlertActionStyle.cancel) { (kAlertAction) in
                    
                }
                alert.addAction(alertAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

