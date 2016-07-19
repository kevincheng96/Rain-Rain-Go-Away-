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
    let uuid: String = UIDevice.currentDevice().identifierForVendor!.UUIDString // user iPhone's UUID

    
    @IBOutlet var hourSlider: UISlider!
    @IBOutlet var notificationSwitch: UISwitch!
    
    @IBAction func hourSliderValueChange(sender: UISlider) {
        currentSliderValue = Int(sender.value)
        defaults.setInteger(currentSliderValue, forKey: "hoursBeforeNotification")
        defaults.synchronize()
        hourLabel.text = "\(currentSliderValue) hours"
    }
    
    @IBOutlet var hourLabel: UILabel!
    
    @IBAction func notificationSwitchPressed(sender: AnyObject) {
        // using an UNSAFE method right now
        // read http://stackoverflow.com/questions/31254725/transport-security-has-blocked-a-cleartext-http
        // to make changes later on!
        //            let url_string = String(urlLabel.text!) + "/updateDeviceLocation"
        let url_string = String("http://rain-rain-go-away.herokuapp.com/api/notificationSwitch")
        let url = NSURL(string: url_string)
        let request = NSMutableURLRequest(URL: url!)
        request.HTTPMethod = "POST"
        
        if notificationSwitch.on {
            let data = ("deviceID=" + uuid + "&receiveNotification=true").dataUsingEncoding(NSUTF8StringEncoding)
            let task = NSURLSession.sharedSession().uploadTaskWithRequest(request, fromData: data!)
            task.resume()
            defaults.setBool(notificationSwitch.on, forKey: "notificationSwitchState")
            defaults.synchronize()
            print("Notification switched on!")
        } else {
            let data = ("deviceID=" + uuid + "&receiveNotification=false").dataUsingEncoding(NSUTF8StringEncoding)
            let task = NSURLSession.sharedSession().uploadTaskWithRequest(request, fromData: data!)
            task.resume()
            defaults.setBool(notificationSwitch.on, forKey: "notificationSwitchState")
            defaults.synchronize()
            print("Notification switched off!")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        currentSliderValue = defaults.integerForKey("hoursBeforeNotification")
        notificationSwitch.on = defaults.boolForKey("notificationSwitchState")
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
