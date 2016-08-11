//
//  videoExporter.swift
//  Test
//
//  Created by Tomas Calemczuk on 8/10/16.
//  Copyright © 2016 Tomi Calemczuk. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import MobileCoreServices
import Photos
import MediaPlayer



public class VideoExporter {
    
//    private static let HDVideoSize = CGSize(width: 1920.0, height: 1080.0)
    private static let HDVideoSize = CGSize(width: 750.0, height: 1334.0)
    
    private static var previewURL: NSURL?
    
    public static func exportVideo(videoURLs: [NSURL], videoPlayerLayer: AVPlayerLayer, videoPlayerLayer2: AVPlayerLayer) {
        
        var videoAssets = [AVAsset]()
        
        for url in videoURLs {
            let avAsset = AVAsset(URL: url)
            videoAssets.append(avAsset)
        }
        
        let composition = AVMutableComposition()
        
        let mainInstruction = AVMutableVideoCompositionInstruction()
        
        var startTime = kCMTimeZero
        
        for asset in videoAssets {
            // Insert Video
            let videoTrack = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
            
            do {
                try videoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration),
                                               ofTrack: asset.tracksWithMediaType(AVMediaTypeVideo)[0],
                                               atTime: startTime)
            } catch {
                print("Error creating track.")
            }

            let instruction = self.videoCompositionInstructionForTrack(videoTrack, asset: asset)
            
            instruction.setOpacity(1.0, atTime:startTime)
            if asset != videoAssets.last {
                instruction.setOpacity(0.0, atTime: CMTimeAdd(startTime, asset.duration))
            }
            mainInstruction.layerInstructions.append(instruction)
            
            startTime = CMTimeAdd(startTime, asset.duration)
        }
        
        let totalDuration = startTime

        mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration)
        let videoComposition = AVMutableVideoComposition()
        videoComposition.instructions = [mainInstruction]
        videoComposition.frameDuration = CMTimeMake(1, 30)
        videoComposition.renderSize = HDVideoSize
        videoComposition.renderScale = 1.0
        
        // Add overlays and animation
        self.applyEffectsToVideo(videoPlayerLayer, layer2: videoPlayerLayer2, composition: videoComposition, duration: totalDuration.seconds)
        
        // Export
        let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        exporter!.outputURL = self.uniqueURL()
        exporter!.outputFileType = AVFileTypeQuickTimeMovie
        exporter!.shouldOptimizeForNetworkUse = true
        exporter!.videoComposition = videoComposition
        
        exporter!.exportAsynchronouslyWithCompletionHandler() {
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.exportDidFinish(exporter!)
                print("Video was exported")
            })
        }
    }
    
    public static func exportDidFinish(session: AVAssetExportSession) {
        if session.status == AVAssetExportSessionStatus.Completed {
            let outputURL = session.outputURL
            let photoLibrary = PHPhotoLibrary.sharedPhotoLibrary()
            photoLibrary.performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(outputURL!)
            }) { (success: Bool, error: NSError?) -> Void in
                var alertTitle = ""
                var alertMessage = ""
                if success {
                    alertTitle = "Success!"
                    alertMessage = "Video files merged successfully!"
                    previewURL = session.outputURL
                } else {
                    alertTitle = "Error!"
                    alertMessage = "Video files merge failed!"
                    previewURL = nil
                }
                
                let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
                
//                dispatch_async(dispatch_get_main_queue(), { () -> Void in
//                    self.presentViewController(alert, animated: true, completion: nil)
//                })
            }
        }
    }
    
    public static func applyEffectsToVideo(layer1: AVPlayerLayer, layer2: AVPlayerLayer, composition: AVMutableVideoComposition, duration: CFTimeInterval) {
    
        
//        backgroundLayer.frame = CGRect(x: 0.0, y: 0.0, width: 250, height: 250)

        
    
        let parentLayer = CALayer()
        parentLayer.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        parentLayer.masksToBounds = true
        parentLayer.addSublayer(layer1)
        parentLayer.addSublayer(layer2)
        layer1.frame = CGRect(x: 0, y: 0, width: 100, height: 50)
        layer2.frame = CGRect(x: 0, y: 50, width: 100, height: 50)
        
        composition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: layer1, inLayer: parentLayer)
    }
    
    private static func videoCompositionInstructionForTrack(track: AVCompositionTrack, asset: AVAsset) -> AVMutableVideoCompositionLayerInstruction {
        
        let instruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track)
        let assetTrack = asset.tracksWithMediaType(AVMediaTypeVideo)[0]
        
        let transform = assetTrack.preferredTransform
        let assetInfo = orientationFromTransform(transform)
        var scaleToFitRatio = HDVideoSize.width / assetTrack.naturalSize.width
        
        if assetInfo.isPortrait {
            // Portrait
            scaleToFitRatio = HDVideoSize.height / assetTrack.naturalSize.width
            
            let scaleFactor = CGAffineTransformMakeScale(scaleToFitRatio, scaleToFitRatio)
            
            let concat = CGAffineTransformConcat(CGAffineTransformConcat(assetTrack.preferredTransform, scaleFactor), CGAffineTransformMakeTranslation((assetTrack.naturalSize.width * scaleToFitRatio) * 0.60, 0))
            
            instruction.setTransform(concat, atTime: kCMTimeZero)
        } else {
            // Landscape
            let scaleFactor = CGAffineTransformMakeScale(scaleToFitRatio, scaleToFitRatio)
            let concat = CGAffineTransformConcat(assetTrack.preferredTransform, scaleFactor)
            instruction.setTransform(concat, atTime: kCMTimeZero)
        }
        
        return instruction
    }
    
    private static func orientationFromTransform(transform: CGAffineTransform) -> (orientation: UIImageOrientation, isPortrait: Bool) {
        var assetOrientation = UIImageOrientation.Up
        var isPortrait = false
        if transform.a == 0 && transform.b == 1.0 && transform.c == -1.0 && transform.d == 0 {
            assetOrientation = .Right
            isPortrait = true
        } else if transform.a == 0 && transform.b == -1.0 && transform.c == 1.0 && transform.d == 0 {
            assetOrientation = .Left
            isPortrait = true
        } else if transform.a == 1.0 && transform.b == 0 && transform.c == 0 && transform.d == 1.0 {
            assetOrientation = .Up
        } else if transform.a == -1.0 && transform.b == 0 && transform.c == 0 && transform.d == -1.0 {
            assetOrientation = .Down
        }
        return (assetOrientation, isPortrait)
    }
    
    private static func uniqueURL() -> NSURL? {
        let directory = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as NSString
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateStyle = .LongStyle
        dateFormatter.timeStyle = .LongStyle
        let date = dateFormatter.stringFromDate(NSDate())
        
        let path = directory.stringByAppendingPathComponent("merge-\(date).mov")
        
        return NSURL.fileURLWithPath(path)
    }
}