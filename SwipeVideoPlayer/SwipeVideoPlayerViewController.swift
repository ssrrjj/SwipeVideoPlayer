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
    
    @IBOutlet weak var videoView: UIView!
    
    
    
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
    
    func startGyro() {
        if CMMotionManager.shared.isGyroAvailable {
            CMMotionManager.shared.gyroUpdateInterval = 0.04
            CMMotionManager.shared.startGyroUpdates(to: .main) { (data, error) in
                self.gyroHandle(data, error)
                return
            }
        }
    }
    
    func stopGyro() {
        CMMotionManager.shared.stopGyroUpdates()
    }
    
    func gyroHandle(_ data: CMGyroData?, _ error: Error?) {
        let time = CMTimeGetSeconds(self.player.currentTime())
        if let yRotationRate = data?.rotationRate.y{
            if abs(yRotationRate) > self.rotationRateThreshold {
                let newTime = time - yRotationRate
                if newTime>=0, newTime < self.duration {
                    self.player.seek(to: CMTime(seconds: newTime, preferredTimescale: 1000), toleranceBefore: self.tolerance, toleranceAfter: self.tolerance)
                }
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let adaptiveSize = AVMakeRect(aspectRatio: videoAspectRatio, insideRect: videoView.bounds)
        playerLayer.frame = adaptiveSize
    }
    
    func addPan() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(reactSwipe))
        videoView.addGestureRecognizer(pan)
    }
    var currentTime: Float64!
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
                player.seek(to: time, toleranceBefore: tolerance, toleranceAfter: tolerance)
             }
            
            
        }
        
    }
    
    // Constants
    let tolerance = CMTime(seconds: 0.01, preferredTimescale: 1000)
    let rotationRateThreshold = 0.03
}
