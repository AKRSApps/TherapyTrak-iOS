//
//  TherapyHomeScreenViewController.swift
//  TherapyTrak
//
//  Created by Krish Iyengar on 4/16/22.
//

import UIKit
import AVFoundation
import AVKit
import SwiftUI
import UserNotifications

struct TherapyVideo {
    
    let heartRate: Double
    let numReps: Int
    let time: String
    let stretch: String
    let therapyVideoID: String
    let date: String
}
struct TherapyUser {
    var name: String
    var email: String
    var profilePicture: UIImage
}

class TherapyHomeScreenViewController: UITableViewController {

    var therapyFirebaseStorageURL = URL(fileURLWithPath: "")
    
    
    var therapyNotificationsOn = false
    var therapyNotificationsDate = Date()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        therapyHomeScreen = self
        
        guard let firebaseScreenRecorderURLString = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first else { return }
        
        therapyFirebaseStorageURL = URL(fileURLWithPath: firebaseScreenRecorderURLString).appendingPathComponent("DownloadedTherapyVideo.mp4", isDirectory: false)
        
        tableView.refreshControl = UIRefreshControl(frame: CGRect(x: view.frame.width/2, y: 30, width: 45, height: 45), primaryAction: UIAction(handler: { therapyRefreshControlAction in
            
            getPatientPossibleStretches()
            
            getTherapyUserInfo()
            
            gatherAllTherapyVideoData()
            
            
        }))
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        therapyNotificationsOn = UserDefaults.standard.object(forKey: "therapyNotificationsOn") as? Bool ?? false
        therapyNotificationsDate = UserDefaults.standard.object(forKey: "therapyNotificationsDate") as? Date ?? Date()
        
       
    }
    
    @IBSegueAction func therapySettingsHostedController(_ coder: NSCoder) -> UIViewController? {
        return UIHostingController(coder: coder, rootView: SettingsView(allowNotifications: therapyNotificationsOn, notificationDate: therapyNotificationsDate))
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allTherapyVideos.count
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let therapyTableViewCell = tableView.dequeueReusableCell(withIdentifier: "therapySessionCell") as? TherapySessionTableViewCell else { return UITableViewCell() }
        
        therapyTableViewCell.avgHeartRateLabel.text = "\(allTherapyVideos[indexPath.row].heartRate) BPM"
        therapyTableViewCell.dateLabel.text = allTherapyVideos[indexPath.row].date
        therapyTableViewCell.numberOfRepsLabel.text = "\(allTherapyVideos[indexPath.row].numReps) Reps"
        therapyTableViewCell.stretchTypeLabel.text = allTherapyVideos[indexPath.row].stretch
        
        return therapyTableViewCell

    }
    func therapySignOutDismiss() {
        DispatchQueue.main.async {
            self.dismiss(animated: true) {
                self.performSegue(withIdentifier: "therapySignOutSegue", sender: self)
            }
        }
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
  
        downloadTherapyVideo(therapyVideoID: allTherapyVideos[indexPath.row].therapyVideoID, therapyVideoURL: therapyFirebaseStorageURL)
        
    }
    
    func showTherapyCurrentDownloadedVideo() {
    
        
        let therapyVideoPlayer = AVPlayer(url: therapyFirebaseStorageURL)
        
        let therapyAVVideoPlayerController = AVPlayerViewController()
        
        therapyAVVideoPlayerController.player = therapyVideoPlayer
        
        present(therapyAVVideoPlayerController, animated: true, completion: {
            therapyVideoPlayer.play()
        })
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        do {
            try FileManager.default.removeItem(at: therapyFirebaseStorageURL)
        }
        catch {
            print("Removing TherapyFirebase Storage")
        }
    }
    
    
    func addTherapyUserNotifications(therapyDate: Date) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound, .criticalAlert, .provisional]) { didTherapyAuthenticate, didTherapyAuthenticateError in
            
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            
            if didTherapyAuthenticate {
                
                let therapyMutableNotification = UNMutableNotificationContent()
                
                therapyMutableNotification.title = "It's that time of the day! ⏰"
                therapyMutableNotification.body = "Time for your Daily Physical Therapy Session"
                
                let therapyDateTrigger = UNCalendarNotificationTrigger(dateMatching: Calendar.current.dateComponents([.hour, .minute], from: therapyDate), repeats: true)
                
                let therapyNotificationRequest = UNNotificationRequest(identifier: "therapyNotificationSession", content: therapyMutableNotification, trigger: therapyDateTrigger)
                
                UNUserNotificationCenter.current().add(therapyNotificationRequest)
            }
        }
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
