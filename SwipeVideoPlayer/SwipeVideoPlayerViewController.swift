//
//  ViewController.swift
//  SwipeVideoPlayer
//
//  Created by 邵仁杰 on 7/11/20.
//  Copyright © 2020 Renjie Shao. All rights reserved.
//

import UIKit
import AVKit
import CoreMotion

 
class SwipeVideoPlayerViewController: UIViewController {
    
    var playerLayer: AVPlayerLayer!
    var player: AVPlayer!
    var isPlaying: Bool = false
    var url: URL!
    var videoAspectRatio: CGSize!
    var duration: Double!
    var currentTime: Float64!
    var chaseTime = CMTime.zero
    var isSeekInProgress = false
    
    
    @IBOutlet weak var videoView: UIView!
    
    
    /// Return the resolution of the video.
    ///
    /// Use this function to display the video adaptively in avplayerlayer
    private func resolutionForLocalVideo(url: URL) -> CGSize? {
        guard let track = AVURLAsset(url: url).tracks(withMediaType: AVMediaType.video).first else { return nil }
       let size = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: abs(size.width), height: abs(size.height))
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        player = AVPlayer(url: url)
        videoAspectRatio = resolutionForLocalVideo(url: url)
        
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resize
        
        videoView.layer.addSublayer(playerLayer)
        addPan()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        player.pause()
        isPlaying = false
        duration = CMTimeGetSeconds(player.currentItem!.duration)
        currentTime = 0.0
        startGyro()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopGyro()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let adaptiveSize = AVMakeRect(aspectRatio: videoAspectRatio, insideRect: videoView.bounds)
        playerLayer.frame = adaptiveSize
    }
    
    /// Start update gyroscope
    func startGyro() {
        if CMMotionManager.shared.isGyroAvailable {
            CMMotionManager.shared.gyroUpdateInterval = gyroUpdateInterval
            CMMotionManager.shared.startGyroUpdates(to: .main) { (data, error) in
                self.gyroHandle(data, error)
                return
            }
        }
    }
    
    /// Stop update gyroscope
    func stopGyro() {
        CMMotionManager.shared.stopGyroUpdates()
    }
    
    func gyroHandle(_ data: CMGyroData?, _ error: Error?) {
        let curSecond = CMTimeGetSeconds(self.player.currentTime())
        if let yRotationRate = data?.rotationRate.y{
            if abs(yRotationRate) > self.rotationRateThreshold {
                let newSecond = curSecond - yRotationRate
                if newSecond>=0, newSecond < self.duration {
                    let newTime = CMTime(seconds: newSecond, preferredTimescale: 1000)
                    seekSoomthlyToTime(newChaseTime: newTime)
                }
            }
        }
    }
    
    
    
    func addPan() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(reactSwipe))
        videoView.addGestureRecognizer(pan)
    }
    
    @objc func reactSwipe(_ recognizer: UIPanGestureRecognizer) {
        let translation = recognizer.translation(in: videoView)
        if recognizer.state == .began {
            currentTime = CMTimeGetSeconds(player.currentTime())
            self.stopGyro()
        } else if recognizer.state == .ended || recognizer.state == .cancelled {
            startGyro()
        }
        else if recognizer.state != .cancelled {
           // Add the X and Y translation to the view's original position.
            
            let newTime = currentTime-0.02 * Float64(translation.x)
            var time: CMTime!
            
            if newTime>0, newTime < duration {
                time = CMTime(seconds: newTime, preferredTimescale: 1000)
                //player.seek(to: time, toleranceBefore: tolerance, toleranceAfter: tolerance)
                
                seekSoomthlyToTime(newChaseTime: time)
             }
        }
        
    }
    
    
    /// Achieve smooth video scrub
    ///
    /// Check isSeekInProgress to avoid calling seek frequently
    /// - Parameter newChaseTime: target time
    func seekSoomthlyToTime(newChaseTime: CMTime) {
        if CMTimeCompare(newChaseTime, chaseTime) != 0 {
            chaseTime = newChaseTime
            if !isSeekInProgress {
                trySeekToChaseTime()
            }
        }
    }
    
    func trySeekToChaseTime() {
        guard player?.status == .readyToPlay else {return}
        actuallySeekToTime()
    }
    
    func actuallySeekToTime() {
        isSeekInProgress = true
        let seekTimeInProgress = chaseTime
        player.seek(to: seekTimeInProgress, toleranceBefore: tolerance, toleranceAfter: tolerance) { (isFinished:Bool) in
            if CMTimeCompare(seekTimeInProgress, self.chaseTime) == 0 {
                self.isSeekInProgress = false
            }
            else {
                self.trySeekToChaseTime()
            }
        }
    }
    
    /// - Constants
    let tolerance = CMTime(seconds: 0.0, preferredTimescale: 1000)
    let rotationRateThreshold = 0.03
    let gyroUpdateInterval = 0.02
}
