//
//  GameViewController.swift
//  SCNRecorder-SampleApp
//
//  Created by Giovanni Murru on 07/12/23.
//
//    Copyright © 2023 Giovanni Murru
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in
//    all copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//    THE SOFTWARE.

import UIKit
import QuartzCore
import SceneKit
import SCNRecorder
import CoreMedia
import AVKit
import Photos


class GameViewController: UIViewController {
    // Tune this value to get the video to autostop after a certain amount of seconds. Use 0 for continuous recording.
    let kSecondsToAutostop : Int = 60
    
    var isRecording: Bool = false {
        didSet {
            recordingButton.layer.cornerRadius = isRecording ? 0 : timerLabelSize.height/2
        }
    }
    var timerLabel : UILabel!
    var recordingButton : UIButton!
    var sceneView : SCNView!
    let timerLabelSize : CGSize = CGSize(width: 120, height: 30)
    var shouldStopRecording : Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/ship.scn")!
        
        // create and add a camera to the scene
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        scene.rootNode.addChildNode(cameraNode)
        
        // place the camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: 15)
        
        // create and add a light to the scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light!.type = .omni
        lightNode.position = SCNVector3(x: 0, y: 10, z: 10)
        scene.rootNode.addChildNode(lightNode)
        
        // create and add an ambient light to the scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = .ambient
        ambientLightNode.light!.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        
        // retrieve the ship node
        let ship = scene.rootNode.childNode(withName: "ship", recursively: true)!
        
        // animate the 3d object
        ship.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 2, z: 0, duration: 1)))
        
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = true
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = true
        
        // configure the view
        scnView.backgroundColor = UIColor.black
        
        sceneView = scnView
        // add a tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scnView.addGestureRecognizer(tapGesture)
        
        scnView.prepareForRecording()

        
        recordingButton = UIButton(frame: CGRect(origin: CGPoint.zero, size: CGSize(width: timerLabelSize.height, height: timerLabelSize.height)))
        recordingButton.center = scnView.center
        recordingButton.layer.cornerRadius = timerLabelSize.height/2
        recordingButton.layer.masksToBounds = true
        recordingButton.layer.backgroundColor = UIColor.red.cgColor
        recordingButton.addTarget(self, action: #selector(startRecording(_:)), for: .touchUpInside)
        view.addSubview(recordingButton)
        
        timerLabel = UILabel(frame: CGRect(origin: CGPoint.zero, size: timerLabelSize))
        timerLabel.text = "00:00:00"
        timerLabel.font = UIFont(name: "Menlo-Regular", size: 17)
        timerLabel.textColor = .red
        view.addSubview(timerLabel)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let minMargin : CGFloat = 20
        let topSafeSpace = view.safeAreaInsets.top > 0 ? view.safeAreaInsets.top : minMargin
        recordingButton.center = CGPoint(x: view.frame.size.width - timerLabelSize.width - timerLabelSize.height/2 - minMargin, y: topSafeSpace + timerLabelSize.height/2)
        let interspace : CGFloat = 20
        timerLabel.center = CGPoint(x: recordingButton.center.x + timerLabelSize.height/2 + interspace + timerLabel.frame.size.width/2, y: recordingButton.center.y)
    }
    
    func formatTime(ticks: Int, tps: Double) -> (minutes: Int, seconds: Int, centiseconds: Int) {
        let seconds = Int(floor(round(TimeInterval(ticks)/TimeInterval(tps) * 100)/100))
        let normalizer = TimeInterval(100)/TimeInterval(tps)
        return (seconds/60 % 60, seconds % 60, Int(round(TimeInterval(ticks)*normalizer)) % 100)
    }
    
    @objc
    func startRecording(_ sender: UIButton) {
        sender.isEnabled = false
        isRecording.toggle()
        if isRecording {
            do {
                let videoSettings  = VideoSettings(fileType: .mov, codec: .hevc())
                let videoRecording = try sceneView.startVideoRecording(videoSettings: videoSettings)
                print("INFO: Started recording")
                print("INFO: Autostop recording in \(kSecondsToAutostop) seconds")
                autostopRecording(videoRecording, in: kSecondsToAutostop)
            } catch {
                print("ERROR: can't start video recording.\nError description:\n\(error.localizedDescription)")
                isRecording = false
            }
        } else {
            shouldStopRecording = true
        }
        sender.isEnabled = true
    }
    
    func stopRecording() {
        print("INFO: Stopped recording")
        sceneView.finishVideoRecording { (videoRecording) in
            /* Process the captured video. Main thread. */
            self.isRecording = false
            self.saveAssetToPhotos(assetURL: videoRecording.url, isVideo: true) { success, error in
                if success {
                    print("INFO: Video has been saved in the Photos gallery")
                    do {
                        try FileManager.default.removeItem(at: videoRecording.url)
                    } catch {
                        print("ERROR: could not remove video recording temporary file from file system.")
                    }
                } else {
                    print("ERROR: Could not save the video to gallery.")
                }
            }
        }
    }
    
    
    func autostopRecording(_ videoRecording: VideoRecording, in recordingTimeDuration: Int) {
        guard recordingTimeDuration > 0 else {
            print("INFO: set kSecondsToAutostop to a value greater than 0 to autostop the recording")
            return
        }
        var isStoppingRecording : Bool = false
        var frameCount : Int = 0
        videoRecording.$duration.observe { [weak self] elapsedTime in
            guard let self = self, elapsedTime > 0, !isStoppingRecording else { return }
            frameCount += 1
            let fps = Double(frameCount)/elapsedTime
            let time = self.formatTime(ticks: Int(frameCount), tps: fps)
            let formattedTime = String(format: "%02d:%02d:%02d", time.minutes, time.seconds, time.centiseconds)
            DispatchQueue.main.async {
                self.timerLabel.text = formattedTime
            }
            if self.shouldStopRecording || frameCount == Int(floor(fps * Double(recordingTimeDuration))) {
                isStoppingRecording = true
                self.shouldStopRecording = false
                self.stopRecording()
                print("INFO: Elapsed time: \(elapsedTime)")
            }
        }
        
    }
    
    @objc
    func handleTap(_ gestureRecognize: UIGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are tapped
        let p = gestureRecognize.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]
            
            // get its material
            let material = result.node.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = UIColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = UIColor.red
            
            SCNTransaction.commit()
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    func finalizeSaveAssetToPhotos(image: UIImage?, assetURL: URL?, isVideo: Bool, completionHandler: ((Bool, Error?)-> Void)?) {
        PHPhotoLibrary.shared().performChanges {
            if let image = image {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } else if let assetURL = assetURL {
                if isVideo {
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: assetURL)
                } else {
                    PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: assetURL)
                }
            }
        } completionHandler: { (success, error) in
            if let error = error {
                print("ERROR: could not save asset on Photos: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                completionHandler?(success, error)
            }
        }
    }
    
    func saveAssetToPhotos(image: UIImage? = nil, assetURL: URL? = nil, isVideo : Bool = false, completionHandler: ((Bool, Error?) -> Void)? = nil) {
        let accessLevel : PHAccessLevel = ProcessInfo.processInfo.isMacCatalystApp ? .readWrite : .addOnly
        let authorization = PHPhotoLibrary.authorizationStatus(for: accessLevel)
        switch authorization {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: accessLevel) { authorization in
                DispatchQueue.main.async {
                    if let image = image {
                        self.saveAssetToPhotos(image: image, completionHandler: completionHandler)
                    } else {
                        self.saveAssetToPhotos(assetURL: assetURL, isVideo: isVideo, completionHandler: completionHandler)
                    }
                }
            }
        case .restricted:
            print("ERROR: access restricted")
            DispatchQueue.main.async {
                completionHandler?(false, nil)
            }
        case .denied:
            print("ERROR: access denied")
            DispatchQueue.main.async {
                completionHandler?(false, nil)
            }
        case .authorized:
            finalizeSaveAssetToPhotos(image: image, assetURL: assetURL, isVideo: isVideo, completionHandler: completionHandler)
        case .limited:
            finalizeSaveAssetToPhotos(image: image, assetURL: assetURL, isVideo: isVideo, completionHandler: completionHandler)
        default:
            print("ERROR: unknown case")
            DispatchQueue.main.async {
                completionHandler?(false, nil)
            }
        }
        
    }

}
