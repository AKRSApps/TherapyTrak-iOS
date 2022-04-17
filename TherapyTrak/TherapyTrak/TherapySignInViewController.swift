//
//  TherapySignInViewController.swift
//  TherapyTrak
//
//  Created by Krish Iyengar on 4/16/22.
//

import UIKit
import SwiftUI
import Firebase
import GoogleSignIn


var therapyGoogleUser: GIDGoogleUser? = nil
var allPossibleTherapyStretch = [String]()

class TherapySignInViewController: UIViewController {
    
    var loginScreenTherapy: LoginScreenTherapy? = nil
    var therapistPatientTherapy: TherapistPatient? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        therapistPatientTherapy = TherapistPatient(therapyPresentingLoginViewController: self)
        loginScreenTherapy = LoginScreenTherapy(therapyPresentingLoginViewController: self)

    }
    override func viewDidAppear(_ animated: Bool) {
        if !GIDSignIn.sharedInstance.hasPreviousSignIn() {
            performSegue(withIdentifier: "showTherapyGoogleSignin", sender: self)
        }
        else {
            therapyRestoreSignIn(therapyPresentingViewController: self)
        }

    }
    @IBSegueAction func therapySignInShowSwiftUI(_ coder: NSCoder) -> UIViewController? {
        let therapyHostingController = UIHostingController(coder: coder, rootView: therapistPatientTherapy)
        return therapyHostingController
        
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
