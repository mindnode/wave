//
//  TideProvider.swift
//  Wave
//
//  Created by John Lee on 2016. 3. 8..
//  Copyright © 2016년 MassiveDynamics. All rights reserved.
//

import Foundation
import Alamofire

class TideProvider {
	
	static let API_KEY = "160772c2-f3e7-4ec6-bf24-c4fad75ce97c"
	static let API_URL = "https://www.worldtides.info/api"
	
	static func getTideHeightAPI(lat : Double,lon: Double) -> String{
		
		let url = "\(API_URL)?heights&lat=\(lat)&lon=\(lon)&length=\(60*60*12)&key=\(API_KEY)"
		print(url)
		return url
	}

	static func getTideHeightAPI(lat : Double,lon: Double, time : Int) -> String{
		
		let url = TideProvider.getTideHeightAPI(lat, lon: lon) + "&start=\(time)"
		print(url)
		return url
	}
	
	static func getTideExtremeAPI(lat : Double,lon: Double) -> String{
		
		let url = "\(API_URL)?extremes&lat=\(lat)&lon=\(lon)&length=\(60*60*12)&key=\(API_KEY)"
		print(url)
		return url
		
	}

	static func getTideExtremeAPI(lat : Double,lon: Double, time : Int) -> String{
		
		let url = "\(API_URL)?extremes&lat=\(lat)&lon=\(lon)&key=\(API_KEY)" + "&start=\(time)"
		print(url)
		return url
		
	}

	static func getMinMaxTime(list : [AnyObject]){
		print("minmax = \(list[0])")
	}
//	
//			let tideProvider = TideProvider()
//			let tideURL = tideProvider.getHeightAPIRequest(37.444917, longitude: 127.138868)
//	
//			print(tideURL)
//			Alamofire.request(.GET, tideURL)
//				.responseJSON{ response in
//					print(response.data)
//	
//					if let JSON = response.result.value{
//						print("JSON : \(JSON)")
//					}
//			}

}