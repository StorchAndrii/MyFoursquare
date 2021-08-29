//
//  StorageManager.swift
//  myFoursquare
//
//  Created by Ночные Снайперы on 16.05.2021.
//

import RealmSwift

let realm = try! Realm()
class StorageManager {
    static func saveObject(_ place: Place){
        try! realm.write{
            realm.add(place)
        }
    }
    //    метод удаления объекта
    static func deleteObject(_ place: Place){
        try! realm.write{
            realm.delete(place)
        }
    }
}
