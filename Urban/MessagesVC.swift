//
//  MessagesVC.swift
//  Urban
//
//  Created by Kangtle on 8/9/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage
import FirebaseStorageUI

class MessagesVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var ref = Database.database().reference()
    let storageRef = Storage.storage().reference()

    var isTrainer = true
    
    var chatChannels = [ChatChannel]()
    let userDefaults = UserDefaults.standard
    
    @IBOutlet weak var chatChannelTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
        
        isTrainer = userDefaults.bool(forKey: "is_trainer")
        
        if isTrainer {
            self.navigationItem.rightBarButtonItem = nil
        }
        // Do any additional setup after loading the view.
        chatChannelTable.delegate = self
        chatChannelTable.dataSource = self
        getChatChannels()
    }

    override func viewWillAppear(_ animated: Bool) {
        self.chatChannels.sort{$0.lastMessage.time > $1.lastMessage.time}
        chatChannelTable.reloadData()
    }
    
    func getChatChannels(){
        
        let uid = Auth.auth().currentUser?.uid ?? ""

        let userChatChannelsRef = ref.child("user_chat_channels/\(uid)")
        userChatChannelsRef.observe(.childAdded, with: {(snapshot) in
            let channel = snapshot.key
//                print(channel)
            let mChatChannel = ChatChannel.init(channelId: channel)
            
            let opponentUid = channel.replacingOccurrences(of: uid, with: "").replacingOccurrences(of: "_", with: "")
//                print(opponentUid)
            
            let opponentRef: DatabaseReference
            if self.isTrainer {
                opponentRef = self.ref.child("clients/\(opponentUid)")
            }else{
                opponentRef = self.ref.child("trainers/\(opponentUid)")
            }
            let group = DispatchGroup()
            group.enter()
            opponentRef.observeSingleEvent(of: .value, with: {(snapshot) in
                let _opponent = snapshot.value as? [String: Any] ?? [:]
                let mOpponent = Opponent(withDic: _opponent)
                mOpponent.id = opponentUid
                mChatChannel.opponent = mOpponent
                group.leave()
            })
            
            let channelRef = self.ref.child("chat_channels/\(channel)")
            group.enter()
            channelRef.observeSingleEvent(of: .childAdded, with: {(snapshot) in
                let _message = snapshot.value as? [String : Any] ?? [:]
                let mMessage = Message.init(withDic: _message)
                mMessage.message = mMessage.message.replacingOccurrences(of: "\n", with: " ")
                mChatChannel.lastMessage = mMessage
                group.leave()
            })

            group.notify(queue: .main){
                print("sort test")
                self.chatChannels.append(mChatChannel)
                self.chatChannels.sort{$0.lastMessage.time > $1.lastMessage.time}
                self.chatChannelTable.reloadData()
            }

            channelRef.observe(.childChanged, with: {(snapshot) in
                let _message = snapshot.value as? [String : Any] ?? [:]
                let mMessage = Message.init(withDic: _message)
                mMessage.message = mMessage.message.replacingOccurrences(of: "\n", with: " ")
                mChatChannel.lastMessage = mMessage
                self.chatChannels.sort{$0.lastMessage.time > $1.lastMessage.time}
                self.chatChannelTable.reloadData()
            })
            
        })
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatChannels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatChannelCell", for: indexPath) as! ChatChannelCell
        
        let channel = chatChannels[indexPath.row]
        //        cell.gymImageView.image = history.gym.thumb
        cell.opponentNameLabel.text = channel.opponent.name
        cell.lastMessageLabel.text = channel.lastMessage.message
        
        let reference = storageRef.child(channel.opponent.photoUrl)
        let placeholderImage = UIImage(named: "placeholder_user.png")
        cell.opponentImageView.sd_setImage(with: reference, placeholderImage: placeholderImage)
        channel.opponent.photo = cell.opponentImageView.image
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm a, d MMM"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        
        var lastMessageTimeStr = ""
        
        let diff = Int64(Date().timeIntervalSince1970)-channel.lastMessage.timestamp
        
        if diff < 2 * 60 {//2min
            lastMessageTimeStr = "Just now"
            cell.myImageView.isHidden = true
            cell.justNowImageView.isHidden = false
            cell.lastMessageLabel.frame.origin.x = 80
        }else if diff < 60 * 60 { //1h
            lastMessageTimeStr = "\(Int(diff / 60))min ago"
        }else if diff < 12 * 60 * 60 { //12
            lastMessageTimeStr = "\(Int(diff / 3600))h ago"
        }else{
            lastMessageTimeStr = dateFormatter.string(from: channel.lastMessage.time)
        }
        
        cell.lastMessageTimeLabel.text = lastMessageTimeStr

        if channel.opponent.id != channel.lastMessage.senderId {
            cell.myImageView.image = APPDELEGATE.currenntUser.photo

            cell.myImageView.isHidden = false
            cell.justNowImageView.isHidden = true
            cell.lastMessageLabel.frame.origin.x = 105
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cell.backgroundColor = UIColor.clear
    }
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = UIColor.init(rgb: 0x2D2E40).withAlphaComponent(0.8)
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, willDeselectRowAt indexPath: IndexPath) -> IndexPath? {
        let cell = tableView.cellForRow(at: indexPath)
        cell?.backgroundColor = UIColor.clear
        return indexPath
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let chatVC = ChatVC()
        chatVC.channel = chatChannels[indexPath.row]
//        chatVC.messages = makeNormalConversation()
        let chatNavigationController = UINavigationController(rootViewController: chatVC)
        present(chatNavigationController, animated: true, completion: nil)
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
