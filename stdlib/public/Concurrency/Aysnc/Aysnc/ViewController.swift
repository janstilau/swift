//
//  ViewController.swift
//  Aysnc
//
//  Created by liuguoqiang on 2024/3/16.
//

import Cocoa

func sayNothing() async {
    NSLog("sayNothing")
}

func saySth() async {
    NSLog("saySth Begin")
    await sayNothing()
    NSLog("saySth End")
}

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        Task(priority: .high) {
            await saySth()
        }
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

