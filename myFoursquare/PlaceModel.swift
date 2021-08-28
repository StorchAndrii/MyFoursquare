//
//  PlaceModel.swift
//  myFoursquare
//
//  Created by Ночные Снайперы on 16.05.2021.
//

import UIKit
import RealmSwift


class Place: Object {
    @objc dynamic var name: String = ""
    @objc dynamic var location: String?
    @objc dynamic var type: String?
    @objc dynamic var imageData: Data?
    @objc dynamic var date = Date()
    @objc dynamic var rating = 0.0
    
    //    инициализация класса
    convenience init(name: String, location: String?, type: String?, imageData: Data?, rating: Double){
        self.init()
        self.name = name
        self.location = location
        self.type = type
        self.imageData = imageData
        self.rating = rating
    }
}


