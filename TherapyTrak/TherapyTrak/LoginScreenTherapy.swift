//
//  LoginScreenTherapy.swift
//  TherapyTrak
//
//  Created by Krish Iyengar on 4/15/22.
//

import SwiftUI
import GoogleSignIn
import Firebase
import FirebaseAuth

struct LoginScreenTherapy: View {
    
    @State var therapyLoginCode: String = ""
    var therapyPresentingLoginViewController: TherapySignInViewController
    
    @FocusState var shouldFocusInputCodeKeyboard
    @State var shouldShowTherapyAlert: Bool = false
    
    var body: some View {
        VStack {
            Image("TherapyTrakLogo").resizable().frame(width: 400, height: 300, alignment: .center)
            
            TextField("Enter Code", text: $therapyLoginCode)
                .frame(width: 225, height: 50, alignment: .center)
                .padding(.leading, 10)
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color(red: 0.329, green: 0.267, blue: 0.533)))
                .cornerRadius(10)
                .padding(.bottom, 50)
                .focused($shouldFocusInputCodeKeyboard)
                .keyboardType(.numberPad)
            
           
            Button {
                therapySignInGoogle(linkedTherapistID: therapyLoginCode, therapyPresentingViewController: therapyPresentingLoginViewController, therapyCompletionSignIn: { therapySuccesffullLogin in
                    if !therapySuccesffullLogin {
                        shouldFocusInputCodeKeyboard = false

                        shouldShowTherapyAlert = true

                    }
                    
                })
            } label: {
                HStack {
                    Image("Therapy_Google_Logo").resizable().frame(width: 25, height: 25, alignment: .center).padding(.trailing, 7.5)
                    Text("Sign in with Google")
                }
            }
            .frame(width: 235, height: 50, alignment: .center)
            .cornerRadius(10)
            .background(Color(red: 0.329, green: 0.267, blue: 0.533))
            .foregroundColor(Color.white)
            .cornerRadius(10)
            .alert("Unable to Find Therapist", isPresented: $shouldShowTherapyAlert) {
                Button("OK", role: .cancel, action: {
                    shouldShowTherapyAlert = false
                })
            }
            Spacer()
        }.onTapGesture {
            shouldFocusInputCodeKeyboard = false
        }
        
    }
    
   
}

struct LoginScreenTherapy_Previews: PreviewProvider {
    static var previews: some View {
//        LoginScreenTherapy(therapyPresentingLoginViewController: UIViewController() as! UIHostingController<LoginScreenTherapy>)
        Text("Hello World")
    }
}
