//
//  SettingsView.swift
//  TherapyTrak
//
//  Created by Krish Iyengar on 4/16/22.
//

import SwiftUI
import GoogleSignIn

struct SettingsView: View {
    
    @State var allowNotifications: Bool = true
    @State var notificationDate: Date = Date()
    
    var body: some View {
            VStack {
                Image(uiImage: therapyUserInfo.profilePicture).resizable().clipShape(Circle()).frame(width: 150, height: 150, alignment: .center).shadow(color: .black, radius: 10, x: 0, y: 0)
                    
                Text(therapyUserInfo.name)
                    .font(.title)
                    .bold()
                    .padding(.top, 20)
                    .padding(.bottom, 10)

                Text(therapyUserInfo.email)
                    .font(.title3)
                    .padding()
                Spacer()
                Divider()
                
                Toggle(isOn: $allowNotifications) {
                    Text("Allow Notifications").bold()
                }.padding([.leading, .trailing], 30)
                    .onChange(of: allowNotifications, perform: { therapyNotificationsBool in
                        UserDefaults.standard.removeObject(forKey: "therapyNotificationsOn")
                        UserDefaults.standard.set(therapyNotificationsBool, forKey: "therapyNotificationsOn")
                        
                            therapyHomeScreen?.addTherapyUserNotifications(therapyDate: notificationDate)
                        
                    })
                       
                        
                    
                
                DatePicker("Notification Timings", selection: $notificationDate, displayedComponents: .hourAndMinute).padding([.leading, .trailing], 30).disabled(!allowNotifications).onChange(of: notificationDate, perform: { therapyDate in
                    UserDefaults.standard.removeObject(forKey: "therapyNotificationsDate")
                    UserDefaults.standard.set(notificationDate, forKey: "therapyNotificationsDate")
                    
                        therapyHomeScreen?.addTherapyUserNotifications(therapyDate: notificationDate)
                    
                })

                Divider()
                
                Button {
                    therapyGoogleUser = nil
                    GIDSignIn.sharedInstance.signOut()
                    therapyHomeScreen?.therapySignOutDismiss()
                    
                } label: {
                    Text("Sign Out").bold()
                }
                .frame(width: 150, height: 40, alignment: .center)
                .background(Color(red: 0.329, green: 0.267, blue: 0.533))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .foregroundColor(.white)
                .padding()
                
                Spacer()

            }
        
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
