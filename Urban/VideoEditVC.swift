//
//  VideoEditVC.swift
//  Urban
//
//  Created by Kangtle on 9/5/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import Firebase
import FirebaseStorage
import TOCropViewController

class VideoEditVC: UIViewController, ABVideoRangeSliderDelegate, TOCropViewControllerDelegate {

    var videoUrl: URL!
    var videoEditingUrl: URL!
    var player: AVPlayer?
    var avpController = AVPlayerViewController()

    var startTime = 0.0;
    var endTime = 0.0;
    var progressTime = 0.0;
    var shouldUpdateProgressIndicator = true
    var isSeeking = false
    
    let storageRef = Storage.storage().reference()
    var ref = Database.database().reference()

    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var videoRangeSlider: ABVideoRangeSlider!
    @IBOutlet weak var btnSound: UIButton!
    
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .default
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tabBarController?.tabBar.isHidden = true
        
        self.avpController = AVPlayerViewController()
        avpController.view.frame = videoView.frame
        self.addChildViewController(avpController)
        self.view.addSubview(avpController.view)

        self.setVideo(with: videoUrl)
        
        videoRangeSlider.delegate = self
        videoRangeSlider.setBorderImage(image: UIImage())
        videoRangeSlider.hideProgressIndicator()
        videoRangeSlider.startTimeView.backgroundView.backgroundColor = .clear
        videoRangeSlider.endTimeView.backgroundView.backgroundColor = .clear
        
        // Do any additional setup after loading the view.
    }
    
    //MARK: ABVideoRangeSlider
    
    func indicatorDidChangePosition(videoRangeSlider: ABVideoRangeSlider, position: Float64) {

        
    }
    func didChangeValue(videoRangeSlider: ABVideoRangeSlider, startTime: Float64, endTime: Float64) {
        
        if startTime != self.startTime{
            self.startTime = startTime
            self.endTime = endTime
            let timescale = self.player?.currentItem?.asset.duration.timescale
            let time = CMTimeMakeWithSeconds(self.startTime, timescale!)
            if !self.isSeeking{
                self.isSeeking = true
                self.player?.seek(to: time, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero){_ in
                    self.isSeeking = false
                }
            }
        }else{
            self.endTime = endTime
            self.startTime = startTime
            let timescale = self.player?.currentItem?.asset.duration.timescale
            let time = CMTimeMakeWithSeconds(self.endTime, timescale!)
            if !self.isSeeking{
                self.isSeeking = true
                self.player?.seek(to: time, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero){_ in
                    self.isSeeking = false
                }
            }
        }
    }

    //MARK: - IBActions
    @IBAction func onClose(_ sender: Any) {
        self.performSegueToReturnBack()
        self.tabBarController?.tabBar.isHidden = false
    }
    @IBAction func onDone(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: "Enter video name", preferredStyle: .alert)
        
        //2. Add the text field. You can configure it however you need.
        alert.addTextField { (textField) in
            textField.placeholder = "Enter video name"
        }
        
        // 3. Grab the value from the text field, and print it when the user clicks OK.
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0] // Force unwrapping because we know it exists.
            let videoName = (textField?.text?.isEmpty)! ? "untitled" : textField?.text
            
            let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
            spinnerActivity.label.text = "Uploading..."
            ////////////////////
            let type = self.videoEditingUrl.pathExtension
            do {
                let data = try Data(contentsOf: self.videoEditingUrl)
                let uid = Auth.auth().currentUser?.uid ?? ""
                let timestamp = Int64(Date().timeIntervalSince1970)
                let uploadUrl = "videos/\(uid)_\(timestamp).\(type)"
                let uploadThumbUrl = "videos/thumbs/\(uid)_\(timestamp).JPG"
                let videoRef = self.storageRef.child(uploadUrl)
                
                videoRef.putData(data, metadata: nil) { (metadata, error) in
                    guard metadata != nil else {
                        // Uh-oh, an error occurred!
                        Helper.showMessage(target: self, title: "", message: (error?.localizedDescription)!)
                        spinnerActivity.hide(animated: true)
                        return
                    }
                    // Metadata contains file metadata such as size, content-type, and download URL.
                    spinnerActivity.hide(animated: true)

                    self.performSegueToReturnBack()
                    self.tabBarController?.tabBar.isHidden = false
                }
                
                let image = VideoHelper.thumbnailFromVideo(videoUrl: self.videoEditingUrl, time: CMTimeMake(0, 1))
                let thumbRef  = self.storageRef.child(uploadThumbUrl)
                thumbRef.putData(UIImageJPEGRepresentation(image, 0.1)!, metadata: nil) { (metadata, error) in
                    guard metadata != nil else {
                        // Uh-oh, an error occurred!
                        Helper.showMessage(target: self, title: "", message: (error?.localizedDescription)!)
                        return
                    }
                    // Metadata contains file metadata such as size, content-type, and download URL.
                    let videoDuration = Int(VideoHelper.videoDuration(videoURL: self.videoEditingUrl))
                    let videoDBRef = self.ref.child("videos/\(uid)").childByAutoId()
                    videoDBRef.setValue(["video_name": videoName ?? "",
                                         "video_url": uploadUrl,
                                         "thumb_url": uploadThumbUrl,
                                         "duration": videoDuration])
                }
                
            } catch {
                print("Unable to load data: \(error)")
                spinnerActivity.hide(animated: true)
            }
        
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        // 4. Present the alert.
        self.present(alert, animated: true, completion: nil)

    }
    @IBAction func onPlayVideo(_ sender: Any) {
        self.player?.play()
    }
    
    @IBAction func onSoundBtn(_ sender: Any) {
        VideoHelper.removeAudioFromVideo(videoURL: self.videoEditingUrl){url in
            print("complete")
            self.btnSound.setBackgroundImage(UIImage(named: "btn_mute"), for: .normal)
            self.setVideo(with: url)
        }
    }
    
    @IBAction func onRefreshBtn(_ sender: Any) {
        self.btnSound.setBackgroundImage(UIImage(named: "btn_sound"), for: .normal)
        self.setVideo(with: self.videoUrl)
    }

    @IBAction func onCutBtn(_ sender: Any) {
        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Processing..."

        VideoHelper.trimVideo(sourceURL: self.videoEditingUrl, start: self.startTime, end: self.endTime){url in
            print("trim complete")
            self.setVideo(with: url)
            spinnerActivity.hide(animated: true)
        }
    }
    
    @IBAction func onCropBtn(_ sender: Any) {
        let firstImageFromVideo = VideoHelper.thumbnailFromVideo(videoUrl: self.videoEditingUrl, time: (player?.currentTime())!)
        let cropController = TOCropViewController(image: firstImageFromVideo)
        cropController.delegate = self
        cropController.toolbar.doneTextButton.setTitleColor(UIColor.init(rgb: 0xF5515F), for: .normal)
        cropController.toolbar.cancelTextButton.setTitleColor(UIColor.gray, for: .normal)
        self.present(cropController, animated: true, completion: nil)
    }
    
    private func setVideo(with url: URL){
        self.videoEditingUrl = url
        self.player = AVPlayer(url: self.videoEditingUrl)
        self.avpController.player = self.player
        self.videoRangeSlider.setVideoURL(videoURL: self.videoEditingUrl)
    }
    
    //MARK - Crop view controller delegate
    
    func cropViewController(_ cropViewController: TOCropViewController, didCropToRect cropRect: CGRect, angle: Int) {
        cropViewController.dismiss(animated: true, completion: nil)

        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Processing..."

        VideoHelper.cropVideo(self.videoEditingUrl, cropRect: cropRect){url in
            print("crop complete")
            self.videoEditingUrl = url
            self.player = AVPlayer(url: self.videoEditingUrl)
            self.avpController.player = self.player
            self.videoRangeSlider.setVideoURL(videoURL: self.videoEditingUrl)
            spinnerActivity.hide(animated: true)
        }
    }
    
    func cropViewController(_ cropViewController: TOCropViewController, didFinishCancelled cancelled: Bool) {
        cropViewController.dismiss(animated: true, completion: nil)
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
