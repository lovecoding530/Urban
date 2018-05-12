//
//  Helper.swift
//  Urban
//
//  Created by Kangtle on 8/9/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import CoreLocation

//MARK: extensions
extension String {
    func capitalizingFirstLetter() -> String {
        let first = String(characters.prefix(1)).capitalized
        let other = String(characters.dropFirst())
        return first + other
    }
    
    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}

extension Int {
    func formattedNumber() -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = NumberFormatter.Style.decimal
        let formattedNumber = numberFormatter.string(from: NSNumber(value:self))
        return formattedNumber!
    }
}

extension UIViewController {
    func performSegueToReturnBack()  {
        if let nav = self.navigationController {
            nav.popViewController(animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }
}

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}


extension UIImageView {
    func downloadedFrom(url: URL, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() { () -> Void in
                self.image = image
            }
            }.resume()
    }
    func downloadedFrom(link: String, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloadedFrom(url: url, contentMode: mode)
    }
}

extension UIView {
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
}


extension UITextField : UITextFieldDelegate{
    func loadDropdownData(data: [String], onSelect: ((String)->())? = nil) {
        let pickerView = KPickerView(pickerData: data, dropdownField: self)
        pickerView.onSelect = onSelect
        self.inputView = pickerView
    }
    
    func setTextWithPickerView(text: String!) {
        let pickerView:KPickerView = self.inputView as! KPickerView
        
        pickerView.selectRow(withText: text)
    }
}

extension URL {
    
    public var queryParameters: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: true), let queryItems = components.queryItems else {
            return nil
        }
        
        var parameters = [String: String]()
        for item in queryItems {
            parameters[item.name] = item.value
        }
        
        return parameters
    }
}

//MARK: APP

var locManager: CLLocationManager = {
    let _locationManager = CLLocationManager()
//    _locationManager.requestWhenInUseAuthorization()
    return _locationManager
}()

enum MeasurementSystem: String{
    case Imperial = "Imperial (lb/inches)"
    case Metric = "Metric (kg/cms)"
}

class Helper{
    static let defaults = UserDefaults.standard

    static func isValidEmail(email:String) -> Bool {
        // print("validate calendar: \(testStr)")
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: email)
    }
    
    static func showMessage(target: UIViewController, title:String, message: String, completion: (()->())?=nil){

        let _title = title == "" ? "Urban" : title
        
        let alert = UIAlertController(title: _title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
        {
            (result : UIAlertAction) -> Void in
            if(completion != nil){
                completion!()
            }
        }
        alert.addAction(okAction)
        target.present(alert, animated: true, completion: nil)
    }
    
    static func distance(fromLat: Double, fromLong: Double, distanceUnit: String) -> Double {
        
        let myLocation = locManager.location
        let fromLocation = CLLocation(latitude: fromLat, longitude: fromLong)
        
        let distanceInMeters = myLocation?.distance(from: fromLocation) // result is in meters
        //you get here distance in meter so 1 miles = 1609 meter
        if distanceUnit == "Km" {
            let distanceInMiles = distanceInMeters!/1000
            return Double(round(distanceInMiles * 10)/10)
        }else{
            let distanceInMiles = distanceInMeters!/1609
            return Double(round(distanceInMiles * 10)/10)
        }
    }
    
    static func insertGradientLayer(target: UIView) -> CAGradientLayer{
        
        var gl:CAGradientLayer!
        
        let colorTop = UIColor.clear.cgColor
        let colorBottom = UIColor.init(rgb: 0x2D2E40).cgColor // 0x1d1d27
        
        gl = CAGradientLayer()
        gl.colors = [colorTop, colorBottom]
        gl.locations = [0.5, 1.0]
        
        target.backgroundColor = UIColor.clear
        gl.frame = target.bounds
        target.layer.insertSublayer(gl, at: 0)

        return gl
    }
    
    static func kg_to_lb(kgs: Double)->Double{
        // 1kg = 2.2046226218 lb
        // 1lb = 16 oz
        return kgs * 2.2046226218
    }
    
    static func cm_to_inche(cms: Double)->Double{
        // 1 in = 2.54 cm
        return cms / 2.54
    }
    
    static func convertMeasureSystem(key: String, value: String) -> String {
        let systemStr = defaults.string(forKey: "measurement_system") ?? MeasurementSystem.Metric.rawValue
        let userMeasurementSystem = MeasurementSystem(rawValue: systemStr)!
        
        var convertedStr: String = ""
        if key == "Weight" {
            let kgs = Double(value) ?? 0.0
            if userMeasurementSystem == MeasurementSystem.Imperial {
                let lbs = Helper.kg_to_lb(kgs: kgs)
                convertedStr = String(format: "%.1f lb", lbs)
            }else{
                convertedStr = String(format: "%.1f kg", kgs)
            }
        } else if key == "Body_Fat" {
            let fats = Double(value) ?? 0.0
            convertedStr = String(format: "%.1f %%", fats)
        } else if key == "Blood_Pressure" {
            convertedStr = value.isEmpty ? "0 / 0" : value
        } else { // length
            let cms = Double(value) ?? 0.0
            if userMeasurementSystem == MeasurementSystem.Imperial {
                let inches = Helper.cm_to_inche(cms: cms)
                convertedStr = String(format: "%.1f in", inches)
            }else{
                convertedStr = String(format: "%.1f cm", cms)
            }
        }
        
        return convertedStr
    }
    
    static func timeStr(for date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a, d MMM"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"

        var timeStr = ""
        
        let diff = Int64(Date().timeIntervalSince1970) - Int64(date.timeIntervalSince1970)
        
        if diff < 2 * 60 {//2min
            timeStr = "Just now"
        }else if diff < 60 * 60 { //1h
            timeStr = "\(Int(diff / 60))min ago"
        }else if diff < 12 * 60 * 60 { //12
            timeStr = "\(Int(diff / 3600))h ago"
        }else{
            timeStr = dateFormatter.string(from: date)
        }
        return timeStr
    }
}
