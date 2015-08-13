//
//  ViewController.swift
//  Rain rain go away!
//
//  Created by Kevin Cheng on 7/30/15.
//  Copyright (c) 2015 Kevin Cheng. All rights reserved.
//

// ** STILL NEED TO FIX BUG WHERE GRABBING LOCATION IS NIL THE FIRST TIME USING APP
// ** FIX UP UI LAYOUT SIZE
// ** ADD SETTINGS PAGE WHERE USER CAN SET HOW EARLY HE WANTS TO BE NOTIFIED
// ** IMPORTANT ** NEED TO MAKE SURE THE APP WORKS IN BACKGROUND, CAN SEND NOTIFICATIONS IN BACKGROUND

import UIKit
import CoreLocation
import Foundation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    private let apiKey = "1870bc9557b627988da5a8c5e0afb6cb"
    var userLocation: CLLocation!
    var userLatitude: Double! //use var or let?
    var userLongitude: Double!
    var hourlyWeatherArray: [(weather: String?, time: Double?)] = [] // (weather, time)
    var hourlyRainArray: [(weather: String?, time: Double?)] = [] //filtered hourlyWeatherArray
    var timeUntilNextRain: Double? //number of seconds until next rain (can be converted to minutes/hours)
    
    @IBOutlet var weatherDisplay: UITextView!
    
    @IBOutlet var locationDisplay: UITextView!
    
    //grabs location, then grabs weather of that location
    @IBAction func grabLocationAndWeather(sender: AnyObject)
        // ** Do we even need a button? can put this in viewDidLoad() when app starts up
    {
        userLocation = locationManager.location
        if CLLocationManager.locationServicesEnabled()
        {
            locationDisplay.text = "\(userLocation)"
        }
        else
        {
            locationDisplay.text = "Location services is currently disabled"
        }
        
        //if userLocation is not nil, call getWeatherData() of current location
        if let location = userLocation
        {
            var userCoordinates = location.coordinate
            userLatitude = userCoordinates.latitude
            userLongitude = userCoordinates.longitude * -1 //api uses opposite longitude coordinate
            getWeatherData()
        }
        else
        {
            weatherDisplay.text = "Could not retrieve weather data"
            
            //refresh coordinates again
            locationManager.stopUpdatingLocation()
            locationManager.startUpdatingLocation()
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
         // Do any additional setup after loading the view, typically from a nib.

        //Requests location services
        locationManager.requestAlwaysAuthorization()
        if CLLocationManager.locationServicesEnabled()
        {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
                        }
                    }
                }
                
                //filter out hourly weather data that is not rain
                self.hourlyRainArray = self.hourlyWeatherArray.filter({$0.weather == "clear-day"}) //need to change to "rain"
                
                //finds the next rain hour that is in the future (in case API forecast is not updated)
                let currentUnixTime = NSDate().timeIntervalSince1970
                for hour in self.hourlyRainArray
                {
                    var nextHour = hour.time
                    if hour.time > currentUnixTime
                    {
                        self.timeUntilNextRain = (nextHour! - currentUnixTime) / 3600 //hours until rain
                        break
                    }
                }
                
                self.sendNotification()
                
                //updates UI in the main thread
                dispatch_async(dispatch_get_main_queue(), {() -> Void in
                    self.weatherDisplay.text = "\(self.timeUntilNextRain!) hours until next rain"
                })
            }
            else
            {
                dispatch_async(dispatch_get_main_queue(), {() -> Void in
                    self.weatherDisplay.text = "Could not retrieve weather data \u{2639}"
                })
            }
        })
        dataTask.resume()
    }
    
   func sendNotification()
    {
        var Notification = UILocalNotification()
        Notification.alertBody = "Bring an umbrella, it's going to rain in \(timeUntilNextRain!) hours!"
        Notification.applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + 1
        Notification.fireDate = NSDate(timeIntervalSinceNow: 10) //need to fire some hours before it rains
        
        UIApplication.sharedApplication().scheduleLocalNotification(Notification)
    }
}

