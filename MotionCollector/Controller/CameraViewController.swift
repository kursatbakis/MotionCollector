//
//  CameraViewController.swift
//  MotionCollector
//
//  Created by Sociable on 2.12.2021.
//  Copyright © 2021 Aleksei Degtiarev. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import Photos

class CameraViewController: UIViewController, AVCaptureFileOutputRecordingDelegate {
    
    let captureSession = AVCaptureSession()
    let videoOutput = AVCaptureMovieFileOutput()
    let recordButton = UIButton(frame: .zero)
    let statsContainerView = UIView(frame: .zero)
    let gyroLabel = UILabel(frame: .zero)
    let accLabel = UILabel(frame: .zero)
    let magLabel = UILabel(frame: .zero)
    let exitButton = UIButton(type: .roundedRect)
    
    var isrecording = false {
        didSet {
            if isrecording {
                recordButton.backgroundColor = .orange
            } else {
                recordButton.backgroundColor = .red
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .sensor, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        openCamera()
        view.addSubview(recordButton)
        view.addSubview(statsContainerView)
        view.addSubview(exitButton)
        NotificationCenter.default.addObserver(self, selector: #selector(notify), name: .sensor, object: nil)
        
        [gyroLabel, magLabel, accLabel].forEach(statsContainerView.addSubview)
        recordButton.backgroundColor = .red
        recordButton.layer.cornerRadius = 30
        recordButton.layer.masksToBounds = true
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        recordButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20.0).isActive = true
        recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        recordButton.widthAnchor.constraint(equalToConstant: 60.0).isActive = true
        recordButton.heightAnchor.constraint(equalToConstant: 60.0).isActive = true
        recordButton.addTarget(self, action: #selector(recordTap), for: .touchUpInside)
        
        statsContainerView.backgroundColor = .black.withAlphaComponent(0.2)
        statsContainerView.translatesAutoresizingMaskIntoConstraints = false
        statsContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6.0).isActive = true
        statsContainerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        statsContainerView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        gyroLabel.translatesAutoresizingMaskIntoConstraints = false
        gyroLabel.topAnchor.constraint(equalTo: statsContainerView.topAnchor, constant: 10.0).isActive = true
        gyroLabel.leftAnchor.constraint(equalTo: statsContainerView.leftAnchor, constant: 10.0).isActive = true
        gyroLabel.rightAnchor.constraint(equalTo: statsContainerView.rightAnchor, constant: -10.0).isActive = true
        gyroLabel.textAlignment = .center
        gyroLabel.textColor = .green
        gyroLabel.font = .monospacedSystemFont(ofSize: 15.0, weight: .medium)
        gyroLabel.adjustsFontSizeToFitWidth = true
        magLabel.translatesAutoresizingMaskIntoConstraints = false
        magLabel.topAnchor.constraint(equalTo: gyroLabel.bottomAnchor, constant: 10.0).isActive = true
        magLabel.leftAnchor.constraint(equalTo: statsContainerView.leftAnchor, constant: 10.0).isActive = true
        magLabel.rightAnchor.constraint(equalTo: statsContainerView.rightAnchor, constant: -10.0).isActive = true
        magLabel.textAlignment = .center
        magLabel.textColor = .blue
        magLabel.font = .monospacedSystemFont(ofSize: 15.0, weight: .medium)
        magLabel.adjustsFontSizeToFitWidth = true
        accLabel.translatesAutoresizingMaskIntoConstraints = false
        accLabel.topAnchor.constraint(equalTo: magLabel.bottomAnchor, constant: 10.0).isActive = true
        accLabel.leftAnchor.constraint(equalTo: statsContainerView.leftAnchor, constant: 10.0).isActive = true
        accLabel.rightAnchor.constraint(equalTo: statsContainerView.rightAnchor, constant: -10.0).isActive = true
        accLabel.bottomAnchor.constraint(equalTo: statsContainerView.bottomAnchor, constant: -10.0).isActive = true
        accLabel.textAlignment = .center
        accLabel.textColor = .red
        accLabel.font = .monospacedSystemFont(ofSize: 15.0, weight: .medium)
        accLabel.adjustsFontSizeToFitWidth = true
        exitButton.frame = CGRect(x: 20, y: UIScreen.main.bounds.height - 80, width: 90, height: 50)
        exitButton.setAttributedTitle(NSAttributedString(string: "EXIT", attributes: [.font: UIFont.systemFont(ofSize: 17.0, weight: .black)]), for: .normal)
        exitButton.backgroundColor = .white.withAlphaComponent(0.7)
        exitButton.layer.cornerRadius = 5.0
        exitButton.layer.masksToBounds = true
        exitButton.addTarget(self, action: #selector(exitButtonTapped), for: .touchUpInside)
    }
    
    @objc func exitButtonTapped() {
        videoOutput.stopRecording()
        dismiss(animated: true, completion: nil)
    }
    
    func tempURL() -> URL? {
        let directory = NSTemporaryDirectory() as NSString
        
        if directory != "" {
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
            return URL(fileURLWithPath: path)
        }
        
        return nil
    }
    
    @objc func notify(_ notification: Notification) {
        if let o = notification.object as? SensorOutput {
            accLabel.text = "Accelero(x,y,z): (\(o.accX!.round(to: 2)), \(o.accY!.round(to: 2)), \(o.accZ!.round(to: 2)))"
            magLabel.text = "Magneto(x,y,z): (\(o.magX!.round(to: 2)), \(o.magY!.round(to: 2)), \(o.magZ!.round(to: 2)))"
            gyroLabel.text = "Gyroscope(x,y,z): (\(o.gyroX!.round(to: 2)), \(o.gyroY!.round(to: 2)), \(o.gyroZ!.round(to: 2)))"
        }
    }
    
    @objc func recordTap() {
    
        let filePath = tempURL()
        if videoOutput.isRecording {
            videoOutput.stopRecording()
            recordButton.backgroundColor = .red
        } else {
            videoOutput.startRecording(to: filePath!, recordingDelegate: self)
            recordButton.backgroundColor = .white
        }
    }
    
    func openCamera() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.setupCaptureSession()
                    }
                } else {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        default:
            dismiss(animated: true, completion: nil)
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func setupCaptureSession() {
        if let captureDevice = AVCaptureDevice.default(for: .video) {
            do {
                let input = try AVCaptureDeviceInput(device: captureDevice)
                captureSession.addInput(input)
            } catch {
                
            }
            if captureDevice.isSmoothAutoFocusSupported {
                do {
                    try captureDevice.lockForConfiguration()
                    captureDevice.isSmoothAutoFocusEnabled = false
                    captureDevice.unlockForConfiguration()
                } catch {
                    print("greg")
                }
            }
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            let cameraLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            cameraLayer.frame = view.frame
            cameraLayer.videoGravity = .resizeAspectFill
            cameraLayer.connection?.videoOrientation = .portrait
            view.layer.addSublayer(cameraLayer)
            captureSession.startRunning()
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
        } completionHandler: { saved, error in
            if saved {
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "Your video was successfully saved", message: nil, preferredStyle: .alert)
                    let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertController.addAction(defaultAction)
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
        
    }
}

extension Double {
    func round(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
