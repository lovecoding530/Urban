//
//  TrainerVideosVC.swift
//  Urban
//
//  Created by Kangtle on 8/26/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import MobileCoreServices
import AVFoundation
import AVKit

struct Video {
    var name: String
    var url: String
    var thumbUrl: String
    var duration: Int
}

class TrainerVideosVC: UIViewController,
                       UIImagePickerControllerDelegate, UINavigationControllerDelegate,
                       UITableViewDelegate, UITableViewDataSource,
                       UIVideoEditorControllerDelegate {
    var imagePicker = UIImagePickerController()
    let storageRef = Storage.storage().reference()
    var ref = Database.database().reference()

    var videos = [[String: Any]]()
    var isLoaded = false
    
    @IBOutlet weak var videosTable: UITableView!
    
    var onDoneBlock: ((String, String) -> Void)? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        if onDoneBlock == nil {
            self.navigationItem.leftBarButtonItem = nil
        }
        
        imagePicker.delegate = self

        getVideos()
        // Do any additional setup after loading the view.
    }
    
    func getVideos(){
        let spinnerActivity = MBProgressHUD.showAdded(to: self.view, animated: true)
        spinnerActivity.label.text = "Please wait..."

        let uid = Auth.auth().currentUser?.uid ?? ""
        let videosRef = ref.child("videos/\(uid)")
        videosRef.observe(.value, with: {(snapshot) in
            let videosDic = snapshot.value as? [String: Any] ?? [:]
            self.videos = Array(videosDic.values) as! [[String : Any]]
            self.videosTable.reloadData()
            
            if !self.isLoaded {
                self.isLoaded = true
                spinnerActivity.hide(animated: true)
            }
        })
    }
    @IBAction func onBack(_ sender: Any) {
        self.performSegueToReturnBack()
    }

    @IBAction func onPressedAdd(_ sender: Any) {
#if (arch(i386) || arch(x86_64)) && os(iOS)
        self.imagePicker.allowsEditing = false
        self.imagePicker.sourceType = .photoLibrary
        self.imagePicker.mediaTypes = [String(kUTTypeMovie)]
        self.present(self.imagePicker, animated: true, completion: nil)
#else
        if(UIImagePickerController.isSourceTypeAvailable(.camera)){
            self.imagePicker.allowsEditing = false
            self.imagePicker.sourceType = .camera
//            self.imagePicker.cameraCaptureMode = .video
            self.imagePicker.mediaTypes = [String(kUTTypeMovie)]
            self.present(self.imagePicker, animated: true, completion: nil)
        }else{
            Helper.showMessage(target: self, title: "", message: "This device is no camera")
        }
#endif
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        picker.dismiss(animated: false, completion: nil)

        if let url = info[UIImagePickerControllerMediaURL] as? URL {
            let videoEditVC = UIStoryboard(name: "Main", bundle: nil)
                              .instantiateViewController(withIdentifier: "VideoEditVC") as! VideoEditVC
            videoEditVC.videoUrl = url
            self.present(videoEditVC, animated: true, completion: nil)
            return
        }
    }
    
    // MARK: TableView
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! VideoTableViewCell
        let video = videos[indexPath.row]
        let videoName = video["video_name"] as! String
        let videoThumbUrl = video["thumb_url"] as! String
        let videoDuration = video["duration"] as! Int
        let min = Int(videoDuration / 60)
        let sec = videoDuration % 60
        let durationStr = "Duration: \(String(format: "%02d", min)):\(String(format: "%02d", sec))"
        cell.videoNameLabel.text = videoName
        cell.videoDurationLabel.text = durationStr
        
        let reference = storageRef.child(videoThumbUrl)
        let placeholderImage = UIImage(named: "placeholder_fitness.png")
        cell.videoThumbView.sd_setImage(with: reference, placeholderImage: placeholderImage)

        cell.backgroundColor = UIColor.clear
        return cell
    }
    
//    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
//        let cell = tableView.cellForRow(at: indexPath)
//        cell?.backgroundColor = UIColor.init(rgb: 0x2D2E40).withAlphaComponent(0.8)
//        return indexPath
//    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let video = videos[indexPath.row]
        let videoUrl = video["video_url"] as! String
        let videoThumbUrl = video["thumb_url"] as! String
        if onDoneBlock != nil {

            onDoneBlock!(videoUrl, videoThumbUrl)
            return

        }else{
            
            let avpController = AVPlayerViewController()
            
            storageRef.child(videoUrl).downloadURL(){  url, error in
                if error == nil {
                    let player = AVPlayer(url: url!)
                    avpController.player = player
                    self.present(avpController, animated: true, completion: nil)
                }
            }
            
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
    }

}
