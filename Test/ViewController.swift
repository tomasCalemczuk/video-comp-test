//
//  ViewController.swift
//  Test
//
//  Created by Tomas Calemczuk on 7/8/16.
//  Copyright © 2016 Tomi Calemczuk. All rights reserved.
//

import UIKit
import AVFoundation
import ReplayKit

class ViewController: UIViewController {
    
    var player: AVPlayer!
    var player2: AVPlayer!
    
    var playerItem: AVPlayerItem!
    var playerItem2: AVPlayerItem!
    
    var playerLayer = AVPlayerLayer()
    var playerLayer2 = AVPlayerLayer()
    
    var videoURLarray = [NSURL]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // For video 1
        var URL = NSURL(string: "https://s3-us-west-2.amazonaws.com/reaction-app-videos/otros/IMG_6698.MOV")!
        var asset = AVAsset(URL: URL)
        playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.frame
        playerLayer.position = CGPoint(x: 187, y: 150)
        view.layer.addSublayer(playerLayer)
        videoURLarray.append(URL)
        player.play()

        // For video 2
        URL = NSURL(string: "https://s3-us-west-2.amazonaws.com/reaction-app-videos/otros/IMG_6698.MOV")!
        asset = AVAsset(URL: URL)
        playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.frame
        view.layer.addSublayer(playerLayer)
        videoURLarray.append(URL)
        player.play()
        
        print(videoURLarray)
    }
    
    @IBAction func saveVideos(sender: AnyObject) {
        VideoExporter.exportVideo(videoURLarray, videoPlayerLayer: playerLayer, videoPlayerLayer2: playerLayer2)
    }
    
    
}
    
