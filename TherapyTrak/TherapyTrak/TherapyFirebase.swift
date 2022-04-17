//
//  TherapyFirebase.swift
//  TherapyTrak
//
//  Created by Krish Iyengar on 4/16/22.
//

import Foundation
import Firebase
import FirebaseDatabase
import GoogleSignIn
import FirebaseStorage
import AVFoundation

var therapyDatabaseReference = Database.database().reference()

func setPatientReference() {
    guard let therapyGoogleUserUnwrapped = therapyGoogleUser else { return }
    therapyDatabaseReference = therapyDatabaseReference.root
    
    therapyDatabaseReference = therapyDatabaseReference.child("patients").child(therapyGoogleUserUnwrapped.userID ?? "ERROR")
}

func getPatientPossibleStretches() {
    allPossibleTherapyStretch.removeAll()
    setPatientReference()
    
    therapyDatabaseReference.child("exercises").child("exercise").getData { therapyPossibleError, therapyPossibleDataSnapshot in
        if therapyPossibleError == nil {
            allPossibleTherapyStretch = therapyPossibleDataSnapshot.value as? [String] ?? []
            if allPossibleTherapyStretch.count > 0 {
                allPossibleTherapyStretch.removeAll { onePossibleTherapyStretch in
                    return onePossibleTherapyStretch == "PLACEHOLDER REMOVE"
                }
            }
        }
    }
    
}
func setHomeReference() {
    therapyDatabaseReference = therapyDatabaseReference.root
}
func setPatientDoctor(therapistID: String, completionPatientDoctor: @escaping ((Bool) -> Void)) {
    guard let therapyGoogleUserUnwrapped = therapyGoogleUser else { return }
    
    
    setHomeReference()
    
    therapyDatabaseReference.child("doctors").getData(completion: { doctorsError, doctorsSnapshot in
        if doctorsError == nil {
            var wasAbleToFindDoctor = false

            for eachDoctorSnapshotChildren in (doctorsSnapshot.children.allObjects as? [DataSnapshot]) ?? [] {

                if ((eachDoctorSnapshotChildren.childSnapshot(forPath: "id").value as? String) ?? "ERROR") == therapistID {
                    therapyDatabaseReference = eachDoctorSnapshotChildren.ref
                    // This means that the doctor is an actual person
                    wasAbleToFindDoctor = true
                    eachDoctorSnapshotChildren.ref.child("patientIDs").getData { therapyPatientIDChangeError, therapyPatientIDChange in
                        if therapyPatientIDChangeError == nil {
                            var therapyPatientIDArray = (therapyPatientIDChange.value as? [String]) ?? []
                            
                            if !therapyPatientIDArray.contains(therapyGoogleUserUnwrapped.userID ?? "ERROR") {
                                therapyPatientIDArray.append(therapyGoogleUserUnwrapped.userID ?? "ERROR")
                                eachDoctorSnapshotChildren.ref.child("patientIDs").setValue(therapyPatientIDArray)
                                
                            }
                            setPatientReference()
                            
                            therapyDatabaseReference.child("doctorID").setValue(therapistID)
                            therapyDatabaseReference.child("name").setValue(therapyGoogleUserUnwrapped.profile?.name)
                            therapyDatabaseReference.child("email").setValue(therapyGoogleUserUnwrapped.profile?.email)
                            
                        }

                    }
                }
            }
            
            completionPatientDoctor(wasAbleToFindDoctor)

        }
    })
}

var therapyUserInfo = TherapyUser(name: "", email: "", profilePicture: UIImage())

func getTherapyUserInfo() {
    
    therapyUserInfo.name = GIDSignIn.sharedInstance.currentUser?.profile?.name ?? "ERROR NAME"
    therapyUserInfo.email = GIDSignIn.sharedInstance.currentUser?.profile?.email ?? "ERROR EMAIL"
    
    guard let therapyUserProfilePicture = GIDSignIn.sharedInstance.currentUser?.profile?.imageURL(withDimension: 50) else { return }
    
    URLSession.shared.dataTask(with: therapyUserProfilePicture) { therapyUserProfilePictureData, therapyProfilePicUserResponse, therapyProfilePicUserError in
        therapyUserInfo.profilePicture = UIImage(data: therapyUserProfilePictureData ?? Data()) ?? UIImage()
        
    }.resume()

}

func uploadVideoStatistics(recordTherapyStats: RecordTherapyViewController) {
    setPatientReference()
    
    therapyDatabaseReference = therapyDatabaseReference.child("stats")
//    therapyDatabaseReference.getData(completion: { videoIDsError, videoIDsSnapshot in
//        if videoIDsError == nil {
//
//            var therapyVideoIDArray = [String]()
//
//            for eachDoctorSnapshotChildren in (videoIDsSnapshot.children.allObjects as? [DataSnapshot]) ?? [] {
//
//                therapyVideoIDArray.append((eachDoctorSnapshotChildren.value as? String) ?? "ERRROR")
//            }
//            therapyVideoIDArray.append(recordTherapyStats.therapyVideoUUID)
//            therapyDatabaseReference.setValue(therapyVideoIDArray)
//
//
            
            therapyDatabaseReference = therapyDatabaseReference.child(recordTherapyStats.therapyVideoUUID)
            // Adds a new video ID
            therapyDatabaseReference.child("heartrate").setValue(recordTherapyStats.lastUpDateTherapyHeartRate)
            therapyDatabaseReference.child("reps").setValue(recordTherapyStats.totalTherapyReps)
            therapyDatabaseReference.child("time").setValue(recordTherapyStats.therapyTimerLabel.text ?? "ERROR")
            therapyDatabaseReference.child("stretch").setValue(recordTherapyStats.therapyStretchChosen)

            
            let therapyDateFormatter = DateFormatter()
            therapyDateFormatter.timeStyle = .short
            therapyDateFormatter.dateStyle = .medium
            therapyDatabaseReference.child("date").setValue(therapyDateFormatter.string(from:recordTherapyStats.startDate))
            
    allTherapyVideos.append(TherapyVideo(heartRate: Double(recordTherapyStats.lastUpDateTherapyHeartRate), numReps: recordTherapyStats.totalTherapyReps, time: recordTherapyStats.therapyTimerLabel.text ?? "ERROR", stretch: recordTherapyStats.therapyStretchChosen, therapyVideoID: recordTherapyStats.therapyVideoUUID, date: therapyDateFormatter.string(from:recordTherapyStats.startDate)))
    DispatchQueue.main.async {
        therapyHomeScreen?.tableView.reloadData()
    }
        
//        }
//    })

}

// Auth Functions
func therapySignInGoogle(linkedTherapistID: String, therapyPresentingViewController: TherapySignInViewController, therapyCompletionSignIn: @escaping (Bool) -> ()) {
    guard let therapyClientID = FirebaseApp.app()?.options.clientID else { return }
    
    let therapyGoogleSignInConfig = GIDConfiguration(clientID: therapyClientID)
    
    GIDSignIn.sharedInstance.signIn(with: therapyGoogleSignInConfig, presenting: therapyPresentingViewController) { user, error in
        
        if error == nil {
            guard let therapyUserIDAuthentication = user?.authentication else { return }
            guard let therapyUserIDToken = therapyUserIDAuthentication.idToken else { return }
            
            
            let therapyCredentialUser = GoogleAuthProvider.credential(withIDToken: therapyUserIDToken, accessToken: therapyUserIDAuthentication.accessToken)
            
            Auth.auth().signIn(with: therapyCredentialUser) { therapyAuthenticationResult, therapyError in
                
                if error == nil {
                    guard let therapyAuthenticationUser = GIDSignIn.sharedInstance.currentUser else { return }
                    
                    therapyGoogleUser = therapyAuthenticationUser
                    
                    if !linkedTherapistID.isEmpty {
                        setPatientDoctor(therapistID: linkedTherapistID, completionPatientDoctor: { didFindDoctor in
                            if didFindDoctor {
                                
                                getPatientPossibleStretches()
                                
                                // Adds the exercises subfolder
            //                    setPatientReference()
                                therapyDatabaseReference.root.child("patients").child(therapyGoogleUser?.userID ?? "ERROR").getData(completion: { therapyExercisesCheckError, therapyExercisesCheckDataSnapshot in
                                    if !therapyExercisesCheckDataSnapshot.hasChild("exercises") {
                                        therapyDatabaseReference.root.child("patients").child(therapyGoogleUser?.userID ?? "ERROR").child("exercises").child("exercise").setValue(["PLACEHOLDER REMOVE"])

                                    }
                                })
                                    
                                gatherAllTherapyVideoData()
                                getTherapyUserInfo()
                                
                                DispatchQueue.main.async {
                                    therapyPresentingViewController.performSegue(withIdentifier: "enterMainAppUserSignedIn", sender: therapyPresentingViewController)
                                }
                                therapyCompletionSignIn(true)
                            }
                            else {
                                GIDSignIn.sharedInstance.signOut()
                                therapyCompletionSignIn(false)
                            }
                           
                            
                        })
                    }
               
                }
                
            }
        }
    }
}

func therapyRestoreSignIn(therapyPresentingViewController: TherapySignInViewController) {
    GIDSignIn.sharedInstance.restorePreviousSignIn { therapyGoogleUserRestored, therapyGoogleUserError in
        if therapyGoogleUserError == nil {
            
            guard let therapyUserAuthentication = therapyGoogleUserRestored else { return }

            therapyGoogleUser = therapyUserAuthentication

            
            getPatientPossibleStretches()
            
            gatherAllTherapyVideoData()
            getTherapyUserInfo()
            
            DispatchQueue.main.async {
                therapyPresentingViewController.performSegue(withIdentifier: "enterMainAppUserSignedIn", sender: therapyPresentingViewController)
            }
        }
    }
}


// Cloud Storage

var therapyStoreageReference = Storage.storage().reference()
func uploadTherapyVideosStorage(therapyVideoFile: URL, therapyVideoUUID: String, recordTherapyStats: RecordTherapyViewController) {
    
    guard let therapyGoogleUserUnwrapped = therapyGoogleUser else { return }
    
    therapyStoreageReference = therapyStoreageReference.root().child("\(therapyGoogleUserUnwrapped.userID ?? "ERROR")/\(therapyVideoUUID).mp4")
    therapyStoreageReference.putFile(from: therapyVideoFile, metadata: nil) { therapyFileUploadMetaData, therapyFileUploadError in
        if therapyFileUploadError == nil {
            uploadVideoStatistics(recordTherapyStats: recordTherapyStats)
        }
    }
    
}


var allTherapyVideos = [TherapyVideo]()

func gatherAllTherapyVideoData() {
    allTherapyVideos.removeAll()
    therapyDatabaseReference.root.child("patients").child(therapyGoogleUser?.userID ?? "ERROR").child("stats").getData { therapyVideosError, therapyVideosDataSnapshot in
        if therapyVideosError == nil {
            let allTherapyVideosDataSnapshot = therapyVideosDataSnapshot.children.allObjects as? [DataSnapshot] ?? []
            for oneTherapyVideosDataSnapshot in allTherapyVideosDataSnapshot {
                let allTherapyVideosStatsDataSnapshot = oneTherapyVideosDataSnapshot.children.allObjects as? [DataSnapshot] ?? []
                
                
                var averageHeartRate = 0.0
                var numReps = 0
                var time = ""
                var stretch = ""
                var date = ""

                for allTherapyVideoStats in allTherapyVideosStatsDataSnapshot {
                    if allTherapyVideoStats.key == "date" {
                        date = allTherapyVideoStats.value as? String ?? "ERROR_DATE"
                    }
                    else if allTherapyVideoStats.key == "stretch" {
                        stretch = allTherapyVideoStats.value as? String ?? "ERROR_STRETCH"
                    }
                    else if allTherapyVideoStats.key == "time" {
                        time = allTherapyVideoStats.value as? String ?? "ERROR_TIME"
                    }
                    else if allTherapyVideoStats.key == "heartrate" {
                        averageHeartRate = allTherapyVideoStats.value as? Double ?? 0.0
                    }
                    else if allTherapyVideoStats.key == "reps" {
                        numReps = allTherapyVideoStats.value as? Int ?? 0
                    }
                }
                
                let oneTherapyVideoObject = TherapyVideo(heartRate: averageHeartRate, numReps: numReps, time: time, stretch: stretch, therapyVideoID: oneTherapyVideosDataSnapshot.key, date: date)
                allTherapyVideos.append(oneTherapyVideoObject)
            }
            
            therapyHomeScreen?.tableView.reloadData()
            therapyHomeScreen?.tableView.refreshControl?.endRefreshing()
        }
    }
    
}

func downloadTherapyVideo(therapyVideoID: String, therapyVideoURL: URL) {
   
    therapyStoreageReference.root().child(therapyGoogleUser?.userID ?? "ERROR").child("\(therapyVideoID).mp4").write(toFile: therapyVideoURL) { downloadedTherapyFile, downloadedTherapyFileError in
        if downloadedTherapyFileError == nil {
            therapyHomeScreen?.showTherapyCurrentDownloadedVideo()
        }
    }
}
