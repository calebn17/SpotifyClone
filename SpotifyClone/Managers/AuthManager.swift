//
//  AuthManager.swift
//  SpotifyClone
//
//  Created by Caleb Ngai on 3/30/22.
//

import Foundation

final class AuthManager {

//MARK: - Setup
    
    //creating a shared instance of AuthManager so we dont have to create a new one all the time
    static let shared = AuthManager()
    
    private var refreshingToken = false
    
    struct Constants {
        static let clientID = "264a497549414d0697df32884516ab41"
        static let clientSecret = "79401374bee94a0e9dfe15114f7aa532"
        static let tokenAPIURL = "https://accounts.spotify.com/api/token"
        static let redirectURI = "https://www.iosacademy.io"
        static let scopes = "user-read-private%20playlist-modify-public%20playlist-read-private%20playlist-modify-private%20user-follow-read%20user-library-modify%20user-library-read%20user-read-email"
    }
    
    private init() {}
    
    //creating the URL for signing in
    public var signInURL: URL? {
        
        let base = "https://accounts.spotify.com/authorize"
        
        let stringURL = "\(base)?response_type=code&client_id=\(Constants.clientID)&scope=\(Constants.scopes)&redirect_uri=\(Constants.redirectURI)&show_dialog=TRUE"
        return URL(string: stringURL)
    }
    
    //tells the App Delegate whether user is signed in or not
    var isSignedIn: Bool {
        return accessToken != nil
    }
 
//MARK: - Cached Token Variables
    //returns cached access token
    private var accessToken: String? {
        return UserDefaults.standard.string(forKey: "access_token")
    }
    
    //returns cached refreshed token
    private var refreshToken: String? {
        return UserDefaults.standard.string(forKey: "refresh_token")
    }
    
    //returns cached token expiration date
    private var tokenExpirationDate: Date? {
        return UserDefaults.standard.object(forKey: "expirationDate") as? Date
    }
    
    //logic controlling if the app should refresh the access token
    private var shouldRefreshToken: Bool {
        guard let expirationDate = tokenExpirationDate else {return false}
        let currentDate = Date()
        let fiveMinutes: TimeInterval = 300
        //if there is 5 min left until expiration date then -> true
        return currentDate.addingTimeInterval(fiveMinutes) >= expirationDate
    }

    //MARK: - Token API Methods
    
    //Called in the AuthViewController
    public func exchangeCodeForToken(code: String, completion: @escaping ((Bool) -> Void)) {
        //Get Token
        guard let url = URL(string: Constants.tokenAPIURL) else {return}
        
        //sets the url query parameters needed to get the token
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
        ]
        
        //making a POST request using the url to grab the token
        //creating the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        //required by Spotify APIs
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        //creating the token and encoding it using base 64
        let basicToken = Constants.clientID + ":" + Constants.clientSecret
        let data = basicToken.data(using: .utf8)
        guard let base64String = data?.base64EncodedString() else {
            completion(false)
            print("failure to get base64")
            return
        }
        //Putting the request all together with the encoded token, authorization header, and all the query params
        //setting the encoded token value to the request
        request.setValue("Basic \(base64String)", forHTTPHeaderField: "Authorization")
        //attaching the query params
        request.httpBody = components.query?.data(using: .utf8)
        //creating the session for the api call
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            
            guard let data = data, error == nil else {
                completion(false)
                return
            }
            do {
                //decoding it with the AuthResponse data model
                let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                //cache the token with this method that is declared below
                self?.cacheToken(result: result)
                completion(true)
            } catch {
                print(error.localizedDescription)
                completion(false)
            }
        }
        task.resume()
    }
    
    //Storing completion blocks to prevent redundancy
    private var onRefreshBlocks = [((String) -> Void)]()
    
    ///Supplies valid token to be used with API calls
    public func withValidToken(completion: @escaping (String) -> Void) {
        
        //if app isn't currently refreshing a token then append completion in onRefreshBlocks
        guard !refreshingToken else {
            //Append the completion
            onRefreshBlocks.append(completion)
            return
        }
        //if app needs to refresh token then refresh
        if shouldRefreshToken {
            //Refresh
            refreshIfNeeded { [weak self] success in
                if let token = self?.accessToken, success {
                        completion(token)
                }
            }
        }
        //if app doesn't need to refresh the token then grab it and passs it to the completion handler
        else if let token = accessToken {
            completion(token)
        }
    }
    
    //called to refresh the token
    public func refreshIfNeeded(completion: ((Bool) -> Void)?) {
        
        //checks if app is not currently refreshing token
        guard !refreshingToken else {return}
        //if token needs to be refresh then let's refresh. If not, then pass it to the completion handler
        guard shouldRefreshToken else {
            completion?(true)
            return
        }
        
        //checking to see if we have a refresh token that is needed to get a new access token
        guard let refreshToken = self.refreshToken else {return}
        
        ///Refresh the token
        //this code is very similar to the initial API call but with some small differences
        guard let url = URL(string: Constants.tokenAPIURL) else {return}
        
        //we are now in the process of refreshing the access token
        refreshingToken = true
        
        var components = URLComponents()
        components.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken),
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        //this is from the docs
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let basicToken = Constants.clientID + ":" + Constants.clientSecret
        let data = basicToken.data(using: .utf8)
        guard let base64String = data?.base64EncodedString() else {
            completion?(false)
            print("failure to get base64")
            return
            
        }
        request.setValue("Basic \(base64String)", forHTTPHeaderField: "Authorization")
        request.httpBody = components.query?.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            self?.refreshingToken = false
            guard let data = data, error == nil else {
                completion?(false)
                return
            }
            do {
                //decoding it with the AuthResponse data model
                let result = try JSONDecoder().decode(AuthResponse.self, from: data)
                
                //passing the new access token to the saved completion block
                self?.onRefreshBlocks.forEach { $0(result.access_token) }
                self?.onRefreshBlocks.removeAll()
                //caching the refreshed result
                self?.cacheToken(result: result)
                completion?(true)
            } catch {
                print(error.localizedDescription)
                completion?(false)
            }
        }
        task.resume()
    }

//MARK: - Cache Method
    
    //Caching the token in User Defaults
    private func cacheToken(result: AuthResponse) {
        UserDefaults.standard.setValue(result.access_token, forKey: "access_token")
        
        if let refresh_token = result.refresh_token {
            UserDefaults.standard.setValue(refresh_token, forKey: "refresh_token")
        }
        //caching the expiration date
        UserDefaults.standard.setValue(Date().addingTimeInterval(TimeInterval(result.expires_in)), forKey: "expirationDate")
    }
    
    public func signOut(completion: (Bool) -> Void) {
        
        UserDefaults.standard.setValue(nil, forKey: "access_token")
        
        UserDefaults.standard.setValue(nil, forKey: "refresh_token")
        
        UserDefaults.standard.setValue(nil, forKey: "expirationDate")
        
        completion(true)
    }
}
