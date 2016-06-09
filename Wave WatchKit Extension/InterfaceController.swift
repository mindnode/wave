//
//  InterfaceController.swift
//  Wave WatchKit Extension
//
//  Created by John Lee on 2016. 3. 8..
//  Copyright © 2016년 MassiveDynamics. All rights reserved.
//

import WatchKit
import Foundation
import Alamofire


class InterfaceController: WKInterfaceController,CLLocationManagerDelegate {

	enum WAVE_DIRECTION : Int{
		case UP = 1,DOWN = 0
	}

	let locationManager = CLLocationManager()
	
	@IBOutlet var weather: WKInterfaceTable!
	@IBOutlet var map: WKInterfaceMap!
	@IBOutlet var remain_time: WKInterfaceLabel!
	@IBOutlet var region: WKInterfaceLabel!
	@IBOutlet var messages: WKInterfaceLabel!
	@IBOutlet var btn_reload: WKInterfaceButton!
	@IBOutlet var panel_indicator: WKInterfaceGroup!
	@IBOutlet var canvas: WKInterfaceGroup!
	
    override func awakeWithContext(context: AnyObject?) {
        super.awakeWithContext(context)
    }
	
	@IBAction func onBtnReloadTouched() {
		// reload entire canvas
		updateCurrentLocation()
		
		WKInterfaceDevice.currentDevice().playHaptic(WKHapticType.Start)

//		let wave_level = Int(arc4random_uniform(100))
//		drawScreen(wave_level,direction: WAVE_DIRECTION.DOWN)
	}
	
	override func didAppear() {

		//////////////////////////////
		// create background bitmap
		//////////////////////////////
		//getCurrentLocation()
		drawScreen(25, direction: WAVE_DIRECTION.UP,min: 0,max: 0,remain: "00:00")
		
		NSTimer.scheduledTimerWithTimeInterval(600, target: self, selector: #selector(InterfaceController.updateCurrentLocation), userInfo: nil, repeats: true)
		
		updateMap(CLLocationCoordinate2DMake(37.548, 126.993),current_location: CLLocationCoordinate2DMake(37, 125))
		updateWeather(7)
	}
	
	func updateWeather(count : Int){
		weather.setNumberOfRows(count, withRowType: "WeatherRowController")
	}
	
	func updateMap(target_location : CLLocationCoordinate2D, current_location : CLLocationCoordinate2D){
		
		let coordination_span : MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
		map.removeAllAnnotations()
		map.addAnnotation(target_location, withPinColor: .Red)
		map.addAnnotation(current_location, withPinColor: .Green)
		map.setRegion(MKCoordinateRegion(center : target_location, span: coordination_span))
	}

	func updateCurrentLocation()/* -> CLLocation*/{
		

		if CLLocationManager.locationServicesEnabled() {
			print("Location service : enabled.")
			locationManager.delegate = self
			locationManager.desiredAccuracy = kCLLocationAccuracyBest
			locationManager.requestAlwaysAuthorization()
//			locationManager.requestWhenInUseAuthorization()
			locationManager.requestLocation()
			self.messages.setText("updating...")
			
		}else{
			print("Location service : disabled.")
		}

	}
	
	
	func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
		print("Authorization status changed: \(status)")
	}
	
	func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
	
		if locations.count > 0 {
			if let location = locations[0] as? CLLocation{

				self.messages.setText("getting GPS.")

				print("User location has been updated successfully.")
				print("alt = \(location.altitude) , lat = \(location.coordinate.latitude) , long = \(location.coordinate.longitude)")
				
				let extreme_start_time = Int(NSDate().timeIntervalSince1970 - 60*60*6)
				print("extreme tide startdate =\(extreme_start_time)")
				let tide_extreme_url = TideProvider.getTideExtremeAPI(location.coordinate.latitude, lon: location.coordinate.longitude,time: extreme_start_time)
//				let tide_extreme_url = TideProvider.getTideExtremeAPI(37.300, lon: 126.321,time: extreme_start_time)
				let weather_url = "http://api.openweathermap.org/data/2.5/forecast?lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)&appid=8d15d804092e849eb207d30bce69b0f4"
				
				Alamofire.request(.GET, weather_url)
					.responseJSON{ response in
						self.messages.setText("getting weather")
						
						let values = response.result.value!["list"]
						
						var i = 0
						for v : NSDictionary in values as! Array{
							if i > 6 {
								break
							}
							let dt = NSDate(timeIntervalSince1970: v["dt"] as! Double + 60*60*9)
							let title = String(v["weather"]![0]["description"])
							
							let temp = (v["main"]!["temp"] as! Double - 273.15) // kelvin to celcius
							print("\(dt) wheater = \(title) , temp = \(temp) , wind = \(v["wind"]!["speed"]) , wind_degree = \(v["wind"]!["deg"])")
							
							let row = self.weather.rowControllerAtIndex(i) as! WeatherRowController
							
							let df = NSDateFormatter()
							df.dateFromString("MM-DD HH:mm")
							let time = df.stringFromDate(dt)
							
//							row.title.setText(title)
							row.time.setText(time)
							row.temperature.setText(String(format: "%02.1f", temp))
							i+=1
						}
				}
				
				
				Alamofire.request(.GET, tide_extreme_url)
					.responseJSON{ response in

						self.messages.setText("getting tide")
						
						let values = response.result.value!["extremes"]

						var extreme_before : Double = 0
						var extreme_after : Double = 0
						
						var min_height : Double = 0
						var max_height : Double = 0
						
						var min_dt : Double = 0
						var max_dt : Double = 0
						
						var i = 0

						for v : NSDictionary in values as! Array{
							
							let dt = v["dt"] as! Double
							let date = NSDate(timeIntervalSince1970: dt + 60*60*9)
							
							print("[\(i)]---------------------------")
							print("ko_date= \(date)\n")
							
							print("date   = \(v["date"])")
							print("dt     = \(v["dt"])")
							print("height = \(v["height"])")
							print("type   = \(v["type"])")
							
							if Int(dt) < Int(NSDate().timeIntervalSince1970) {
								extreme_before = v["height"] as! Double
							}
							if Int(dt) > Int(NSDate().timeIntervalSince1970) {
								extreme_after = v["height"] as! Double
							}
							
							if v["type"] as! String == "Low" {
								min_height = v["height"] as! Double
								min_dt = v["dt"] as! Double
							}
							
							if v["type"] as! String == "High" {
								max_height = v["height"] as! Double
								max_dt = v["dt"] as! Double
							}
							
							
							if i > 0 {
								break;
							}
							

							let realLocation : CLLocation = CLLocation(
								latitude: CLLocationDegrees(response.result.value!["responseLat"] as! Double),
								longitude: CLLocationDegrees(response.result.value!["responseLon"] as! Double)
								)
							
							self.updateMap(
								CLLocationCoordinate2DMake(realLocation.coordinate.latitude, realLocation.coordinate.longitude),
								current_location: CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude)
							)
							
							CLGeocoder().reverseGeocodeLocation(realLocation, completionHandler:
								{(placemarks,error) -> Void in
									
									print("GEOCODER")
									if (error != nil) {
										print("error reverseGeocode : \(error?.localizedDescription)")
										return
									}
									
									if placemarks!.count > 0 {
//										print("placename = %s", placemarks![0] as CLPlacemark)
										self.region.setText(placemarks![0].name)
									}else{
										print("Problem with the data received from geocoder")
									}
							})
						}
						

						let wave_diff = abs(extreme_before) + abs(extreme_after)
						print("wave_diff = \(wave_diff)")
						
						let now = Int(NSDate().timeIntervalSince1970)
						let tide_height_url = TideProvider.getTideHeightAPI(location.coordinate.latitude, lon: location.coordinate.longitude,time: now)
//						let tide_height_url = TideProvider.getTideHeightAPI(37.300, lon: 126.321,time: now)
						
						i = 0
						Alamofire.request(.GET, tide_height_url)
							.responseJSON{ response in

								self.messages.setText("current tide...")
								let values = response.result.value!["heights"]
								let current_height = values!![0]["height"] as! Double
//
//								for v : NSDictionary in values as! Array{
//									
//									let dt = v["dt"] as! Double
//									let date = NSDate(timeIntervalSince1970: dt + 60*60*9)
//									
//									print("[\(i)]---------------------------")
//									print("ko_date= \(date)\n")
//									
//									print("date   = \(v["date"])")
//									print("dt     = \(v["dt"])")
//									print("height = \(v["height"])")
//									
//								}
								let rate = (abs(min_height) + current_height) / (abs(min_height) + abs(max_height))
								
								let direction : WAVE_DIRECTION = extreme_before < extreme_after
									? WAVE_DIRECTION.UP : WAVE_DIRECTION.DOWN
								
								var remain_dt : Double = 0
								
								switch direction {
									
									case WAVE_DIRECTION.DOWN :
										remain_dt = min_dt - NSDate().timeIntervalSince1970
										break
									case WAVE_DIRECTION.UP :
										remain_dt = max_dt - NSDate().timeIntervalSince1970
										break
								}
								
								let remain_time_hour = remain_dt / 3600
								let remain_time_minute = (remain_dt % 3600) / 60
								
								let remain_str = "\(String(format: "%02d",Int(remain_time_hour))):\(String(format: "%02d",Int(remain_time_minute)))"
								
								self.drawScreen(Int(rate*100),direction: direction,min: min_height,max: max_height,remain : remain_str)
								
								print("curr = \(current_height)")
								print(" min = \(min_height)")
								print(" max = \(max_height)")
								print("rate = \(rate*100)%")
								
								
								self.messages.setText(String(format: "%.2fm", current_height))

								WKInterfaceDevice.currentDevice().playHaptic(WKHapticType.Notification)
						}

				}
			}
		}
	}
	
	func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
		print("error in #locationManager : \(error)")
	
		self.messages.setText("Where am I?(retry)")
		WKInterfaceDevice.currentDevice().playHaptic(WKHapticType.Failure)
	}
	
	func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
		print("didUpdateToLocation")
	}
	

	//////////////////////////////////////////////////
	// indicator height : 280
	// wave y pos range : max : -30 ~ min : -310
	//////////////////////////////////////////////////
	
	func drawScreen(waveHeight : Int ,direction : WAVE_DIRECTION, min : Double, max : Double, remain : String) {
		
		
		var size = CGSizeMake(272,370)
		var tideHeight : CGFloat = 0
		
		remain_time.setText(remain)
		
		//		let image_background = UIImage(contentsOfFile: "")
		let image_background = UIImage.init(named: "background.png")
		let image_wave       = UIImage.init(named: "wave.png")
		let image_indicator  = UIImage.init(named: "indicator.png")

		let image_direction = (direction == WAVE_DIRECTION.UP) ?
			UIImage.init(named: "direction_up.png") : UIImage.init(named: "direction_down.png")
		
		//		let image_sun = UIImage.init(named: "sun.png")
		//		let image_reload = UIImage.init(named: "reload.png")
		//		let image_alert = UIImage.init(named: "alert.png")
		
		tideHeight = CGFloat(-(Int(image_indicator!.size.height)*(100-waveHeight)/100)) - 20

		UIGraphicsBeginImageContext(size)
		var context = UIGraphicsGetCurrentContext()
		
		//		CGContextDrawImage(context, CGRectMake(0,100,272,340),image_background?.CGImage)
		let rect_background = CGRectMake(0, 0, image_background!.size.width, image_background!.size.height);
		let rect_wave		= CGRectMake(0, tideHeight, image_wave!.size.width, image_wave!.size.height);
		let rect_direction	= CGRectMake(18,340 + tideHeight ,16,16);
		
		//		let rect_sun		= CGRectMake(140, 40, image_sun!.size.width, image_sun!.size.height);
		//		let rect_reload		= CGRectMake(180, 220, image_reload!.size.width, image_reload!.size.height);
		//		let rect_alert		= CGRectMake(180, 220, image_alert!.size.width, image_alert!.size.height);
		

		CGContextTranslateCTM(context, 0, 340);
		
		//		CGContextTranslateCTM(context, 0, image_indicator!.size.height);
		//		CGContextTranslateCTM(context, 0, image_wave!.size.height);
		
		CGContextScaleCTM(context, 1.0, -1.0);
		CGContextDrawImage(context, rect_background, image_background!.CGImage);
		CGContextDrawImage(context, rect_wave, image_wave!.CGImage);
		CGContextDrawImage(context, rect_direction, image_direction!.CGImage);
		
		//		CGContextDrawImage(context, rect_indicator, image_indicator!.CGImage);
		//		CGContextDrawImage(context, rect_sun, image_sun!.CGImage);
		//		CGContextDrawImage(context, rect_reload, image_reload!.CGImage);
		//		CGContextDrawImage(context, rect_alert, image_alert!.CGImage);
		//		CGContextTranslateCTM(context, 0, image_background!.size.height);
		
		// Convert to UIImage
		var cgimage = CGBitmapContextCreateImage(context);
		var uiimage = UIImage(CGImage: cgimage!)

		
		// End the graphics context
		UIGraphicsEndImageContext()
		
		// Show on WKInterfaceImage
		canvas.setBackgroundImage(uiimage)
		
		
		//////////////////////////////////////////
		// Draw indicator
		//////////////////////////////////////////
		
		
		size = CGSizeMake(120,370)
		
		UIGraphicsBeginImageContext(size)
		context = UIGraphicsGetCurrentContext()

		//////////////////////////////////////////
		// Draw MIN/MAX height
		// Setup the font specific variables
		let textColor: UIColor = UIColor.whiteColor()
		let textFont: UIFont = UIFont(name: "Helvetica Bold", size: 20)!
		
		let textFontAttributes = [
			NSFontAttributeName: textFont,
			NSForegroundColorAttributeName: textColor,
		]
		
		NSString(string: String(format: "%.2f", max)).drawAtPoint(CGPoint(x:70,y: 40), withAttributes: textFontAttributes)
		NSString(string: String(format: "%.2f", min)).drawAtPoint(CGPoint(x:70,y:image_indicator!.size.height + 24),withAttributes: textFontAttributes)
		//////////////////////////////////////////

		
		let rect_indicator  = CGRectMake(15, 2, image_indicator!.size.width, image_indicator!.size.height);
		CGContextTranslateCTM(context, 0, 340);
		CGContextScaleCTM(context, 1.0, -1.0);
		CGContextDrawImage(context, rect_indicator, image_indicator!.CGImage);

		
		cgimage = CGBitmapContextCreateImage(context);
		uiimage = UIImage(CGImage: cgimage!)
		
		// End the graphics context
		UIGraphicsEndImageContext()
		
		// Show on WKInterfaceImage
		panel_indicator.setBackgroundImage(uiimage)
		
		
		
	}
	
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()

//
//		let tideProvider = TideProvider()
//		let tideURL = tideProvider.getHeightAPIRequest(37.444917, longitude: 127.138868)
//		
//		print(tideURL)
//		Alamofire.request(.GET, tideURL)
//			.responseJSON{ response in
//				print(response.data)
//				
//				if let JSON = response.result.value{
//					print("JSON : \(JSON)")
//				}
//		}

		
		
//
//		let image_buffer = UIImage(named: "wave_background")
//
//		canvas.setImage(image_buffer)
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

}
