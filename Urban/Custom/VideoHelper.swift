//
//  VideoHelper.swift
//  Urban
//
//  Created by Kangtle on 9/5/17.
//  Copyright © 2017 Kangtle. All rights reserved.
//

import Foundation
import AVKit
import AVFoundation
import MobileCoreServices

class VideoHelper {
    static func thumbnailFromVideo(videoUrl: URL, time: CMTime) -> UIImage{
        let asset: AVAsset = AVAsset(url: videoUrl) as AVAsset
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        imgGenerator.appliesPreferredTrackTransform = true
        do{
            let cgImage = try imgGenerator.copyCGImage(at: time, actualTime: nil)
            let uiImage = UIImage(cgImage: cgImage)
            return uiImage
        }catch{
            
        }
        return UIImage()
    }
    
    static func videoDuration(videoURL: URL) -> Float64{
        let source = AVURLAsset(url: videoURL)
        return CMTimeGetSeconds(source.duration)
    }
    
    static func removeAudioFromVideo(videoURL: URL, completion: ((_ url: URL)->())?=nil) {
        let temPath = URL.init(fileURLWithPath: NSTemporaryDirectory())
        let outputURL = temPath.appendingPathComponent("video_edit_temp.mov")
        
        let composition = AVMutableComposition()

        let sourceAsset = AVURLAsset(url: videoURL, options: nil)
        let compositionVideoTrack: AVMutableCompositionTrack? = composition.addMutableTrack(withMediaType: AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        let sourceVideoTrack: AVAssetTrack? = sourceAsset.tracks(withMediaType: AVMediaTypeVideo)[0]

        compositionVideoTrack?.preferredTransform = (sourceVideoTrack?.preferredTransform)! //video orientation
        
        let x: CMTimeRange = CMTimeRangeMake(kCMTimeZero, sourceAsset.duration)
        _ = try? compositionVideoTrack!.insertTimeRange(x, of: sourceVideoTrack!, at: kCMTimeZero)
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(atPath: outputURL.path)
        }
        let exporter = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality)
        exporter?.outputURL = outputURL
        exporter?.outputFileType = AVFileTypeQuickTimeMovie
        exporter?.exportAsynchronously(completionHandler: {() -> Void in
            DispatchQueue.main.async {
                if completion != nil {
                    completion!(outputURL)
                }
            }
        })
        
    }
    
    static func saveFinalVideoFile(toDocument url: URL) {
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("Videos")
        let movieData = try? Data(contentsOf: url)
        try? movieData?.write(to: fileURL, options: .atomic)
    }
    
    static func trimVideo(sourceURL: URL, start:Double, end:Double, completion: ((_ url: URL)->())?=nil) {
        let manager = FileManager.default
        
        let asset = AVAsset(url: sourceURL)
        let length = Float(asset.duration.value) / Float(asset.duration.timescale)
        print("video length: \(length) seconds")
        
        let temPath = URL.init(fileURLWithPath: NSTemporaryDirectory())
        let outputURL = temPath.appendingPathComponent("video_edit_temp.mov")

        
        //Remove existing file
        try? manager.removeItem(at: outputURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {return}
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileTypeQuickTimeMovie
        
        let startTime = CMTime(seconds: start, preferredTimescale: 1000)
        let endTime = CMTime(seconds: end, preferredTimescale: 1000)
        let timeRange = CMTimeRange(start: startTime, end: endTime)

        exportSession.timeRange = timeRange
        exportSession.exportAsynchronously{
            switch exportSession.status {
            case .completed:
                print("exported at \(outputURL)")
                break
            case .failed:
                print("failed \(exportSession.error?.localizedDescription ?? "")")
                break
            case .cancelled:
                print("cancelled \(exportSession.error?.localizedDescription ?? "")")
                break
            default: break
            }
            
            DispatchQueue.main.async {
                if completion != nil {
                    completion!(outputURL)
                }
            }
        }
    }
    
    static func cropVideo( _ outputFileUrl: URL, cropRect: CGRect, completion: ((_ url: URL)->())?=nil)
    {
        let asset = AVAsset( url: outputFileUrl )
        let videoTrack = asset.tracks(withMediaType: AVMediaTypeVideo).first
        
        let assetComposition = AVMutableComposition()
        let trackTimeRange = CMTimeRangeMake(kCMTimeZero, asset.duration)
        
        let videoCompositionTrack = assetComposition.addMutableTrack(withMediaType: AVMediaTypeVideo,
                                                                     preferredTrackID: kCMPersistentTrackID_Invalid)
        try? videoCompositionTrack.insertTimeRange(trackTimeRange, of: videoTrack!, at: kCMTimeZero)
//        videoCompositionTrack.preferredTransform = (videoTrack?.preferredTransform)! //video orientation

        if let audioTrack = asset.tracks(withMediaType: AVMediaTypeAudio).first {
            let audioCompositionTrack = assetComposition.addMutableTrack(withMediaType: AVMediaTypeAudio,
                                                                         preferredTrackID: kCMPersistentTrackID_Invalid)
            try? audioCompositionTrack.insertTimeRange(trackTimeRange, of: audioTrack, at: kCMTimeZero)
        }
        
        //1. Create the instructions
        let mainInstructions = AVMutableVideoCompositionInstruction()
        mainInstructions.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration)
        //2 add the layer instructions
        let layerInstructions = AVMutableVideoCompositionLayerInstruction(assetTrack: videoCompositionTrack)
        
        let renderSize = CGSize(width: Int(cropRect.size.width/4)*4, height: Int(cropRect.size.height/4)*4) // avoiding green line
        
        let rotation = atan2((videoTrack?.preferredTransform.b)!, (videoTrack?.preferredTransform.a)!)
        var rotationOffset = CGPoint(x: 0, y: 0)
        if videoTrack?.preferredTransform.b == -1.0 {
            rotationOffset.y = (videoTrack?.naturalSize.width)!
        } else if videoTrack?.preferredTransform.c == -1.0 {
            rotationOffset.x = (videoTrack?.naturalSize.height)!
        } else if videoTrack?.preferredTransform.a == -1.0 {
            rotationOffset.x = (videoTrack?.naturalSize.width)!
            rotationOffset.y = (videoTrack?.naturalSize.height)!
        }
        var transform = CGAffineTransform.identity
        transform = transform.translatedBy(x: -cropRect.origin.x + rotationOffset.x, y: -cropRect.origin.y + rotationOffset.y)
        transform = transform.rotated(by: rotation)

        layerInstructions.setTransform(transform, at: kCMTimeZero)
        layerInstructions.setOpacity(1.0, at: kCMTimeZero)
        mainInstructions.layerInstructions = [layerInstructions]
        
        //3 Create the main composition and add the instructions
        
        let videoComposition = AVMutableVideoComposition()
        videoComposition.renderSize = renderSize
        videoComposition.instructions = [mainInstructions]
        videoComposition.frameDuration = CMTimeMake(1, 30)
        
        let temPath = URL.init(fileURLWithPath: NSTemporaryDirectory())
        let outputURL = temPath.appendingPathComponent("video_edit_temp.mov")
        try? FileManager.default.removeItem(at: outputURL)
        
        let exportSession = AVAssetExportSession(asset: assetComposition, presetName: AVAssetExportPresetHighestQuality)!
        exportSession.outputFileType = AVFileTypeQuickTimeMovie
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.videoComposition = videoComposition
        exportSession.outputURL = outputURL
        exportSession.exportAsynchronously(completionHandler: {
            switch exportSession.status {
            case .completed:
                print("exported at \(outputURL)")
                break
            case .failed:
                print("failed \(exportSession.error?.localizedDescription ?? "")")
                break
            case .cancelled:
                print("cancelled \(exportSession.error?.localizedDescription ?? "")")
                break
            default: break
            }
            DispatchQueue.main.async {
                if completion != nil {
                    completion!(outputURL)
                }
            }
        })
    }
}
