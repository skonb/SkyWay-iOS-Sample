//
//  ChatViewController.swift
//  SwiftExample
//
//  Created by Dan Leonard on 5/11/16.
//  Copyright © 2016 MacMeDan. All rights reserved.
//
import UIKit
import AWSIoT
import SwiftyJSON
import JSQMessagesViewController

class ChatViewController: JSQMessagesViewController{
    var messages = [JSQMessage]()
    var incomingBubble: JSQMessagesBubbleImage!
    var outgoingBubble: JSQMessagesBubbleImage!
    var topic: String?
    let manager = AWSIoTDataManager(forKey: "default")
    var connected = false
    var myId: String?
 
    override func viewDidLoad() {
        super.viewDidLoad()
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        incomingBubble = bubbleFactory?.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
        outgoingBubble = bubbleFactory?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleGreen())

        senderId = ""
        senderDisplayName = ""
        
        view.backgroundColor =  UIColor.clear
        collectionView.backgroundColor = UIColor.clear
       
    }
    
    
    
    func endSubscription(){
        if let topic = topic{
            manager.unsubscribeTopic(topic)
        }
        topic = nil
    }
    
    
    func updateTopic(topic: String){
        endSubscription()
        self.topic = topic
    }
    
    func connect(withId id: String){
        myId = id;
        manager.connectUsingWebSocket(withClientId: id, cleanSession: true) {[weak self] (status) in
            switch(status){
            case .connected:
                self?.connected = true
                break
            case .disconnected:
                self?.connected = false
                break
            default:
                break
            }
        }
    }
    
    
    func startSubscription(){
        if(connected){
            manager.subscribe(toTopic: topic!, qoS: .messageDeliveryAttemptedAtMostOnce, messageCallback: { [weak self](data) in
                let json = JSON(data: data)
                if json["from"] != nil && json["message"] != nil{
                    let message = JSQMessage(senderId: json["from"].string, displayName: "", text: json["message"].string)
                    self?.messages.append(message!)
                    self?.finishReceivingMessage(animated: true)
                }
                
            })
        }
    }
    
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        if(connected){
            let json: JSON = ["from": myId!, "message": text]
            
            manager.publishString(json.rawString()!, onTopic: topic!, qoS: .messageDeliveryAttemptedAtMostOnce)
            finishSendingMessage()
        }
    }
    
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.item]
        if message.senderId == self.senderId {
            return self.outgoingBubble
        }
        return self.incomingBubble
    }
    
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    
    deinit{
        if let t = topic{
            manager.unsubscribeTopic(t)
        }
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return JSQMessagesAvatarImage(placeholder: UIImage(named: "image"))
    }
}
