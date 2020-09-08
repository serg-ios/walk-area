//
//  StartViewController.swift
//  WalkArea
//
//  Created by Sergio Rodríguez Rama on 01/05/2020.
//  Copyright © 2020 Sergio Rodríguez Rama. All rights reserved.
//

import Foundation
import UIKit
import MapKit

protocol StartDelegate: class {
    func start(with distance: CLLocationDistance, in measuringUnit: MeasuringUnit)
    func dismiss()
}

class StartViewController: UIViewController {
    
    // MARK: - Static
    
    static let id = "StartViewController"
    
    static func create(delegate: StartDelegate) -> StartViewController {
        let storyboard = UIStoryboard(name: Self.id, bundle: nil)
        let viewController = storyboard.instantiateViewController(identifier: Self.id) as! StartViewController
        viewController.delegate = delegate
        return viewController
    }
    
    // MARK: - Private var let
    
    private weak var delegate: StartDelegate?
    private var distance: CLLocationDistance = 1000
    private var measuringUnit: MeasuringUnit!
    
    // MARK: - IBOutlet
    
    @IBOutlet private weak var beginButton: UIButton!
    @IBOutlet private weak var radiusTextField: UITextField!
    @IBOutlet private weak var measuringUnitPicker: UIPickerView!
    
    // MARK: - IBAction
    
    @IBAction func radiusTextFieldEditingChanged(_ sender: UITextField) {
        if let radiusStr = sender.text,
            let radius = CLLocationDistance(radiusStr),
            radius > 0 {
            distance = radius
            beginButton.isEnabled = true
        } else {
            beginButton.isEnabled = false
        }
    }
    
    @IBAction func beginButtonTouchUpInside(_ sender: UIButton) {
        
        let alert = UIAlertController(title: NSLocalizedString("New walk", comment: ""), message: NSLocalizedString("Do you want to start a new walk?", comment: ""), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("No", comment: ""), style: .default, handler: nil))
        let yesAction = UIAlertAction(title: NSLocalizedString("Yes", comment: ""), style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.start(with: self.measuringUnit.inMeters(self.distance), in: self.measuringUnit)
            self.dismiss(animated: true, completion: nil)
        })
        alert.addAction(yesAction)
        alert.preferredAction = yesAction
        present(alert, animated: true)
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViewTapGesture()
        setupMeasuringUnitPicker()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        radiusTextField.becomeFirstResponder()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        delegate?.dismiss()
    }
}

// MARK: - UIPickerViewDataSource methods

extension StartViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        MeasuringUnit.allCases.count
    }
}

// MARK: - UIPickerViewDelegate methods

extension StartViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        measuringUnit = MeasuringUnit.allCases[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let measuringUnit = MeasuringUnit.allCases[row]
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byTruncatingMiddle
        paragraphStyle.alignment = .center
        let attributedString = NSMutableAttributedString(string: "\(measuringUnit.name) (\(measuringUnit.symbol))")
        let range = NSRange(location: 0, length: attributedString.mutableString.length)
        attributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: range)
        return attributedString
    }
}

// MARK: - Private methods

private extension StartViewController {
    
    func setupViewTapGesture() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func setupMeasuringUnitPicker() {
        measuringUnitPicker.dataSource = self
        measuringUnitPicker.delegate = self
        measuringUnit = MeasuringUnit.allCases[measuringUnitPicker.selectedRow(inComponent: 0)]
    }
    
    @objc func hideKeyboard() {
        radiusTextField.resignFirstResponder()
    }
}
