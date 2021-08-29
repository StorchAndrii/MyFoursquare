import UIKit
import Alamofire
import SwiftyJSON
import MapKit




class MakeReqvest {
    class func forsquaer(  completion: @escaping ((_ placeList: [String], _ addressList: [String], _ placeLng: [String], _ placeLat: [String] )  -> Void))   {
        var placeList: [String] = []
        var addressList: [String] = []
        var placeLng: [String] = []
        var placeLat: [String] = []
        
        
        let location2:CLLocationCoordinate2D = CLLocationManager().location!.coordinate
        let lat = String(location2.latitude)
        let long = String(location2.longitude)
        
        
        let url = "https://api.foursquare.com/v2/venues/search?ll=\(lat),\(long)&client_id=JGJNMTC0LPZYTZEIZO23P4J31QFW43KEZ1MVGEJV21KW3ZVL&client_secret=XK1EVZ14ZAYINXJUSIFYNQVHJWHBPUJMX5WCMCINBHVAMRE3&v=20210530"
        
        Alamofire.request(url, method: .get).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                                print("\(json["meta"]["code"])")
                
                for (_, subJSON) in json["response"]["venues"]{
                    
                                        print(subJSON["name"])
                    placeList.append(subJSON["name"].stringValue)
                    
                                        print(subJSON["location"]["address"])
                    addressList.append(subJSON["location"]["address"].stringValue)
                    
                    print(subJSON["location"]["lng"])
                    placeLng.append(subJSON["location"]["lng"].stringValue)
                    
                    print(subJSON["location"]["lat"])
                    placeLat.append(subJSON["location"]["lat"].stringValue)
                    
                }
                completion(placeList, addressList, placeLng, placeLat)
                
            case .failure(let error):
                print(error)
            }
            
        }
        
    }
}
