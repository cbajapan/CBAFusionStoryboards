//
//  NetworkRepository.swift
//  CBAFusionStoryboards
//
//  Created by Cole M on 7/21/23.
//


import Foundation

protocol NetworkRepositoryDelegate: AnyObject {
    
    func asyncLogin(loginReq: Login, reqObject: LoginRequest) async throws -> (Data, URLResponse)
    func asyncLogout(logoutReq: Login, sessionid: String) async throws -> URLResponse
}

class NetworkRepository: NetworkRepositoryDelegate {

    let networkManager = NetworkManager()
    weak var networkRepositoryDelegate: NetworkRepositoryDelegate?
    
    func asyncLogin(loginReq: Login, reqObject: LoginRequest) async throws -> (Data, URLResponse) {
        let scheme = loginReq.secureSwitch ? "https" : "http"
        let url = "\(scheme)://\(loginReq.server):\(loginReq.port)/csdk-sample/SDK/login"
        let body = try? JSONEncoder().encode(reqObject)
        return try await networkManager.asyncCodableNetworkWrapper(type: LoginResponse.self, urlString: url, httpMethod: "POST", httpBody: body)
    }
    
    func asyncLogout(logoutReq: Login, sessionid: String) async throws -> URLResponse {
        let scheme = logoutReq.secureSwitch ? "https" : "http"
        let url = "\(scheme)://\(logoutReq.server):\(logoutReq.port)/csdk-sample/SDK/login/id/\(sessionid)"
        return try await networkManager.asyncNetworkWrapper(urlString: url, httpMethod: "DELETE")
    }
    
    enum Errors: Swift.Error {
        case nilResponseError
    }
}

struct Login: Codable {
    var username: String
    var password: String
    var server: String
    var port: String
    var secureSwitch: Bool
    var useCookies: Bool
    var acceptUntrustedCertificates: Bool
}

struct LoginRequest: Codable {
    var username: String
    var password: String
}

struct LoginResponse: Codable {
    var id: UUID?
    var sessionid: String
    var voiceUser: String
    var voiceDomain: String
}

struct LogoutResponse: Codable {
    var response: String
}
