//
//  TherapistPatient.swift
//  TherapyTrak
//
//  Created by Krish Iyengar on 4/16/22.
//

import SwiftUI
import WebKit

struct TherapistPatient: View {
    
    @State var therapyTherapistWebViewSheet = false
    @State var therapyTherapistLoginSheet = false
    
    var therapyPresentingLoginViewController: TherapySignInViewController

    var body: some View {
       VStack {
            Image("TherapyTrakLogo").resizable().frame(width: 400, height: 300, alignment: .center)
               .padding(.bottom, 20)
           
           Button {
               therapyTherapistLoginSheet = true
           } label: {
               HStack {
                   Image(systemName: "person.fill").resizable().frame(width: 25, height: 25, alignment: .center).padding(.trailing, 7.5)
                   Text("Patient")
               }
           }
           .frame(width: 235, height: 50, alignment: .center)
           .cornerRadius(10)
           .background(Color(red: 0.329, green: 0.267, blue: 0.533))
           .foregroundColor(Color.white)
           .cornerRadius(10)
           .padding(.bottom, 10)
           .fullScreenCover(isPresented: $therapyTherapistLoginSheet) {
               LoginScreenTherapy(therapyPresentingLoginViewController: therapyPresentingLoginViewController)

           }
           .padding(.bottom, 50)
           
          
           Button {
               therapyTherapistWebViewSheet = true
           } label: {
               HStack {
                   Image(systemName: "heart.fill").resizable().frame(width: 25, height: 25, alignment: .center).padding(.trailing, 7.5)
                   Text("Therapist")
               }
           }
           .frame(width: 235, height: 50, alignment: .center)
           .cornerRadius(10)
           .background(Color(red: 0.329, green: 0.267, blue: 0.533))
           .foregroundColor(Color.white)
           .cornerRadius(10)
           .fullScreenCover(isPresented: $therapyTherapistWebViewSheet) {
               TherapyTherapistWebView()

           }
           
            Spacer()
       }
    }
}


struct TherapyTherapistWebView: UIViewRepresentable {
    let therapyWebView = WKWebView()
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
    
    }
    func makeUIView(context: Context) -> WKWebView {
        guard let therapistWebView = URL(string: "https://sashankbalusu.github.io/therapyTrak/") else { return therapyWebView }
        therapyWebView.load(URLRequest(url: therapistWebView))
        return therapyWebView
    }
}

struct TherapistPatient_Previews: PreviewProvider {
    static var previews: some View {
//        TherapistPatient()
        Text("Hello Woreld")
    }
}
