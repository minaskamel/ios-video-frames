//
//  VideoFramesManager.swift
//  ios-video-frames
//

import UIKit
import AVFoundation

protocol VideoFramesManagerDelegate {
    func videoFramesAreReady(_ images : [UIImage])
}

class VideoFramesManager {
    
    static let instance = VideoFramesManager()
    var delegate : VideoFramesManagerDelegate?
    var asset : AVURLAsset!
    
    func extractVideoFrames(asset : AVURLAsset) {
        self.asset = asset
        DispatchQueue.main.async {
            self.delegate?.videoFramesAreReady(self.generateFramesPhotos())
        }
    }
    
    func generateFramesPhotos() -> [UIImage] {
        var images = [UIImage]()
        
        let videoDurationInSeconds = Int(asset.duration.value) / Int(asset.duration.timescale)
        let assetImgGenerate : AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        assetImgGenerate.requestedTimeToleranceAfter = kCMTimeZero;
        assetImgGenerate.requestedTimeToleranceBefore = kCMTimeZero;
        assetImgGenerate.maximumSize = CGSize(width: 65, height: 40);
        
        
        var currentSecond = 0.0
        
        for _ in 0..<videoDurationInSeconds {
            do {
                let img : CGImage = try assetImgGenerate.copyCGImage(at: CMTimeMakeWithSeconds(currentSecond, 600), actualTime: nil)
                images.append(UIImage(cgImage: img))
                currentSecond += 1
            } catch {
            }
        }
        return images
    }
    
}
