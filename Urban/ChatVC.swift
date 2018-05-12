//
//  ChatVC.swift
//  Urban
//
//  Created by Kangtle on 8/19/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import IQKeyboardManagerSwift
import Firebase

class ChatVC: JSQMessagesViewController {

    var ref = Database.database().reference()

    var channel: ChatChannel!
    var messages = [JSQMessage]()
    let defaults = UserDefaults.standard
    var incomingBubble: JSQMessagesBubbleImage!
    var outgoingBubble: JSQMessagesBubbleImage!
    fileprivate var displayName: String!
    
    var avatarOpponent: JSQMessagesAvatarImage!
    
    var avatarMe: JSQMessagesAvatarImage!
    
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.statusBarStyle = .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        IQKeyboardManager.sharedManager().enable = false
        self.navigationController?.navigationBar.barTintColor = UIColor.init(rgb: 0x1C1D2E)
        self.navigationController?.navigationBar.tintColor = UIColor.white
        self.navigationItem.title = channel.opponent.name
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]

        avatarMe = JSQMessagesAvatarImageFactory().avatarImage(withPlaceholder: APPDELEGATE.currenntUser.photo)
        avatarOpponent = JSQMessagesAvatarImageFactory().avatarImage(withPlaceholder: channel.opponent.photo)
        getMessages()
        // Setup navigation
        setupButtons()

        let imgBackground:UIImageView = UIImageView(frame: self.view.bounds)
        imgBackground.image = UIImage(named: "bg_clear")
        imgBackground.contentMode = UIViewContentMode.scaleAspectFill
        imgBackground.clipsToBounds = true
        self.collectionView?.backgroundView = imgBackground
        
        incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor.white)
        outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.init(rgb: 0xF5515F))
        
        collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize(width: kJSQMessagesCollectionViewAvatarSizeDefault, height:kJSQMessagesCollectionViewAvatarSizeDefault )
        collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: kJSQMessagesCollectionViewAvatarSizeDefault, height:kJSQMessagesCollectionViewAvatarSizeDefault )
        
        // This is a beta feature that mostly works but to make things more stable it is diabled.
        collectionView?.collectionViewLayout.springinessEnabled = false
        
        automaticallyScrollsToMostRecentMessage = true
        
        self.collectionView?.reloadData()
        self.collectionView?.layoutIfNeeded()
        
    }
    
    func getMessages(){
        let messageRef = ref.child("chat_messages/\(channel.id ?? "")").queryLimited(toFirst: 20)
        messageRef.observe(.childAdded, with: {(snapshot) in
            let messageDic = snapshot.value as! [String : Any]
            let mMessage = Message(withDic: messageDic)
            let message = JSQMessage(senderId: mMessage.senderId, senderDisplayName: "", date: mMessage.time, text: mMessage.message)
            self.messages.append(message)
            self.finishSendingMessage(animated: true)
        })
    }
    
    func setupButtons() {
        let backButton = UIBarButtonItem(image: UIImage(named: "btn_back"), style: .plain, target: self, action: #selector(backButtonTapped))
        navigationItem.leftBarButtonItem = backButton

        let avatarImageView = UIImageView(image: channel.opponent.photo)
        avatarImageView.frame = CGRect(x: 0, y: 0, width: 44, height: 44)
        avatarImageView.layer.cornerRadius = 22
        avatarImageView.clipsToBounds = true
        let rightBarItem = UIBarButtonItem(customView: avatarImageView)
        rightBarItem.action = #selector(opponentAvatarImageTapped)
        self.navigationItem.rightBarButtonItem = rightBarItem

        
        //inputToolBar
        self.inputToolbar.contentView?.leftBarButtonItem = nil //Left Button
        
        let rightButton = UIButton(frame: CGRect.zero)
        let sendImage = UIImage(named: "btn_message_send.png")
        rightButton.setImage(sendImage, for: .normal)
        rightButton.frame = CGRect(x: 0, y: 0, width: 30, height: 0)
        self.inputToolbar.contentView?.rightContentPadding = CGFloat(0)
        
        self.inputToolbar.contentView?.rightBarButtonItem = rightButton
    }
    func backButtonTapped() {
        dismiss(animated: true, completion: nil)
        IQKeyboardManager.sharedManager().enable = true
    }
    
    func opponentAvatarImageTapped(_ sender: UIBarButtonItem) {
    }
    
    
    // MARK: JSQMessagesViewController method overrides
    override func didPressSend(_ button: UIButton, withMessageText text: String, senderId: String, senderDisplayName: String, date: Date) {
        /**
         *  Sending a message. Your implementation of this method should do *at least* the following:
         *
         *  1. Play sound (optional)
         *  2. Add new id<JSQMessageData> object to your data source
         *  3. Call `finishSendingMessage`
         */
        let timestamp = Int64(date.timeIntervalSince1970)
        let messageRef = ref.child("chat_messages/\(channel.id ?? "")/\(timestamp)")
        let message = [
            "message" : text,
            "sender" : Auth.auth().currentUser?.uid ?? "",
            "time" : timestamp
        ] as [String : Any]
        messageRef.setValue(message)
        let channelRef = ref.child("chat_channels/\(channel.id ?? "")/last_message")
        channelRef.setValue(message)
        ref.child("user_chat_channels/\(Auth.auth().currentUser?.uid ?? "")/\(channel.id ?? "")").setValue(true)
        ref.child("user_chat_channels/\(channel.opponent.id ?? "")/\(channel.id ?? "")").setValue(true)
    }
    
    //MARK: JSQMessages CollectionView DataSource
    
    override func senderId() -> String {
        return (Auth.auth().currentUser?.uid)!
    }
    
    override func senderDisplayName() -> String {
        return (Auth.auth().currentUser?.displayName ?? "")!
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, messageDataForItemAt indexPath: IndexPath) -> JSQMessageData {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, messageBubbleImageDataForItemAt indexPath: IndexPath) -> JSQMessageBubbleImageDataSource {
        
        return messages[indexPath.item].senderId == self.senderId() ? outgoingBubble : incomingBubble
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, avatarImageDataForItemAt indexPath: IndexPath) -> JSQMessageAvatarImageDataSource? {
        return messages[indexPath.item].senderId == self.senderId() ? avatarMe : avatarOpponent
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView, attributedTextForCellTopLabelAt indexPath: IndexPath) -> NSAttributedString? {
        /**
         *  This logic should be consistent with what you return from `heightForCellTopLabelAtIndexPath:`
         *  The other label text delegate methods should follow a similar pattern.
         *
         *  Show a timestamp for every 3rd message
         */
        
        if (indexPath.item % 3 == 0) {
            let message = self.messages[indexPath.item]
            
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.date)
        }
        
        return nil
    }
        
    override func collectionView(_ collectionView: JSQMessagesCollectionView, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout, heightForCellTopLabelAt indexPath: IndexPath) -> CGFloat {
        /**
         *  Each label in a cell has a `height` delegate method that corresponds to its text dataSource method
         */
        
        /**
         *  This logic should be consistent with what you return from `attributedTextForCellTopLabelAtIndexPath:`
         *  The other label height delegate methods should follow similarly
         *
         *  Show a timestamp for every 3rd message
         */
        if indexPath.item % 3 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        return 0.0
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let _cell = cell as! JSQMessagesCollectionViewCell
        if messages[indexPath.item].senderId == self.senderId() {
            if let textView = _cell.textView {
                textView.textColor = UIColor.white
            }
        }
        else {
            if let textView = _cell.textView {
                textView.textColor = UIColor(rgb: 0x2D2E40)
            }
        }
    }
}
