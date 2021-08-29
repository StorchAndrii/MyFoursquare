//
//  MapViewController.swift
//  myFoursquare
//
//  Created by Ночные Снайперы on 25.05.2021.
//

import UIKit
import MapKit
import CoreLocation

protocol MapViewControllerDelegate {
    func getAddress (_ address: String?)
}
class MapViewController: UIViewController {
    
    var mapViewControllerDelegate: MapViewControllerDelegate?
    var place = Place()
    
    let annotationIdentifier = "annotationIdentifier"
    let locationManager = CLLocationManager()
    let regionInMeters = 1000.00
    var incomeSegueIdentifier = ""
    var placeCoordinate: CLLocationCoordinate2D?
    var directionsArray: [MKDirections] = []
    var previousLocation: CLLocation? {
        didSet {
            startTrackingUserLocation()
        }
    }

    
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var mapPinImage: UIImageView!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var doneButton: UIButton!
    @IBOutlet var goBotton: UIButton!
    @IBOutlet var distanceLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        setupMapView()
        checkLocationEnabled()
    }
    
    
    //центрирование карты относительно позиции пользователя при нажатии на кнопку
    @IBAction func centerViewUserLocation(_ sender: Any) {
        showUserLocation()
    }
    
    @IBAction func doneButtonPressed() {
        // при нажитии кнопки передаем данные addressLabel в PlaceLocation
        mapViewControllerDelegate?.getAddress(addressLabel.text)
        
        // закрываем ViewController
        dismiss(animated: true)
    }
    
    @IBAction func goButtonPressed() {
        getDirections()
        distanceLabel.isHidden = false
        timeLabel.isHidden = false
    }
    
    @IBAction func closeVC() {
        dismiss(animated: true)
    }

    
    
    //MARK:  позиционирование карты  по заданному сигвею кнопки на метку места.
    private func setupMapView() {
        
        goBotton.isHidden = true
        distanceLabel.isHidden = true
        timeLabel.isHidden = true
        
        
        if incomeSegueIdentifier == "showPlace" {
            setupPlaceMark()
            //скрываем маркер центра карты
            mapPinImage.isHidden = true
            //скрываем addressLabel
            addressLabel.isHidden = true
            //скрываем doneButton
            doneButton.isHidden = true
            
            goBotton.isHidden = false
            
            
        }
    }
    
    //MARK: отменяем все действующие маршруты и удаляем их с карты
    private func resetMapView(withNew directions: MKDirections) {
        //удаление текущего маршрута
        mapView.removeOverlays(mapView.overlays)
        //добавляем в массив текущие маршруты
        directionsArray.append(directions)
        //перебираем все значения массива и отменить у каждого элемента маршрут
        let _ = directionsArray.map { $0.cancel() }
        //удаляем все элементы у массива
        directionsArray.removeAll()
    }
    
    
    //MARK: маркер отображающий обьект на карте
    private func setupPlaceMark() {
        //извлекаем место
        guard let location = place.location else { return }
        //преобразования между географическими координатами и названиями мест.
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { placemarks, error in
            //проверка error на ошибки
            if let error = error {
                print(error)
                return
            }
            //извлекаем опционал с plasemarks
            guard let placemarks = placemarks else { return }
            
            //получаем метку на карте
            let placemark = placemarks.first
            
            //описываем точку на которую указывает маркер на карте
            let annotation = MKPointAnnotation()
            annotation.title = self.place.name
            annotation.subtitle = self.place.type

            // привязываем созданную аннотацию к конкретной точке на карте в соответствии с местом положения маркера
            //определяем местоположение маркера
            guard let placemarkLocation = placemark?.location else { return }
            //привязываем аннотацию к этой точке на карте
            annotation.coordinate = placemarkLocation.coordinate
            
            //передаем координаты
            self.placeCoordinate = placemarkLocation.coordinate
            
            //создаем видимую область на карте для отображения всех созданных аннотаций
            self.mapView.showAnnotations([annotation], animated: true)
            //выделяем созданную аннотацию
            self.mapView.selectAnnotation(annotation, animated: true)
            
        }
    }
    
    
    //MARK: определение местоположения
    private func checkLocationEnabled(){
        if CLLocationManager.locationServicesEnabled(){
            setupManager()
            checkAuthorization()
        }else{
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.showAlertLocation(title: "У вас выключенна служба геолокации", message: "Хотите включить?", url: URL(string: "App-Prefs:root=LOCATION_SERVICES"))
            }
        }
    }
    func setupManager(){
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    
    private func checkAuthorization(){
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            break
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
            // позиционирование карты по сигвею кнопки  текущего местоположения
            if incomeSegueIdentifier == "getAddress" { showUserLocation() }
            locationManager.startUpdatingLocation()
            break
        case .denied:
            showAlertLocation(title: "Вы запретили использование местоположения", message: "хотите это изменить?", url:  URL(string: UIApplication.openSettingsURLString))
            break
        case .restricted:
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            
        @unknown default:
            print("new case")
        }
    }
    
    //MARK: центрирование карты относительно позиции пользователя
    private func showUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion(center: location,
                                            latitudinalMeters: regionInMeters,
                                            longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
            
        }
    }

    //MARK: отслеживание стартового местоположения пользователя
    private func startTrackingUserLocation(){
        //извлекаем значение
        guard let previousLocation = previousLocation else { return }
        //определяем координаты центра текущей области
        let center = getCenterLocation(for: mapView)
        //определяем расстояние до центра текущей области от предыдущей точки
        guard center.distance(from: previousLocation) > 50 else { return }
        // задаем новые координаты равные текущим
        self.previousLocation = center
        
        //позиционируем карту в соответствии с текущим местоположением пользователя.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showUserLocation()
        }
        
        
    }
    
    
    //MARK: логика прокладывания маршрута.
    private func getDirections() {
        //извлекаем координаты
        guard let location = locationManager.location?.coordinate else {
            showAlert(title: "Error", message: "Current location is not found")
            return
        }
        
        //режим постоянного отслеживания местоположения пользователя
        locationManager.startUpdatingLocation()
        //передаем текущие координаты
        previousLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        
        //выполняем запрос на прокладку маршрута
        guard let request = createDirectionsRequest(from: location) else {
            showAlert(title: "Error", message: "Destination is not found")
            return
        }
         // создаем маршрут
        let directions = MKDirections(request: request)
            //избавляемся от текущих маршрутов перед созданием нового
        resetMapView(withNew: directions)

        //расчет маршрута
        directions.calculate { response, error in
            // извлекаем ошибку
            if let error = error {
                print(error)
                return
            }
            // извлекаем обработанный маршрут
            guard let responce = response else {
                self.showAlert(title: "Error", message: "Directions is not available")
                return
            }
            //перебор массива маршрутов
            for route in responce.routes {
                //создаем наложение со всеми маршрутами
                self.mapView.addOverlay(route.polyline)
                //фокусируем маршрут целиком, от точки А к точке Б. по геометрии маршрута
                self.mapView.setVisibleMapRect(route.polyline.boundingMapRect,  animated: true)


                //устанавливаем дополнительную информацию по маршруту.
                //расстояние
                let distance = String(format: "%.1f", route.distance / 1000)
                
                //время в пути
                let timeInterval = String(format: "%.1f", route.expectedTravelTime / 60)
                
                self.distanceLabel.text = "Расстояние до места: \(distance) km."
                self.timeLabel.text = "Время в пути составит: \(timeInterval) min"

                print("Расстояние до места: \(distance) km")
                print("Время в пути составит: \(timeInterval) min")
            }
        }
    }

    
    //MARK: настройка  запроса на прокладку маршрута
    private func createDirectionsRequest(from coordinate: CLLocationCoordinate2D) -> MKDirections.Request? {
        //передаем координаты заведения
        guard let destinationCoordinate = placeCoordinate else { return nil }
        //определяем стартовую точку
        let startingLocation = MKPlacemark(coordinate: coordinate)
        //определяем конечную точку
        let destination = MKPlacemark(coordinate: destinationCoordinate)
        
        //создаем запрос на построение маршрута
        let request = MKDirections.Request()
        //создаем стартовую точку
        request.source = MKMapItem(placemark: startingLocation)
        //создаем конечную точку
        request.destination = MKMapItem(placemark: destination)
        // указываем тип транспорта
        request.transportType = .automobile
        // разрешаем устанавливать альтернативные маршруты
        request.requestsAlternateRoutes = false
        
        return request
    }
    
    
    //MARK: возвращаем координаты центра экрана
    private func getCenterLocation(for mapView: MKMapView) -> CLLocation {
        let latitude = mapView.centerCoordinate.latitude
        let longitude = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
    
    //MARK: создание Alert
    private func showAlertLocation(title:String, message:String?, url:URL?){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Setting", style: .default) { (alert) in
            //            URL(string: "App-Prefs:root=LOCATION_SERVICES")
            if let url = url{
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        let cancelAction = UIAlertAction(title: "cancel", style: .cancel, handler: nil)
        
        alert.addAction(settingsAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    private func showAlert(title: String, message: String) {
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        
        alert.addAction(okAction)
        present(alert, animated: true)
    }
}

//MARK: MKMapViewDelegate
extension MapViewController: MKMapViewDelegate{
    //отоброжение анотаций
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        guard !(annotation is MKUserLocation) else { return nil}
        //Возвращает повторно используемый вид аннотации, расположенный по его идентификатору.
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier) as? MKPinAnnotationView
        
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            annotationView?.canShowCallout = true
        }
        //размещаем изображение внутри банера
        if let imageData = place.imageData {
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            imageView.layer.cornerRadius = 10
            imageView.clipsToBounds = true
            imageView.image = UIImage(data: imageData)
            annotationView?.rightCalloutAccessoryView = imageView
        }
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        let center = getCenterLocation(for: mapView)
        let geocoder = CLGeocoder()
        
        //возврат фокусировки карты на местоположение пользователя
        if incomeSegueIdentifier == "showPlace" && previousLocation != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.showUserLocation()
            }
        }
         // делаем отмену отложенного запроса
        geocoder.cancelGeocode()
        
        
        geocoder.reverseGeocodeLocation(center) { (placemarks, error) in
            
            if let error = error {
                print(error)
                return
            }
            // извлекаем массив методов
            guard let placemarks = placemarks else { return }
            
            let placemark = placemarks.first
            // извлекаем улицу
            let streetName = placemark?.thoroughfare
            // извлекаем номер дома
            let buildNumber = placemark?.subThoroughfare
            
            //передаем Асинхронно значения в лейбл addressLabel
            DispatchQueue.main.async {
                
                if streetName != nil && buildNumber != nil {
                    self.addressLabel.text = "\(streetName!), \(buildNumber!)"
                } else if streetName != nil {
                    self.addressLabel.text = "\(streetName!)"
                } else {
                    self.addressLabel.text = ""
                }
            }
        }
    }
    
    // MARK: отображение всех маршрутов
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .blue
        
        return renderer
    }
}

extension MapViewController:CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let locations = locations.last?.coordinate{
            let region = MKCoordinateRegion(center: locations, latitudinalMeters: 500, longitudinalMeters: 500)
            mapView.setRegion(region, animated: true)
            
        }
    }
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        checkAuthorization()
    }
}

