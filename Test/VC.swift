//
//  VC.swift
//  Test
//
//  Created by Jesse Tipton on 8/11/16.
//  Copyright © 2016 Tomi Calemczuk. All rights reserved.
//

import AVFoundation
import AVKit
import UIKit

class ViewController: UIViewController {
    
    var player: AVPlayer!
    var playerLayer: AVPlayerLayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let videoAsset = AVAsset(URL: NSURL(string: "https://s3-us-west-2.amazonaws.com/reaction-app-videos/Penalty/IMG_6251.MOV")!)
        let reactionAsset = AVAsset(URL: NSURL(string: "https://s3-us-west-2.amazonaws.com/reaction-app-videos/otros/IMG_6698.MOV")!)
        
        let mixComposition = AVMutableComposition()
        
        let videoTrack = videoAsset.tracksWithMediaType(AVMediaTypeVideo)[0]
        let mutableVideoTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: 100)
        try! mutableVideoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAsset.duration), ofTrack: videoTrack, atTime: kCMTimeZero)
        
        let reactionTrack = reactionAsset.tracksWithMediaType(AVMediaTypeVideo)[0]
        let mutableReactionTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: 200)
        try! mutableReactionTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, reactionAsset.duration), ofTrack: reactionTrack, atTime: kCMTimeZero)

        let instruction = AVMutableVideoCompositionInstruction()
        
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: mutableVideoTrack)
        layerInstruction.setTransform(mutableVideoTrack.preferredTransform, atTime: kCMTimeZero)
        
        let layer2Instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: mutableReactionTrack)
        layerInstruction.setTransform(CGAffineTransformTranslate(CGAffineTransformMakeScale(0.5, 0.5), 320, 180), atTime: kCMTimeZero)
        
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoTrack.timeRange.duration)
        instruction.layerInstructions = [layerInstruction, layer2Instruction]
        
        let composition = AVMutableVideoComposition()
        composition.renderSize = videoTrack.naturalSize
        composition.frameDuration = CMTimeMake(1, 30)
        composition.instructions = [instruction]
        
        
        let playerItem = AVPlayerItem(asset: mixComposition)
        playerItem.videoComposition = composition
        
        player = AVPlayer(playerItem: playerItem)

        playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = view.layer.bounds
        view.layer.addSublayer(playerLayer)
        
        player.play()
    }
    
}
