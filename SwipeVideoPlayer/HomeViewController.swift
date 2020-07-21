//
//  HomeViewController.swift
//  SwipeVideoPlayer
//
//  Created by 邵仁杰 on 7/12/20.
//  Copyright © 2020 Renjie Shao. All rights reserved.
//

import UIKit
import AVKit
import MobileCoreServices

class HomeViewController: UIViewController{

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if let url = sender as? URL {
            if let svpc = segue.destination as? SwipeVideoPlayerViewController {
                svpc.url = url
            }
        }
    }
    
    func startMediaBrowser(sourceType: UIImagePickerController.SourceType) {
      guard UIImagePickerController.isSourceTypeAvailable(sourceType) else { return }
      
      let mediaUI = UIImagePickerController()
      mediaUI.sourceType = sourceType
      mediaUI.mediaTypes = [kUTTypeMovie as String]
      mediaUI.allowsEditing = true
      mediaUI.delegate = self
      present(mediaUI, animated: true, completion: nil)
    }
    
    
    @IBAction func openAlbum(_ sender: UIButton) {
        print("press")
        startMediaBrowser(sourceType: .savedPhotosAlbum)
    }
    
}

extension HomeViewController: UIImagePickerControllerDelegate{
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        print("picked")
        guard let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String,
        mediaType == (kUTTypeMovie as String),
            let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL
        else { return }
        dismiss(animated: true) {
            self.performSegue(withIdentifier: "play video", sender: url)
        }
    }
}

extension HomeViewController: UINavigationControllerDelegate {
    
}
