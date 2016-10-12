//
//  ViewController.swift
//  ios-video-frames
//
//

import UIKit
import AVFoundation

enum PlayState {
    case play, pause
}

class ViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet var videoView: UIView!
    @IBOutlet var framesScrollView: UIScrollView!
    @IBOutlet var playButton: UIButton!
    @IBOutlet var elapsedTimeLabel: UILabel!
    @IBOutlet var remainingTimeLabel: UILabel!
    
    //MARK: - Attributes
    var playerItem : AVPlayerItem!
    var player : AVPlayer!
    var playState : PlayState = .pause
    var timer : Timer?
    let timerStep = 0.1
    var shownFramesImagesCount : Int!
    let frameImageWidth : CGFloat = 65
    let frameImageHeight : CGFloat = 40
    
    //MARK: - Init
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initViews()
    
        DispatchQueue.main.async {
            self.loadVideo()
            self.adjustControls()
            self.adjustVideoFrames()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.playerDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
        
        UIUtils.instance.showPorgressHudWithMessage("Preparing Video", view: self.view)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        player.pause()
    }
    
    func initViews() {
        playButton.isEnabled = false
        elapsedTimeLabel.text = "00:00"
        remainingTimeLabel.text = "00:00"
    }
    
    func loadVideo() {
        playerItem = getPlayerItem()
        player = AVPlayer(playerItem: playerItem)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = videoView.bounds
        videoView.layer.addSublayer(playerLayer)
        videoView.layoutSubviews()
    }
    
    func adjustControls() {
        playButton.isEnabled = true
        elapsedTimeLabel.text = timeFormat(0)
        remainingTimeLabel.text = "-" + timeFormat(Int64(getVideoDuration()))
    }
    
    func adjustVideoFrames() {
        let currentPlayerAsset = player.currentItem?.asset
        if currentPlayerAsset is AVURLAsset {
            VideoFramesManager.instance.delegate = self
            VideoFramesManager.instance.extractVideoFrames(asset: currentPlayerAsset as! AVURLAsset)
        }
    }
    
    //MARK: - Play methods
    @IBAction func playButtonTapped(_ sender: AnyObject) {
        switch playState {
        case .play:
            pause()
            break
        case .pause:
            play()
            break
        }
    }
    
    func play() {
        playButton.setTitle("Pause", for: UIControlState())
        playState = .play
        player.play()
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: timerStep, target: self, selector: #selector(ViewController.updateTime(_:)), userInfo: nil, repeats: true)
        timer!.fire()
    }
    
    func pause() {
        timer?.invalidate()
        
        playButton.setTitle("Play", for: UIControlState())
        playState = .pause
        player.pause()
    }
    
    func updateTime(_ isScrolling : Bool) {
        let currentTime = getVideoCurrentTime()
        let videoDuration = getVideoDuration()
        let remaining = Int(videoDuration) - Int(currentTime)
        elapsedTimeLabel.text = timeFormat(Int64(currentTime))
        remainingTimeLabel.text = "-" + timeFormat(Int64(remaining))
        if (!isScrolling) {
            DispatchQueue.main.async {
                self.changeScrollViewOffsetXPosition(byOffset: CGFloat(self.timerStep))
            }
        }
    }
    
    func updateVideoPlayerAfterScrolling(_ timeToSeek : Double) {
        let videoDuration = Double(getVideoDuration())
        let newTime = timeToSeek < videoDuration ? timeToSeek : videoDuration
        let timeScale = player.currentItem?.asset.duration.timescale ?? 60000
        
        player.isMuted = true
        player.seek(to: CMTime(seconds: newTime, preferredTimescale: timeScale), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero, completionHandler: { (finished) in
            if finished {
                self.updateTime(true)
                self.player.isMuted = false
            }
        })
    }
    
    func playerDidFinishPlaying() {
        pause()
    }
    
    //MARK: - Frames Scroll View
    func changeScrollViewOffsetXPosition(byOffset offset : CGFloat)  {
        let currentOffset = self.framesScrollView.contentOffset
        var newXPosition = currentOffset.x + (self.frameImageWidth * offset)
        newXPosition = max(0, min(newXPosition , CGFloat(self.shownFramesImagesCount) * self.frameImageWidth))
        let newOffset = CGPoint(x: newXPosition , y: currentOffset.y)
        self.framesScrollView.delegate = nil
        self.framesScrollView.setContentOffset(newOffset, animated: false)
        self.framesScrollView.delegate = self
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset
        updateVideoPlayerAfterScrolling(Double(currentOffset.x / frameImageWidth))
    }
    
    //MARK: - Helper methods
    func getPlayerItem() -> AVPlayerItem {
        let videoUrl = URL(fileURLWithPath: Bundle.main.path(forResource: "video", ofType: "mp4")!)
        return AVPlayerItem(url: videoUrl)
    }
    
    func timeFormat(_ value : Int64) -> (String) {
        let minutes : Int = Int(value / 60)
        let seconds : Int = Int(value - (minutes * 60))
        return NSString(format: "%d:%02d", minutes, seconds) as (String)
    }
    
    func getVideoDuration() -> Float {
        return Float(CMTimeGetSeconds(playerItem.asset.duration))
    }
    
    func getVideoCurrentTime() -> Float {
        return Float(CMTimeGetSeconds(playerItem.currentTime()))
    }
    
}

// MARK: - Extensions
extension ViewController : VideoFramesManagerDelegate {
    func videoFramesAreReady(_ images: [UIImage]) {
        var framesImages = images
        var imagesViews = [UIImageView]()
        let scrollViewWidth = framesScrollView.frame.size.width
        let scrollViewStartEndOffsets = scrollViewWidth / 2
        if framesImages.count > 0 {
            shownFramesImagesCount = framesImages.count
            for i in 0..<shownFramesImagesCount {
                let imageView = UIImageView(image: framesImages[i])
                let xPosition : CGFloat = scrollViewStartEndOffsets + frameImageWidth * CGFloat(i)
                imageView.frame = CGRect(x: xPosition, y: 0, width: frameImageWidth, height: frameImageHeight)
                imagesViews.append(imageView)
            }
            
            DispatchQueue.main.async(execute: {
                for imageView in imagesViews {
                    self.framesScrollView.addSubview(imageView)
                }
                self.framesScrollView.setNeedsLayout()
                self.framesScrollView.contentSize = CGSize(width: scrollViewWidth + (CGFloat(self.shownFramesImagesCount) * self.frameImageWidth), height: self.frameImageHeight)
                UIUtils.instance.hideProgressHud()
            })
        }
        
    }
}

