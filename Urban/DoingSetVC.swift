//
//  DoingSetVC.swift
//  Urban
//
//  Created by Kangtle on 8/15/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import FirebaseStorage
import AVFoundation
import AVKit

class DoingSetVC: UIViewController {

    @IBOutlet weak var setImageView: UIImageView!
    @IBOutlet weak var setNameLabel: UILabel!

    @IBOutlet weak var chartView: UIView!
    @IBOutlet weak var elapsedTimeLabel: UILabel!
    @IBOutlet weak var leftTimeLabel: UILabel!
    @IBOutlet weak var textView: UIView!

    @IBOutlet weak var cooldownView: UIView!
    @IBOutlet weak var cooldownChartView: UIView!
    @IBOutlet weak var cooldownElapsedTimeLabel: UILabel!
    @IBOutlet weak var cooldownLeftTimeLabel: UILabel!
    @IBOutlet weak var cooldownTextView: UIView!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var doneBtn: UIButton!
    @IBOutlet weak var repsLabel: UILabel!
    
    let storageRef = Storage.storage().reference()

    var set: WorkoutSet! = nil
    
    var progressTime: Int = 0
    var cooldownProgressTime: Int = 0
    
    var timer: Timer? = nil
    var cooldownTimer: Timer? = nil

    let chartShapeLayer = CAShapeLayer()
    let cooldownChartShapeLayer = CAShapeLayer()
    
    var isWatchingVideo = false
    
    var onDoneBlock: ((Bool) -> Void)?

    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .any, barMetrics: .default)
        self.toolbar.backgroundColor = .clear

        setImageView.layer.cornerRadius = setImageView.frame.width/2
        setImageView.clipsToBounds = true

        let reference = storageRef.child(set.thumbUrl)
        let placeholderImage = UIImage(named: "placeholder_fitness.png")
        setImageView.sd_setImage(with: reference, placeholderImage: placeholderImage)

        setNameLabel.text = set.name
        
        if set.duration > 0 {
            chartView.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi/2));
            textView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/2));
            
            cooldownChartView.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi/2));
            cooldownTextView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/2));
            
            drawBGCircle()
            
            //change the fill color
            chartShapeLayer.fillColor = UIColor.clear.cgColor
            //you can change the stroke color
            chartShapeLayer.strokeColor = UIColor(rgb: 0xCB2D3E).cgColor
            //you can change the line width
            chartShapeLayer.lineWidth = 7.0
            
            chartView.layer.addSublayer(chartShapeLayer)
            
            
            
            //change the fill color
            cooldownChartShapeLayer.fillColor = UIColor.clear.cgColor
            //you can change the stroke color
            cooldownChartShapeLayer.strokeColor = UIColor(rgb: 0xCB2D3E).cgColor
            //you can change the line width
            cooldownChartShapeLayer.lineWidth = 7.0
            
            cooldownChartView.layer.addSublayer(cooldownChartShapeLayer)
            
            self.runTimer()
        }else{
            repsLabel.isHidden = false
            doneBtn.isHidden = false
            chartView.isHidden = true
            
            repsLabel.text = "REPS: \(set.reps ?? 0)"
        }
        // Do any additional setup after loading the view.
    }

    func runTimer(){
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateChart), userInfo: nil, repeats: true)
        timer?.fire()
    }

    func runCooldownTimer(){
        cooldownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateCooldownChart), userInfo: nil, repeats: true)
        cooldownTimer?.fire()
    }
    
    func drawBGCircle(){
        let radius = CGFloat(chartView.frame.width/2)
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: radius, y: radius),
                                      radius: radius,
                                      startAngle: CGFloat(0),
                                      endAngle:CGFloat(Double.pi*2),
                                      clockwise: true)
        
        let shapeLayer1 = CAShapeLayer()
        shapeLayer1.path = circlePath.cgPath
        
        //change the fill color
        shapeLayer1.fillColor = UIColor.clear.cgColor
        //you can change the stroke color
        shapeLayer1.strokeColor = UIColor(rgb: 0x2D2E40).withAlphaComponent(0.9).cgColor
        //you can change the line width
        shapeLayer1.lineWidth = 7.0
        
        let shapeLayer2 = CAShapeLayer()
        shapeLayer2.path = circlePath.cgPath
        
        //change the fill color
        shapeLayer2.fillColor = UIColor.clear.cgColor
        //you can change the stroke color
        shapeLayer2.strokeColor = UIColor(rgb: 0x2D2E40).withAlphaComponent(0.9).cgColor
        //you can change the line width
        shapeLayer2.lineWidth = 7.0
        
        chartView.layer.addSublayer(shapeLayer1)
        cooldownChartView.layer.addSublayer(shapeLayer2)
        
    }

    func updateChart(){
        
        let progressChart = Double.pi * 2 / Double(set.duration * 60) * Double(progressTime)
        
        let radius = CGFloat(chartView.frame.width/2)
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: radius, y: radius),
                                      radius: radius,
                                      startAngle: CGFloat(0),
                                      endAngle:CGFloat(progressChart),
                                      clockwise: true)
        
        chartShapeLayer.path = circlePath.cgPath
        
        let elapsedMin = Int(progressTime / 60)
        let elapsedSec = progressTime % 60
        let elapsedStr = "\(String(format: "%02d", elapsedMin)):\(String(format: "%02d", elapsedSec))m"
        
        let leftTime = set.duration*60-progressTime
        let leftMin = Int(leftTime / 60)
        let leftSec = leftTime % 60
        let leftStr = "\(leftMin)m \(leftSec)sec left"
        
        self.elapsedTimeLabel.text = elapsedStr
        self.leftTimeLabel.text = leftStr
        
        if(set.duration * 60 == progressTime){
            timer?.invalidate()
            if onDoneBlock != nil {
                self.dismiss(animated: true, completion: nil)
                self.onDoneBlock!(true)
            }
        }
        
        progressTime += 1
    }
    
    func updateCooldownChart(){
        
        let progressChart = Double.pi * 2 / Double(30) * Double(cooldownProgressTime)
        
        let radius = CGFloat(chartView.frame.width/2)
        let circlePath = UIBezierPath(arcCenter: CGPoint(x: radius, y: radius),
                                      radius: radius,
                                      startAngle: CGFloat(0),
                                      endAngle:CGFloat(progressChart),
                                      clockwise: true)
        
        cooldownChartShapeLayer.path = circlePath.cgPath
        
        let elapsedMin = Int(cooldownProgressTime / 60)
        let elapsedSec = cooldownProgressTime % 60
        let elapsedStr = "\(String(format: "%02d", elapsedMin)):\(String(format: "%02d", elapsedSec))m"
        
        let leftTime = 30-cooldownProgressTime
        let leftMin = Int(leftTime / 60)
        let leftSec = leftTime % 60
        let leftStr = "\(leftMin)m \(leftSec)sec left"
        
        self.cooldownElapsedTimeLabel.text = elapsedStr
        self.cooldownLeftTimeLabel.text = leftStr
        
        if(cooldownProgressTime == 30){
            timer?.invalidate()
            cooldown(isHidden: true)
        }
        
        cooldownProgressTime += 1
    }
    
    @IBAction func onPressedWatchAgain(_ sender: Any) {
        let avpController = AVPlayerViewController()
        
        storageRef.child(set.videoUrl).downloadURL(){  url, error in
            if error == nil {
                self.isWatchingVideo = true
                self.timer?.invalidate()
                let player = AVPlayer(url: url!)
                avpController.player = player
                self.present(avpController, animated: true, completion: nil)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent

        if isWatchingVideo {
            isWatchingVideo = false
            self.runTimer()
        }
    }
    
    @IBAction func onTapChatView(_ sender: Any) {
        print("tap chat View")
        cooldown(isHidden: false)
    }
    @IBAction func onTapCooldownChatView(_ sender: Any) {
        print("tap cooldown chat View")
        cooldown(isHidden: true)
    }
    
    func cooldown(isHidden: Bool) {
        if isHidden {
            self.cooldownView.isHidden = true
            self.runTimer()
            cooldownTimer?.invalidate()
        }else{
            self.cooldownView.isHidden = false
            timer?.invalidate()
            cooldownProgressTime = 0
            self.runCooldownTimer()
        
        }
    }
    
    @IBAction func onBack(_ sender: Any) {
        self.performSegueToReturnBack()
        self.onDoneBlock!(false)
    }
    
    @IBAction func onPressedDone(_ sender: Any) {
        if onDoneBlock != nil {
            self.dismiss(animated: true, completion: nil)
            self.onDoneBlock!(true)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
