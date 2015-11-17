//
//  SettingsViewController.swift
//  Rain rain go away!
//
//  Created by Kevin Cheng on 8/14/15.
//  Copyright (c) 2015 Kevin Cheng. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {
    
    var currentSliderValue: Int!
    let defaults = NSUserDefaults.standardUserDefaults() //defaults is used to store the settings data
    
    @IBOutlet var hourSlider: UISlider!
    
    @IBAction func hourSliderValueChange(sender: UISlider) {
        currentSliderValue = Int(sender.value)
        defaults.setInteger(currentSliderValue, forKey: "hoursBeforeNotification")
        defaults.synchronize()
        hourLabel.text = "\(currentSliderValue) hours"
    }
    
    @IBOutlet var hourLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentSliderValue = defaults.integerForKey("hoursBeforeNotification")
        hourSlider.setValue(Float(currentSliderValue), animated: true)
        hourLabel.text = "\(currentSliderValue) hours"

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    
    /* override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let destinationVC = segue.destinationViewController as ViewController
        destinationVC.hoursBeforeNotification = currentSliderValue
    } */
}
