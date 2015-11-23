//
//  ViewController.swift
//  Rain rain go away!
//
//  Created by Kevin Cheng on 7/30/15.
//  Copyright (c) 2015 Kevin Cheng. All rights reserved.
//

// ** IMPORTANT ** NEED TO MAKE SURE THE APP WORKS IN BACKGROUND, CAN SEND NOTIFICATIONS IN BACKGROUND
// ** LOCATION IS NOT BEING UPDATED WHEN APP FIRST OPENS

import UIKit
import CoreLocation
import Foundation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    let defaults = NSUserDefaults.standardUserDefaults() //defaults is used to store the settings data
    let locationManager = CLLocationManager()
    private let apiKey = "1870bc9557b627988da5a8c5e0afb6cb"
    var userLocation: CLLocation! = nil
    var userLatitude: Double! //use var or let?
    var userLongitude: Double!
    var hourlyWeatherArray: [(weather: String?, time: Double?)] = [] // (weather, time)
    var hourlyRainArray: [(weather: String?, time: Double?)] = [] //filtered hourlyWeatherArray
    var secondsUntilNextRain: Double? //number of seconds until next rain
    var hoursUntilNextRain: Int? //hours until next rain
    var hoursBeforeNotification: Int! = 6 //hours prior to rain to notify user
    var hoursUntilNotification: Int? = nil
    
    @IBOutlet var weatherDisplay: UITextView!
    
    @IBOutlet var statusDisplay: UITextView!

    @IBOutlet var hourDisplay: UITextView!
    
    @IBAction func grabLocationAndWeather(sender: AnyObject)
        // ** Do we even need a button? can put this in viewDidLoad() when app starts up
    {
        /*userLocation = locationManager.location
        updateLocationAndWeather() */
        statusDisplay.text = "Please wait as we update your location"
        userLocation = nil
        locationManager.startUpdatingLocation()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
         // Do any additional setup after loading the view, typically from a nib.

        //Requests location services
        locationManager.requestAlwaysAuthorization()
        
        /* let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(4 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()){} */
        
        hoursBeforeNotification = defaults.integerForKey("hoursBeforeNotification")
        
        if CLLocationManager.locationServicesEnabled()
        {
            self.locationManager.delegate = self
            self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            self.locationManager.distanceFilter = 7500 //travel 7500 meters for location to update
            self.locationManager.startUpdatingLocation()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //calls weather API and updates UI when location is updated
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if let location = locations.last as? CLLocation //TRY FIXING THIS SO IT DOESNT CONTNUOUSLY UPDATE
        {
            if userLocation == nil {
                userLocation = location
                updateLocationAndWeather()
            }
            else
            {
                updateLocationAndWeather()
            }
        }
    }
    
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        locationManager.stopUpdatingLocation()
        statusDisplay.text = error.description
    }
    
    //retrieves user location, then calls getWeatherData() to retrieve data from weather API
    func updateLocationAndWeather() -> Void
    {
        if CLLocationManager.locationServicesEnabled()
        {
            statusDisplay.text = "Location obtained. Retrieving weather data..."
        }
        else
        {
            statusDisplay.text = "Location services is currently disabled"
        }
        
        //if userLocation is not nil, call getWeatherData() of current location
        if let location = userLocation
        {
            var userCoordinates = location.coordinate
            userLatitude = userCoordinates.latitude
            userLongitude = -(userCoordinates.longitude) //api uses opposite longitude coordinate
            getWeatherData()
        }
        else
        {
            weatherDisplay.text = "Could not retrieve user location"
            
            //refresh coordinates again
            locationManager.stopUpdatingLocation()
            locationManager.startUpdatingLocation()
        }
    }

    //requests weather of user location using weather API, then updates UI
    func getWeatherData() -> Void
    {
        let urlPath = "https://api.forecast.io/forecast/\(apiKey)/\(userLatitude),\(userLongitude)"
        let url = NSURL(string: urlPath)
        
        let sharedSession = NSURLSession.sharedSession()
        let dataTask: NSURLSessionDataTask = sharedSession.dataTaskWithURL(url!, completionHandler: {(data, response, error) -> Void in
            if (error == nil)
            {
                let weatherDictionary: NSDictionary = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil) as NSDictionary
                
                //parse (weather, time) to hourlyWeatherArray
                if let hourlyDataBlock = weatherDictionary["hourly"] as? NSDictionary
                {
                    if let dataArray = hourlyDataBlock["data"] as? NSArray
                    {
                        for hour in dataArray //loop through data for each hour
                        {
                            var hourlyData = hour as? NSDictionary
                            var weatherIcon = hour["icon"] as? String
                            var weatherHour = hour["time"] as? Double
                            var weatherTuple = (weatherIcon, weatherHour)
                            self.hourlyWeatherArray += [weatherTuple]
                            // ** MIGHT BE RE-LOOPING THIS, SINCE ARRAY KEEPS GROWING
                        }
                    }
                }
                
                //filter out hourly weather data that is not rain
                self.hourlyRainArray = self.hourlyWeatherArray.filter({$0.weather == "rain" || $0.weather == "thunderstorm"}) //need to change to "rain"
                
                //checks if there is rain in the next hours (if hourlyRainArray is not empty)
                if self.hourlyRainArray.isEmpty == false
                {
                    let currentUnixTime = NSDate().timeIntervalSince1970
                    for hour in self.hourlyRainArray
                    {
                        //finds the next rain hour that is in the future (in case API forecast is not updated)
                        var nextHour = hour.time
                        if hour.time > currentUnixTime
                        {
                            self.secondsUntilNextRain = (nextHour! - currentUnixTime) / 3600 //hours until rain
                            self.hoursUntilNextRain = Int(round(self.secondsUntilNextRain!))
                            break
                        }
                    }
                }
                else
                {
                    self.hoursUntilNextRain = nil
                }
                
                if self.hoursBeforeNotification <= self.hoursUntilNextRain
                {
                    self.sendNotification()
                }
             
            
                //updates UI in the main thread
                dispatch_async(dispatch_get_main_queue(), {() -> Void in
                    self.weatherDisplay.text = "\(weatherDictionary)"
                    
                    if self.hoursUntilNextRain == nil
                    {
                        self.hourDisplay.font = self.hourDisplay.font.fontWithSize(42)
                        self.hourDisplay.text = ">48"
                        self.statusDisplay.text = "No rain in the next two days"
                    }
                    else if self.hoursUntilNextRain < 1
                    {
                        self.hourDisplay.font = self.hourDisplay.font.fontWithSize(58)
                        self.hourDisplay.text = "<1"
                        self.statusDisplay.text = "You will be notified in \(self.hoursUntilNotification!) hours to bring your umbrella!"
                    }
                    else
                    {
                        self.hourDisplay.font = self.hourDisplay.font.fontWithSize(58)
                        self.hourDisplay.text = "\(self.hoursUntilNextRain!)"
                        self.statusDisplay.text = "You will be notified in \(self.hoursUntilNotification!) hours to bring your umbrella!"
                    }
                    
                    if ((self.hoursBeforeNotification > self.hoursUntilNextRain) && self.hoursUntilNextRain != nil)
                    {
                        self.statusDisplay.text = "No local notification set because your hours before notification is greater than the time until next rain. Please adjust your value in the settings page"
                    }
                })
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), {() -> Void in
                    self.weatherDisplay.text = "Could not retrieve weather data \u{2639}"
                    self.statusDisplay.text = "Could not retrieve weather data \u{2639}"
                })
            }
        })
        dataTask.resume()
    }
    
   func sendNotification()
    {
        var Notification = UILocalNotification()
        if let hourTillRain = hoursUntilNextRain
        {
            UIApplication.sharedApplication().cancelAllLocalNotifications() //cancel all pre-existing notifications so only one is sent
            hoursUntilNotification = hoursUntilNextRain! - hoursBeforeNotification
            let notificationTime = hoursUntilNotification! * 3600
            Notification.fireDate = NSDate(timeIntervalSinceNow: Double(notificationTime) + 5)
            Notification.alertBody = "Bring an umbrella, it's going to rain in \(hoursBeforeNotification!) hours!"
            Notification.applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + 1
            // ** ALSO NEEDS TO MAKE SURE NOTIFICATION WILL BE SENT EVEN IF IT IS RAINING RIGHT NOW OR SOON, REGARDLESS OF THE hoursBeforeNotification
            UIApplication.sharedApplication().scheduleLocalNotification(Notification)
        }
    }
}

