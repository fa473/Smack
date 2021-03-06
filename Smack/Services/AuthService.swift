//
//  AuthService.swift
//  Smack
//
//  Created by home on 12/28/17.
//  Copyright © 2017 home. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class AuthService {
    static let instance = AuthService()

    let defaults = UserDefaults.standard

    var isLoggedIn: Bool {
        get {
            return defaults.bool(forKey: LOGGED_IN_KEY)
        }
        set {
            defaults.set(newValue, forKey: LOGGED_IN_KEY)
        }
    }

    var authToken: String {
        get {
            return defaults.value(forKey: TOKEN_KEY) as? String ?? ""
        }
        set {
            defaults.set(newValue, forKey: TOKEN_KEY)
        }
    }

    var userEmail: String {
        get {
            return defaults.value(forKey: USER_EMAIL) as? String ?? ""
        }
        set {
            defaults.set(newValue, forKey: USER_EMAIL)
        }
    }

    // Creates a new user account
    func createUser(name: String, email: String, password: String, avatarName: String,
                    avatarColor: String, completion: @escaping CompletionHandler) {

        let lowerCaseEmail = email.lowercased()

        // Prepare request body
        let body: [String: Any] = [
            "name": name,
            "email": lowerCaseEmail,
            "password": password,
            "avatarName": avatarName,
            "avatarColor": avatarColor
        ]

        // Send request to user route and parse response
        Alamofire.request(URL_USER_ADD, method: .post, parameters: body,
                          encoding: JSONEncoding.default,
                          headers: BEARER_HEADER).responseJSON { (response) in
            if response.result.error == nil {
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data: data)
                    UserDataService.instance.setUserData(id: json["_id"].stringValue,
                                                         avatarColor: avatarColor,
                                                         avatarName: avatarName,
                                                         email: email,
                                                         name: name)
                } catch {
                    debugPrint(error)
                }

                completion(true)
            } else {
                completion(false)
                debugPrint(response.result.error as Any)
            }
        }
    }

    // Check user credentials and receive auth token
    func loginUser(email: String, password: String,
                   completion: @escaping CompletionHandler) {

        let lowerCaseEmail = email.lowercased()

        let body: [String: Any] = [
            "strategy": "local",
            "email": lowerCaseEmail,
            "password": password
        ]

        Alamofire.request(URL_LOGIN, method: .post, parameters: body, encoding: JSONEncoding.default, headers: HEADER).responseJSON { (response) in
            if response.result.error == nil {
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data: data)
                    self.userEmail = json["email"].stringValue
                    self.authToken = json["accessToken"].stringValue
                } catch {
                    debugPrint(error)
                }
                self.isLoggedIn = true
                completion(true)
            } else {
                completion(false)
                debugPrint(response.result.error as Any)
            }
        }

    }

    // find user info by email and then set user data with response
    func findUserByEmail(completion: @escaping CompletionHandler) {
        Alamofire.request("\(URL_USER_BY_EMAIL)?email=\(userEmail)", method: .get, parameters: nil,
                          encoding: JSONEncoding.default,
                          headers: BEARER_HEADER).responseJSON { (response) in
            if response.result.error == nil {
                guard let data = response.data else { return }
                do {
                    let json = try JSON(data: data)
                    let user = json["data"][0]
                    // Parse JSON
                    let id = user["_id"].stringValue
                    let avatarColor = user["avatarColor"].stringValue
                    let avatarName = user["avatarName"].stringValue
                    let email = user["email"].stringValue
                    let name = user["name"].stringValue
                    // Populate user info
                    UserDataService.instance.setUserData(id: id,
                                                         avatarColor: avatarColor,
                                                         avatarName: avatarName,
                                                         email: email,
                                                         name: name)
                } catch {
                    debugPrint(error)
                }
                completion(true)
            } else {
                completion(false)
                debugPrint(response.result.error as Any)
            }
        }
    }

}

