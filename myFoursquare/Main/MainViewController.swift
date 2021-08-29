import UIKit
import RealmSwift

class MainViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    
    private let searchController = UISearchController(searchResultsController: nil)
    
    private var places: Results<Place>!
    
    private var filteredPlaces: Results<Place>!
    
    private var ascendingSorting = true
    
    private var searchBarIsEmpty: Bool{
        guard let text = searchController.searchBar.text else {return false}
        return text.isEmpty
    }
    private var isFiltering: Bool {
        return searchController.isActive && !searchBarIsEmpty
    }
    
    
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var segmentedControl: UISegmentedControl!
    
    @IBOutlet var reversedSortingButton: UIBarButtonItem!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        places = realm.objects(Place.self)
        
        
        //MARK: Setup the Search controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }
    
    // MARK: - Table view data source (Таблица просмотра данных источника)
    
    //метод отоброжает количество ячеек в конкретной  секции
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            return filteredPlaces.count
        }
        return places.count
    }
    
    
    //MARK: метод отображения контента в конкретной Cell (ячейке)
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! CustomTableViewCell
        
        
        //присвоение к Label ячейки конкретный элемент с массива который мы берем по индексу текущей строки [indexPath.row] (.row - возвращает целочисленное значения индекса массива)
        let place = isFiltering ? filteredPlaces[indexPath.row] : places[indexPath.row]
        
        
        
        cell.nameLabel?.text = place.name
        cell.locationLabel.text = place.location
        cell.typeLabel.text = place.type
        //добавление картинки в ячейку
        cell.imageOfPlace.image = UIImage(data: place.imageData!)
        
        //присвоение рейтинга на главный экран с базы данных
        cell.cosmosView.rating = place.rating
        
        return cell
    }
    
    //MARK: Анимация ячеек
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let degree: Double = 90
        let rotationAngle = CGFloat(degree * .pi / 180)
        let rotationTransform = CATransform3DMakeRotation(rotationAngle, 1, 0, 0)
        cell.layer.transform = rotationTransform
        UIView.animate(withDuration: 0.5, delay: 0.1 * Double(indexPath.row), options: .curveEaseInOut) {
            cell.layer.transform = CATransform3DIdentity
        }
    }
    
    
    // MARK: Table view delegate
    
    //отмена выделения ячейки
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    //метод вызова меню при свайпе по ячейке справа на лево
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let place = places[indexPath.row]
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") {  (contextualAction, view, boolValue) in
            
            StorageManager.deleteObject(place)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        let swipeActions = UISwipeActionsConfiguration(actions: [deleteAction])
        
        return swipeActions
    }
    
    
    // MARK: - Navigation
    //     переход в окно детального просмотра и редактирования данных в ячейке при нажатии на него
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            //извлечение обьекта по индексу ячейки.
            //извлекаем индекс выбранной ячейки.
            guard let indexPath = tableView.indexPathForSelectedRow else { return }
            
            //извлекаем обьект по полученному индексу с условиями поиска
            let place = isFiltering ? filteredPlaces[indexPath.row] : places[indexPath.row]
            
            //создаем экземпляр VC
            let newPlaceVC = segue.destination as! NewPlaceViewController
            //присваиваем и передаем обьект с выбранной ячейки в новое окно newPlaceVC
            newPlaceVC.currentPlace = place
        }
    }
    
    
    
    //    возврат на главный экран при помощи кнопки save с окна NewPlace. с переносом всех заполненных данных в главное окно с сохранением в массив places. и заполнением новой ячейки.
    @IBAction func unwindSegue(_ seque: UIStoryboardSegue){
        guard let newPlaceVC = seque.source as? NewPlaceViewController else {return}
        newPlaceVC.savePlace()
        tableView.reloadData()
    }
    
    //    MARK: Сортировка
    
    
    @IBAction func sortSelection(_ sender: UISegmentedControl) {
        sorting()
    }
    
    @IBAction func reversedSorting(_ sender: Any) {
        ascendingSorting.toggle()
        sorting()
    }
    
    //    настройка сортировки
    private func sorting(){
        if segmentedControl.selectedSegmentIndex == 0 {
            places = places.sorted(byKeyPath: "date", ascending: ascendingSorting)
        }else{
            places = places.sorted(byKeyPath: "name", ascending: ascendingSorting)
        }
        tableView.reloadData()
    }
}
//настройка поиска
extension MainViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    private func filterContentForSearchText(_ searchText: String) {
        filteredPlaces = places.filter("name CONTAINS[c] %@ OR location CONTAINS[c] %@", searchText, searchText)
        
        tableView.reloadData()
    }
}
