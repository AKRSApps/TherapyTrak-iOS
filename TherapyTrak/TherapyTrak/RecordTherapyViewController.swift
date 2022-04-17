//
//  ViewController.swift
//  TherapyTrak
//
//  Created by Krish Iyengar on 4/15/22.
//

import UIKit
import AVFoundation
import Vision
import HealthKit
import ReplayKit

class RecordTherapyViewController: UIViewController {
    
    let recordTherapySession = AVCaptureSession()
    lazy var recordTherapyPreviewLayer: AVCaptureVideoPreviewLayer = {
        setUpTherapyCaptureSession()
        
        let tempRecordTherapyCaptureSession = AVCaptureVideoPreviewLayer(session: recordTherapySession)
        tempRecordTherapyCaptureSession.videoGravity = .resizeAspectFill
        
        tempRecordTherapyCaptureSession.connection?.videoOrientation = .landscapeRight
        
        return tempRecordTherapyCaptureSession
    }()
    
    var allTherapyVNDetectedParts = [VNHumanBodyPoseObservation.JointName : VNRecognizedPoint]()
    var allTherapySequenceHandler = VNSequenceRequestHandler()
    
    var therapyShapeLayer: CAShapeLayer = {
        let tempTherapyShapeLayer = CAShapeLayer()
        tempTherapyShapeLayer.lineWidth = 2.5
        tempTherapyShapeLayer.strokeColor = UIColor(red: 0.329, green: 0.267, blue: 0.533, alpha: 1).cgColor
        
        
        return tempTherapyShapeLayer
    }()
    
    var isInExtremePosition = false
    var totalTherapyReps = 0
    var lastBadRep = Date.timeIntervalSinceReferenceDate
    var lastTherapyRepTime = Date.timeIntervalSinceReferenceDate
    
    var therapyHealthStore = HKHealthStore()
    var lastUpDateTherapyHeartRate = 0
//    var numberTherapyHeartsRateCounts = 0
    
//    var averageTherapyHeartRate = 0.0
    var startDate = Date()
    
    // View Elements
    // Heart Rate
    let heartRateBeatingImage: UIImageView = {
        let tempHeartRateBeatingImage = UIImageView(image: UIImage(named: "TherapyHeartRate"))
        
        tempHeartRateBeatingImage.frame = CGRect(x: 100, y: 30, width: 45, height: 45)
        return tempHeartRateBeatingImage
    }()
    let heartRateNumberLabel: UILabel = {
        let tempHeartRateLabel = UILabel(frame: CGRect(x: 160, y: 30, width: 100, height: 45))
        tempHeartRateLabel.textColor = UIColor.white
        tempHeartRateLabel.font = UIFont.boldSystemFont(ofSize: 20)
        return tempHeartRateLabel
    }()
    var therapyHeartRateImageAnimation: Timer = Timer()
    
    // Rep
    let repCountLabel: UILabel = {
        let tempHeartRateLabel = UILabel(frame: CGRect(x: 160, y: 30, width: 100, height: 45))
        tempHeartRateLabel.textColor = UIColor.white
        tempHeartRateLabel.font = UIFont.boldSystemFont(ofSize: 20)
        tempHeartRateLabel.text = "0 Reps"
        return tempHeartRateLabel
    }()
    
    // Timer
    let therapyTimerLabel: UILabel = {
        let tempHeartRateLabel = UILabel(frame: CGRect(x: 160, y: 30, width: 100, height: 45))
        tempHeartRateLabel.textColor = UIColor.white
        tempHeartRateLabel.font = UIFont.boldSystemFont(ofSize: 20)
        tempHeartRateLabel.text = "0:00"
        return tempHeartRateLabel
    }()
    var therapyTimerCounter = 0
    var therapyTimer = Timer()
    
    // Start Button
    var therapyStartButton = UIButton()
    
    var therapyFirebaseStorageURL: URL = URL(fileURLWithPath: "")
    var therapyVideoUUID = UUID().uuidString
    
    var therapyStretchChosen = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        therapyStartButton.addAction(UIAction(handler: { startTherapyButtonAction in
            
            
            let therapyAlertController = UIAlertController(title: "Choose an Exercise", message: "Pick an exercise for the TherapyTrak to auto-detect", preferredStyle: .alert)
            
            for onePossibleExercise in allPossibleTherapyStretch {
                therapyAlertController.addAction(UIAlertAction(title: onePossibleExercise, style: .default, handler: { onePossibleExerciseAction in
                    self.therapyStretchChosen = onePossibleExercise
                    
                    self.startPhysicalTherapyExercises(therapyAction: startTherapyButtonAction)
                }))
            }
            therapyAlertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { cancelTherapyAlertController in
                self.dismiss(animated: true)
            }))
            
            self.present(therapyAlertController, animated: true)
            
            
            
            
        }), for: .touchDown)
        
        therapyStartButton.setTitle("Start", for: .normal)
        therapyStartButton.setTitleColor(.white, for: .normal)
        therapyStartButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 30)
        therapyStartButton.backgroundColor = UIColor(red: 0.953, green: 0.325, blue: 0.38, alpha: 0.75)
        therapyStartButton.layer.cornerRadius = 20
        
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        recordTherapySession.stopRunning()
    }
  
    override func viewDidAppear(_ animated: Bool) {
        
        
        if UIDevice.current.orientation != .landscapeRight {
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        }
        
        
        view.layer.addSublayer(recordTherapyPreviewLayer)
        
        view.layer.insertSublayer(therapyShapeLayer, above: recordTherapyPreviewLayer)
        
        // Heart Rate Views
        view.addSubview(heartRateNumberLabel)
        view.addSubview(heartRateBeatingImage)
        
        // Rep Count
        view.addSubview(repCountLabel)
        
        // Timer
        view.addSubview(therapyTimerLabel)
        
        // Start Button
        view.addSubview(therapyStartButton)
        
        self.repCountLabel.frame = CGRect(x: self.view.frame.maxX - 200, y: self.view.frame.maxY - 100, width: 100, height: 45)
        self.therapyTimerLabel.frame = CGRect(x: self.view.frame.maxX - 200, y: 30, width: 100, height: 45)
        self.therapyStartButton.frame = CGRect(x: self.view.frame.maxX/2.0-125, y: self.view.frame.maxY/2.0-50, width: 250, height: 100)
        
        
        
        self.recordTherapyPreviewLayer.frame = self.view.frame
        self.therapyShapeLayer.frame = view.frame
        
        

        askHealthAuth()
        
        
        
    }
    override func viewWillLayoutSubviews() {
        
        self.repCountLabel.frame = CGRect(x: self.view.frame.maxX - 200, y: self.view.frame.maxY - 100, width: 100, height: 45)
        self.therapyTimerLabel.frame = CGRect(x: self.view.frame.maxX - 200, y: 30, width: 100, height: 45)
        if self.therapyStartButton.titleLabel?.text == "Start" {
            self.therapyStartButton.frame = CGRect(x: self.view.frame.maxX/2.0-125, y: self.view.frame.maxY/2.0-50, width: 250, height: 100)
        }
        else {
            // This will be for the stop button
            self.therapyStartButton.frame = CGRect(x: 100, y: self.view.frame.maxY - 100, width: 100, height: 45)

        }
        self.recordTherapyPreviewLayer.frame = self.view.frame
        self.therapyShapeLayer.frame = view.frame
        
//        recordTherapyPreviewLayer.connection?.videoOrientation = .landscapeRight
    }
    
    func endTherapyAction() {
        therapyHeartRateImageAnimation.invalidate()
        therapyTimer.invalidate()
        
        DispatchQueue.main.async {
            RPScreenRecorder.shared().stopRecording(withOutput: self.therapyFirebaseStorageURL) { therapyScreenRecordingStopError in
                if therapyScreenRecordingStopError == nil {
                    DispatchQueue.main.async {

                        self.dismiss(animated: true)
                    }
                    uploadTherapyVideosStorage(therapyVideoFile: self.therapyFirebaseStorageURL, therapyVideoUUID: self.therapyVideoUUID, recordTherapyStats: self)
                    
                }
            }
        }
        
        
    }
    
    func startPhysicalTherapyExercises(therapyAction: UIAction) {
        
        
        self.therapyStartButton.frame = CGRect(x: 100, y: self.view.frame.maxY - 100, width: 100, height: 45)
        self.therapyStartButton.setTitle("Stop", for: .normal)
        self.therapyStartButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        
        self.therapyStartButton.removeAction(therapyAction, for: .touchDown)
        
        self.therapyStartButton.addAction(UIAction(handler: { [self] stopTherapyButtonAction in
            self.endTherapyAction()
        }), for: .touchDown)
        
        
        therapyHeartRateImageAnimation = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(animateTherapyHeartRate), userInfo: nil, repeats: true)
        therapyTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(therapyTimerCountMethod), userInfo: nil, repeats: true)
        
        // Sets the delegate only when the app starts
        (recordTherapySession.outputs.first as? AVCaptureVideoDataOutput)?.setSampleBufferDelegate(self, queue: DispatchQueue(label: "RecordTherapySampleBufferQueue"))
        
        RPScreenRecorder.shared().startRecording { therapyRPIScreenRecorderError in
            print(therapyRPIScreenRecorderError)
        }
        therapyVideoUUID = UUID().uuidString
        
        guard let firebaseScreenRecorderURLString = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first else { return }
        
        therapyFirebaseStorageURL = URL(fileURLWithPath: firebaseScreenRecorderURLString).appendingPathComponent("\(therapyVideoUUID).mp4", isDirectory: false)
        
        startDate = Date()
    }
    
    @objc func therapyTimerCountMethod() {
        therapyTimerCounter += 1
        
        DispatchQueue.main.async {
            self.therapyTimerLabel.text = "\(self.timeFormatterColon(inputValue: self.therapyTimerCounter))"
        }
        
    }
    
}

extension RecordTherapyViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func setUpTherapyCaptureSession() {
        
        do {
            guard let therapyCaptureInputDevice = AVCaptureDevice.default(for: .video) else { return }
            let therapyCaptureInput = try AVCaptureDeviceInput(device: therapyCaptureInputDevice)
            let therapyCaptureOutput = AVCaptureVideoDataOutput()
            therapyCaptureOutput.alwaysDiscardsLateVideoFrames = true
            recordTherapySession.beginConfiguration()
            
            recordTherapySession.addInput(therapyCaptureInput)
            recordTherapySession.addOutput(therapyCaptureOutput)
            
            recordTherapySession.automaticallyConfiguresApplicationAudioSession = true
            recordTherapySession.commitConfiguration()
            
            recordTherapySession.startRunning()
            
            
        }
        catch {
            print("Start Therapy Camera Session Error")
        }
        
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        let therapyVNHumanBodyPoseRequest = VNDetectHumanBodyPoseRequest { therapyVNRequest, therapyVNError in
            if therapyVNError == nil {
                
                do {
                    let therapyPoseRecognized = therapyVNRequest.results as? [VNHumanBodyPoseObservation]
                    self.allTherapyVNDetectedParts = try therapyPoseRecognized?.first?.recognizedPoints(.all) ?? [:]
                    self.drawTherapyPointsOnScreen()
                    
                    self.classifyTherapyExercise()
                }
                catch {
                    print("ERROR VN Detection Observations")
                }
            }
            
        }
        
        
        do {
            try allTherapySequenceHandler.perform([therapyVNHumanBodyPoseRequest], on: sampleBuffer)
        }
        catch {
            print("ERROR Therapy VNBody Pose")
        }
    }
    
    func drawTherapyPointsOnScreen() {
        
        
        let therapyPath = CGMutablePath()
        
        for eachTherapyPointDict in allTherapyVNDetectedParts {
            let eachTherapyPoint = recordTherapyPreviewLayer.layerPointConverted(fromCaptureDevicePoint: CGPoint(x: eachTherapyPointDict.value.location.x, y: 1-eachTherapyPointDict.value.location.y))
            
            //            if eachTherapyPointDict.key == .rightAnkle {
            //                print(eachTherapyPoint)
            //            }
            
            let therapyBezierPath = UIBezierPath(ovalIn: CGRect(x: eachTherapyPoint.x, y: eachTherapyPoint.y, width: 10, height: 10))
            therapyPath.addPath(therapyBezierPath.cgPath)
            
            
        }
        
        therapyShapeLayer.path = therapyPath
        
        DispatchQueue.main.async {
            self.therapyShapeLayer.didChangeValue(for: \.path)
        }
    }
    
    
    func classifyTherapyExercise() {
        if therapyStretchChosen == "Squats" {
            if allTherapyVNDetectedParts[.rightKnee]?.location != nil && allTherapyVNDetectedParts[.root]?.location != nil {
                let totalTherapyDistance = therapyDistance(firstTherapyPoint: allTherapyVNDetectedParts[.root]?.location ?? CGPoint(x: 0, y: 0), secondTherapyPoint: allTherapyVNDetectedParts[.rightKnee]?.location ?? CGPoint(x: 0, y: 0))
                
                let totalTherapyAnkleDistance = therapyDistance(firstTherapyPoint: allTherapyVNDetectedParts[.leftAnkle]?.location ?? CGPoint(x: 0, y: 0), secondTherapyPoint: allTherapyVNDetectedParts[.rightAnkle]?.location ?? CGPoint(x: 0, y: 0))

                print("Therapy Distance: \(totalTherapyAnkleDistance), Reps: \(totalTherapyReps)")
                
                if (totalTherapyDistance <= 0.13 && !isInExtremePosition) {
                    if (Date.timeIntervalSinceReferenceDate - lastTherapyRepTime) >= 0.75 {
                        isInExtremePosition = true
                        totalTherapyReps += 1
                        DispatchQueue.main.async {
                            
                            
                            self.repCountLabel.text = "\(self.totalTherapyReps) Reps"
                        }
                        AVSpeechSynthesizer().speak(AVSpeechUtterance(string: "\(totalTherapyReps)"))
                        
                        lastTherapyRepTime = Date.timeIntervalSinceReferenceDate
                    }
                }
                else if !isInExtremePosition && totalTherapyAnkleDistance <= 0.03 && Date.timeIntervalSinceReferenceDate - lastBadRep >= 5 {
                    AVSpeechSynthesizer().speak(AVSpeechUtterance(string: "Please move your feet apart."))

                    lastBadRep = Date.timeIntervalSinceReferenceDate

                }
                else if isInExtremePosition && totalTherapyDistance >= 0.18 {
                    isInExtremePosition = false
                }
            }
        }
        else if therapyStretchChosen == "Hand-Raises" {
            if allTherapyVNDetectedParts[.rightElbow]?.location != nil && allTherapyVNDetectedParts[.leftElbow]?.location != nil && allTherapyVNDetectedParts[.nose]?.location != nil {
                let totalTherapyDistanceLeftElbow = therapyDistance(firstTherapyPoint: allTherapyVNDetectedParts[.leftElbow]?.location ?? CGPoint(x: 0, y: 0), secondTherapyPoint: allTherapyVNDetectedParts[.nose]?.location ?? CGPoint(x: 0, y: 0))
                let totalTherapyDistanceRightElbow = therapyDistance(firstTherapyPoint: allTherapyVNDetectedParts[.rightElbow]?.location ?? CGPoint(x: 0, y: 0), secondTherapyPoint: allTherapyVNDetectedParts[.nose]?.location ?? CGPoint(x: 0, y: 0))

                
                let totalTherapyDistance = (totalTherapyDistanceLeftElbow < totalTherapyDistanceRightElbow) ? totalTherapyDistanceLeftElbow : totalTherapyDistanceRightElbow
                
                print("Therapy Distance: \(totalTherapyDistanceRightElbow), Reps: \(totalTherapyReps), Time: \((Date.timeIntervalSinceReferenceDate - lastTherapyRepTime)), extremePosition: \(isInExtremePosition)")

                if (totalTherapyDistance <= 0.13 && !isInExtremePosition) {
                    if (Date.timeIntervalSinceReferenceDate - lastTherapyRepTime) >= 0.75 {
                        isInExtremePosition = true
                        totalTherapyReps += 1
                        DispatchQueue.main.async {
                            
                            
                            self.repCountLabel.text = "\(self.totalTherapyReps) Reps"
                        }
                        AVSpeechSynthesizer().speak(AVSpeechUtterance(string: "\(totalTherapyReps)"))
                        
                        lastTherapyRepTime = Date.timeIntervalSinceReferenceDate
                    }
                }
                else if isInExtremePosition && totalTherapyDistance >= 0.25 {
                    isInExtremePosition = false
                }
            }
        }
    }
    
    func therapyDistance(firstTherapyPoint: CGPoint, secondTherapyPoint: CGPoint) -> Double {
        return sqrt(pow(firstTherapyPoint.x - secondTherapyPoint.x, 2) + pow(firstTherapyPoint.y - secondTherapyPoint.y, 2))
    }
    
  
}
extension RecordTherapyViewController {
    // Heart Rate Retrieval
    func askHealthAuth() {
        guard let therapyHeartQuantity = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        therapyHealthStore = HKHealthStore()
        
        therapyHealthStore.requestAuthorization(toShare: [], read: [therapyHeartQuantity]) { didProvideHealthAuth, didProvideHealthAuthError in
            if didProvideHealthAuthError == nil {
                print("Authorized Health Heart Rate")
            }
        }
        
    }
    
    func returnLastTherapyHeartRate() {
        guard let therapyHeartQuantity = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        
        let therapyHeartRateSearch = HKQuery.predicateForSamples(withStart: Calendar.current.date(byAdding: .year, value: -1, to: Date()), end: Date(), options: .strictEndDate)
        let therapyHeartRateSearchQuery = HKSampleQuery(sampleType: therapyHeartQuantity, predicate: therapyHeartRateSearch, limit: Int(HKObjectQueryNoLimit), sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { therapyQuerySample, therapyFinalResults, therapyQueryError in
            if therapyQueryError == nil && therapyFinalResults != nil {
                guard let therapyHeartRate = therapyFinalResults?.first as? HKQuantitySample else { return }
                let therapyHeartRateUnit = HKUnit(from: "count/min")
                let therapyHeartRateValue = therapyHeartRate.quantity.doubleValue(for: therapyHeartRateUnit)
                

                self.lastUpDateTherapyHeartRate = Int(therapyHeartRateValue)
                print(self.lastUpDateTherapyHeartRate)
                
                DispatchQueue.main.async {
                    self.heartRateNumberLabel.text = String(self.lastUpDateTherapyHeartRate)
                }
                
            }
        }
        therapyHealthStore.execute(therapyHeartRateSearchQuery)
    }
    
    @objc func animateTherapyHeartRate() {
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseInOut) {
            self.heartRateBeatingImage.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            
        } completion: { didFinishPulsingHeartRateUp in
            if didFinishPulsingHeartRateUp {
                UIView.animate(withDuration: 0.5) {
                    
                    
                    self.heartRateBeatingImage.transform = CGAffineTransform.identity
                }
            }
        }
        returnLastTherapyHeartRate()
        
    }
    
    
}
// Helper Functions
extension RecordTherapyViewController {
    func timeFormatterColon(inputValue: Int) -> String {
        var tempString = ""
        if inputValue < 60 {
            
            if inputValue % 60 < 10 {
                return "00:0\(inputValue)"
            }
            else {
                return "00:\(inputValue)"
            }
        }
        else {
            if inputValue > 3600 {
                tempString = ""
                let hourConversion = inputValue/3600
                let hourSoonToBeMinutes = inputValue%3600
                let minutesConversion = hourSoonToBeMinutes/60
                let minutesSoonToBeSeconds = hourSoonToBeMinutes%60
                if hourConversion < 10 {
                    tempString = "0\(hourConversion)"
                }
                else {
                    tempString = "\(hourConversion)"
                }
                if minutesConversion < 10 {
                    tempString = tempString + ":0\(minutesConversion)"
                    
                }
                else {
                    tempString = tempString + ":\(minutesConversion)"
                }
                
                if minutesSoonToBeSeconds < 10 {
                    tempString = tempString + ":0\(minutesSoonToBeSeconds)"
                }
                else {
                    tempString = tempString + ":\(minutesSoonToBeSeconds)"
                }
                
            }
            else {
                if inputValue % 60 < 10 {
                    if inputValue/60 < 10 {
                        tempString = "0\(inputValue/60):0\(inputValue%60)"
                    }
                    else {
                        tempString = "\(inputValue/60):0\(inputValue%60)"
                    }
                    
                }
                else {
                    if inputValue/60 < 10 {
                        tempString = "0\(inputValue/60):\(inputValue%60)"
                    }
                    else {
                        tempString = "\(inputValue/60):\(inputValue%60)"
                    }
                    
                }
            }
        }
        return tempString
    }
    
}

