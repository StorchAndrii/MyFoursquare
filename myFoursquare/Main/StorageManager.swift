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
