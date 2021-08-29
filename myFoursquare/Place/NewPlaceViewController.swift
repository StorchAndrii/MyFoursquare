import UIKit



class NewPlaceViewController: UITableViewController {
    
    var currentPlace: Place!
    var imageIsChanged = false
    var currentRating = 0.0
    
    
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    @IBOutlet weak var placeImage: UIImageView!
    @IBOutlet weak var placeName: UITextField!
    @IBOutlet weak var placeLocation: UITextField!
    @IBOutlet weak var placeType: UITextField!
    
    @IBOutlet var ratingControl: RatingControl!
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //убираем разлиновку пустых ячеек
        tableView.tableFooterView = UIView(frame: CGRect(x: 0,
                                                         y: 0,
                                                         width: tableView.frame.size.width,
                                                         height: 1))
        
        //контроль включения saveButton
        saveButton.isEnabled = false
        placeName.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        //        запуск окна редактирования
        setupEditScreen()
        
        
        
    }
    
    
    //    MARK: Table view delegate
    //    Скрытие клавиатуры!! Если мы нажимаем на добавление картинки(ячейка с индексом 0) всплывает меню "ALERT" на добавление картинки и сделать фото, в другом случае скрываем клавиатуру.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0{
            
            let cameraIcon = #imageLiteral(resourceName: "Camera96x96")
            let photoIcon = #imageLiteral(resourceName: "Image96x96")
            
            
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            let camera = UIAlertAction(title: "Camera", style: .default){_ in
                self.chooseImagePicker(source: .camera)
            }
            //назначаем иконки в алерт камеры
            camera.setValue(cameraIcon, forKey: "image")
            camera.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            
            let photo = UIAlertAction(title: "Photo", style: .default){_ in
                self.chooseImagePicker(source: .photoLibrary)
            }
            //назначаем иконки в алерт фото
            photo.setValue(photoIcon, forKey: "image")
            photo.setValue(CATextLayerAlignmentMode.left, forKey: "titleTextAlignment")
            
            let cancel = UIAlertAction(title: "Cancel", style: .cancel)
            
            actionSheet.addAction(camera)
            actionSheet.addAction(photo)
            actionSheet.addAction(cancel)
            
            present(actionSheet, animated: true)
        } else {
            view.endEditing(true)
        }
    }
    
    //MARK: Navigation метеод перехода на MapView
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        // извлекаем идентификатор сигвея
        guard
            let identifier = segue.identifier,
            //создаем экземпляр класса mapViewController
            let mapVC = segue.destination as? MapViewController
        else { return }
        
        mapVC.incomeSegueIdentifier = identifier
        mapVC.mapViewControllerDelegate = self
        
        
        
        if identifier == "showPlace" {
            
            mapVC.place.name = placeName.text!
            mapVC.place.location = placeLocation.text
            mapVC.place.type = placeType.text
            mapVC.place.imageData = placeImage.image?.pngData()
        }
    }
    
    
    
    //MARK:  saveNewPlace  Сохранение нового места
    func savePlace(){
        
        
        
        //        если картинка не загружена. ставим картинку по умолчанию!
        let image = imageIsChanged ? placeImage.image : #imageLiteral(resourceName: "Burger")
        
        //        конвертируем изображение в Data
        let imageData = image?.pngData()
        //        модель данных
        let newPlace = Place(name: placeName.text!,
                             location: placeLocation.text,
                             type: placeType.text,
                             imageData: imageData,
                             rating: Double(ratingControl.rating))
        
        //MARK:внесение изменений в текущий обьект или сохранение нового
        if currentPlace != nil {
            //            внесение изменений в текущий обьект если не нил
            try! realm.write {
                currentPlace?.name = newPlace.name
                currentPlace?.location = newPlace.location
                currentPlace?.type = newPlace.type
                currentPlace?.imageData = newPlace.imageData
                currentPlace?.rating = newPlace.rating
            }
        } else {
            //        сохранение нового обьекта если нил
            StorageManager.saveObject(newPlace)
        }
    }
    
    
    
    //MARK: экран редактирования записи выбранной ячейка
    
    private func setupEditScreen(){
        if currentPlace != nil {
            setupNavigationBar()
            imageIsChanged = true
            
            //            приводим значение image.data в image
            guard let data = currentPlace?.imageData, let image = UIImage(data: data) else {return}
            
            placeImage.image = image
            placeImage.contentMode = .scaleAspectFill
            placeName.text = currentPlace?.name
            placeLocation.text = currentPlace?.location
            placeType.text = currentPlace?.type
            ratingControl.rating = Int(currentPlace.rating)
        }
    }
    private func setupNavigationBar(){
        //        убираем название с кнопки возврата
        if let topItem = navigationController?.navigationBar.topItem {
            topItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        }
        //        убираем кнопку cancel
        navigationItem.leftBarButtonItem = nil
        //        передаем имя заведения текущей ячейки
        title = currentPlace?.name
        //        активация кнопки save
        saveButton.isEnabled = true
        
        
    }
    
    
    
    // MARK:   закрытие окна при помощи кнопки cancel
    @IBAction func cancelAction(_ sender: Any) {
        dismiss(animated: true)
    }
}

//MARK: - Text field delegate
extension NewPlaceViewController: UITextFieldDelegate{
    //    Скрываем клавиатуру при нажатии DONE
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    //MARK: saveButton активация
    //    если поле placeName пустое saveButton не активно! (и наоборот)
    @objc private func textFieldChanged() {
        if placeName.text?.isEmpty == false {
            saveButton.isEnabled = true
        }else {
            saveButton.isEnabled = false
        }
    }
}


//MARK: Work with image - Работа с картинками
extension NewPlaceViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    
    //   UIImagePickerController.SourceType - Константы, которые описывают источник, который следует использовать при выборе изображения или при определении доступных типов носителей.
    //UIImagePickerController - Контроллер просмотра, который управляет системными интерфейсами для съемки, записи фильмов и выбора элементов из пользовательской медиатеки.
    func chooseImagePicker(source: UIImagePickerController.SourceType){
        if UIImagePickerController.isSourceTypeAvailable(source){
            let imagePiker = UIImagePickerController()
            imagePiker.delegate = self
            //Редактировать картинку
            imagePiker.allowsEditing = true
            imagePiker.sourceType = source
            present(imagePiker, animated: true)
        }
    }
    //    присваиваем выбранное изображение в imageOfPlace
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //        приведение к UIImage
        placeImage.image = info[.editedImage] as? UIImage
        //        масштабирование
        placeImage.contentMode = .scaleToFill
        //        обрезка по рамке
        placeImage.clipsToBounds = true
        
        imageIsChanged = true
        //        выход
        dismiss(animated: true)
    }
}
//подписываем класс
extension NewPlaceViewController: MapViewControllerDelegate {
    //передаем адресс
    func getAddress(_ address: String?) {
        placeLocation.text = address
    }
    
    
}
