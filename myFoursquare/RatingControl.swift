//
//  RatingControl.swift
//  myFoursquare
//
//  Created by Ночные Снайперы on 21.05.2021.
//

import UIKit


@IBDesignable class RatingControl: UIStackView {
    
    //MARK: Properties
    var rating = 0 {
        didSet {
            updateButtonSelectionState()
        }
    }
    
    private var ratingButtons = [UIButton]()
    
    //размер кнопок
    @IBInspectable var starSize: CGSize = CGSize(width: 44.0, height: 44.0){
        didSet{
            setupButtons()
        }
    }
    
    //количество кнопок
    //    @IBInspectable
    @IBInspectable var starCount: Int = 5 {
        didSet{
            setupButtons()
        }
    }
    
    //        MARK: Initialisation
    override init(frame: CGRect){
        super.init(frame: frame)
        setupButtons()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setupButtons()
    }
    //MARK: Button Action
    @objc func ratingButtonTapped(button: UIButton) {
        
        guard let index = ratingButtons.firstIndex(of: button) else { return }
        
        //рассчитываем значение выбранной кнопки
        let selectedRating = index + 1
        
        if selectedRating == rating {
            rating = 0
        } else {
            rating = selectedRating
        }
        
    }
    
    //    MARK: Private Methods
    
    private func setupButtons() {
        
        //удаление кнопок перед созданием новых
        for button in ratingButtons {
            removeArrangedSubview(button)
            button.removeFromSuperview()
        }
        
        ratingButtons.removeAll()
        
        
        // загрузка картинки для кнопки рейтинга
        let bundle = Bundle(for: type(of: self))
        
        let filledStar = UIImage(named: "filledStar", in: bundle, compatibleWith: self.traitCollection)
        
        let emptyStar = UIImage(named: "emptyStar", in: bundle, compatibleWith: self.traitCollection)
        
        let highlightedStar = UIImage(named: "highlightedStar", in: bundle, compatibleWith: self.traitCollection)
        
        
        
        
        
        //MARK: логика создания и добавления кнопок
        for _ in 0..<starCount {
            //        создание кнопки
            let button = UIButton()
            
            //установка картинки для кнопки рейтинга(setImage)
            button.setImage(emptyStar, for: .normal) //включенное, но не выбранное и не выделенное.
            button.setImage(filledStar, for: .selected)//выбранное состояние
            button.setImage(highlightedStar, for: .highlighted)//Выделенное состояние контроля.
            button.setImage(highlightedStar, for: [.highlighted, .selected])//Выделенное состояние контроля и выбранное состояние
            
            
            //        добавление констрейнов
            //отключаем автоматические констрейны
            button.translatesAutoresizingMaskIntoConstraints = false
            //высота
            button.heightAnchor.constraint(equalToConstant: starSize.height).isActive = true
            //ширина
            button.widthAnchor.constraint(equalToConstant: starSize.width).isActive = true
            
            //настройка кнопки
            button.addTarget(self, action: #selector(ratingButtonTapped(button:)), for: .touchUpInside)
            
            // добавление кнопки в стек
            addArrangedSubview(button)
            
            //добавление новой кнопки в массив ratingButtons
            ratingButtons.append(button)
        }
        updateButtonSelectionState()
    }
    
    //MARK: выполняем метод обновления значения рейтинга для кнопок
    private func updateButtonSelectionState() {
        for (index, button) in ratingButtons.enumerated() {
            button.isSelected = index < rating
        }
    }
    
}



