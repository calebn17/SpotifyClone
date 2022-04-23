//
//  APICaller.swift
//  SpotifyClone
//
//  Created by Caleb Ngai on 3/30/22.
//

import Foundation

final class APICaller {
    
    //Creating a Singleton
    static let shared = APICaller()
    private init() {}
    //
    
    struct Constants {
        static let baseAPIURL = "https://api.spotify.com/v1"
    }
    
    enum APIError: Error {
        case failedToGetData
    }
    
//MARK: - Albums
    
    public func getAlbumDetails(for album: Album, completion: @escaping (Result<AlbumDetailsResponse, Error>) -> Void) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/albums/" + album.id), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                do {
                    let result = try JSONDecoder().decode(AlbumDetailsResponse.self, from: data)
                    //passing the result data as a Success value into the completion handler. Makes it easier to verfiy that API call worked.
                    completion(.success(result))
                    
                }
                catch {
                    //passing the error to the completion handler
                    completion(.failure(error))
                }
            }
            task.resume()
            
        }
    }
    
//MARK: - Playlists
    
    public func getPlaylistDetails(for playlist: Playlist, completion: @escaping (Result<PlaylistDetailsResponse, Error>) -> Void) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/playlists/" + playlist.id), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                do {
                    let result = try JSONDecoder().decode(PlaylistDetailsResponse.self, from: data)
                    //passing the result data as a Success value into the completion handler. Makes it easier to verfiy that API call worked.
                    completion(.success(result))
                                    }
                catch {
                    //passing the error to the completion handler
                    completion(.failure(error))
                }
            }
            task.resume()
            
        }
    }
    
    public func getCurrentUserPlaylists(completion: @escaping (Result<[Playlist], Error>) -> Void) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/me/playlists/?limit=50"), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                do {
                    let result = try JSONDecoder().decode(LibraryPlaylistsResponse.self, from: data)
                    //passing the result data as a Success value into the completion handler. Makes it easier to verfiy that API call worked.
                    //setting value of completion handler to result.items because we want an [Playlists]
                    completion(.success(result.items))
                }
                catch {
                    //passing the error to the completion handler
                    completion(.failure(error))
                }
            }
            task.resume()
            
        }
    }
    public func createPlaylists(with name: String, completion: @escaping (Bool) -> Void) {
        
    }
    public func addTrackToPlaylists(track: AudioTrack, playlist: Playlist, completion: @escaping (Bool) -> Void) {
        
    }
    public func removeTrackFromPlaylists(track: AudioTrack, playlist: Playlist, completion: @escaping (Bool) -> Void) {
        
    }
    
    
//MARK: - Profile
    
    //Using Result container to store UserProfile
    public func getCurrentUserProfile(completion: @escaping (Result<UserProfile, Error>) -> Void) {
        
        //Calling the reusable function
        createRequest(with: URL(string: Constants.baseAPIURL + "/me") , type: .GET) { baseRequest in
            let task = URLSession.shared.dataTask(with: baseRequest) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                do {
                    //Use the below line to see what the returned json looks like to create the data model for it
                    //let result = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
                    
                    let result = try JSONDecoder().decode(UserProfile.self, from: data)
                    //passing the result data as a Success value into the completion handler. Makes it easier to verfiy that API call worked.
                    completion(.success(result))
                }
                catch {
                    //passing the error to the completion handler
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }

//MARK: - Browse
    
    public func getNewReleases(completion: @escaping ((Result<NewReleasesResponse, Error>)) -> Void) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/browse/new-releases?limit=50"), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                do {
                    let result = try JSONDecoder().decode(NewReleasesResponse.self, from: data)
                    completion(.success(result))
                }
                catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    
    public func getFeaturedPlaylists(completion: @escaping ((Result<FeaturedPlaylistsResponse, Error>) -> Void)){
        createRequest(with: URL(string: Constants.baseAPIURL + "/browse/featured-playlists?limit=50"), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                do {
                    let result = try JSONDecoder().decode(FeaturedPlaylistsResponse.self, from: data)
                    completion(.success(result))
                }
                catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    
    public func getRecommendations(genres: Set<String>, completion: @escaping ((Result<RecommendationsResponse, Error>) -> Void)){
        let seeds = genres.joined(separator: ",")
        createRequest(with: URL(string: Constants.baseAPIURL + "/recommendations?limit=2&seed_genres=\(seeds)"), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                do {
                    let result = try JSONDecoder().decode(RecommendationsResponse.self, from: data)
                    completion(.success(result))
                }
                catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    
    public func getRecommendedGenres(completion: @escaping ((Result<RecommendedGenresResponse, Error>) -> Void)){
        createRequest(with: URL(string: Constants.baseAPIURL + "/recommendations/available-genre-seeds"), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                do {
                    let result = try JSONDecoder().decode(RecommendedGenresResponse.self, from: data)
                    completion(.success(result))
                }
                catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    
//MARK: - Categories
    
    public func getCategories(completion: @escaping (Result<AllCategoriesResponse, Error>) -> Void) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/browse/categories?limit=50"), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                do {
                    let result = try JSONDecoder().decode(AllCategoriesResponse.self, from: data)
                    completion(.success(result))
                }
                catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    
    public func getCategoryPlaylist(category: Category, completion: @escaping (Result<CategoriesPlaylistsResponse, Error>) -> Void) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/browse/categories/\(category.id)/playlists?limit=50"), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                do {
                    let result = try JSONDecoder().decode(CategoriesPlaylistsResponse.self, from: data)
                    completion(.success(result))
                }
                catch {
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    
//MARK: - Search
    
    public func search(with query: String, completion: @escaping (Result<[SearchResult], Error>) -> Void) {
        createRequest(with: URL(string: Constants.baseAPIURL + "/search?limit=10&type=album,artist,playlist,track&q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"), type: .GET) { request in
            let task = URLSession.shared.dataTask(with: request) { data, _, error in
                guard let data = data, error == nil else {
                    completion(.failure(APIError.failedToGetData))
                    return
                }
                do {
                    let result = try JSONDecoder().decode(SearchResultsResponse.self, from: data)
                    
                    //Storing the parsed results in this array of SearchResult
                    var searchResults: [SearchResult] = []
                    //Taking the non nil elements of each type and putting it into each case of the SearchResult enum
                    searchResults.append(contentsOf: result.tracks.items.compactMap({.track(model: $0)}))
                    searchResults.append(contentsOf: result.albums.items.compactMap({.album(model: $0)}))
                    searchResults.append(contentsOf: result.artists.items.compactMap({.artist(model: $0)}))
                    searchResults.append(contentsOf: result.playlists.items.compactMap({.playlist(model: $0)}))
                   
                    completion(.success(searchResults))
                }
                catch {
                    print(error.localizedDescription)
                    completion(.failure(error))
                }
            }
            task.resume()
        }
    }
    
//MARK: - Private Methods
    
    enum HTTPMethod: String {
        case GET
        case POST
    }
    
    ///Reusable function for making API requests. Returns a URL Request
    private func createRequest(with url: URL?, type: HTTPMethod, completion: @escaping (URLRequest) -> Void) {
        
        //Getting the valid access token from AuthManager and making the request
        AuthManager.shared.withValidToken { token in
            
            guard let apiURL = url else {return}
            
            var request = URLRequest(url: apiURL)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpMethod = type.rawValue
            request.timeoutInterval = 30
            completion(request)
        }
        
        
    }
}
