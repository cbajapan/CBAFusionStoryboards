//
//  ViewController.swift
//  CBAFusionStoryboards
//
//  Created by Cole M on 7/21/23.
//

import UIKit
import FCSDKiOS
import OSLog

class AuthenticationViewController: UIViewController {

    
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    
    @IBOutlet var serverTextField: UITextField!
    @IBOutlet var portTextField: UITextField!
    
//    let logger = Logger(subsystem: "CBAFusion", category: "CBAFusion")
    var sessionExists = false
    var acbuc: ACBUC?
    var uc: ACBUC? {
        didSet {
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.acbuc = self.uc
            }
        }
    }
    var showErrorAlert: Bool = false
    var errorMessage: String = ""
    var showSettingsSheet = false
    var showProgress: Bool = false
    var networkRepository: NetworkRepository?
    var sessionID = ""
    var connectedToSocket = false
    var connection = false {
        didSet {
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.connectedToSocket = self.connection
            }
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.networkRepository = NetworkRepository()
        self.networkRepository?.networkRepositoryDelegate = networkRepository
        dismissKeyboard()
    }

    @IBAction func loginButton(_ sender: Any) {
        Task {
            await loginUser(networkStatus: true)
        }
    }
    
    func requestLoginObject() -> LoginRequest {
        return LoginRequest(
            username: "1001",
            password: "123"
        )
    }
    
    @MainActor
    func loginUser(networkStatus: Bool) async {
        let loginCredentials = Login(
            username: usernameTextField.text ?? "",
            password: passwordTextField.text ?? "",
            server: serverTextField.text ?? "",
            port: portTextField.text ?? "",
            secureSwitch: true,
            useCookies: true,
            acceptUntrustedCertificates: true
        )
        
        do {
            guard let repository = networkRepository?.networkRepositoryDelegate else {return}
            let (data, response) = try await repository.asyncLogin(loginReq: loginCredentials, reqObject: requestLoginObject())
            let payload = try JSONDecoder().decode(LoginResponse.self, from: data)
            await fireStatus(response: response)
            
            self.sessionID = payload.sessionid
            await self.createSession(sessionid: payload.sessionid, networkStatus: networkStatus)
        
        } catch {
            await errorCaught(error: error)
//            self.logger.error("Error Logging in Error: \(error.localizedDescription)")
        }
    }
    
    func errorCaught(error: Error) async {
        await showAlert(error: error)
    }
    
    @MainActor
    func fireStatus(response: URLResponse) async {
        guard let httpResponse = response as? HTTPURLResponse else {return}
        switch httpResponse.statusCode {
        case 200...299:
break
        case 401:
            await showAlert(response: httpResponse)
        case 402...500:
            await showAlert(response: httpResponse)
        case 501...599:
            await showAlert(response: httpResponse)
        case 600:
            await showAlert(response: httpResponse)
        default:
            await showAlert(response: httpResponse)
        }
    }
    
    @MainActor
    func showAlert(response: HTTPURLResponse? = nil, error: Error? = nil) async {
        var message: String = "No Message"
        if response == nil {
            message = error?.localizedDescription ?? "Error string empty"
        } else {
            message = "\(String(describing: response))"
        }
        self.errorMessage = message
        self.showErrorAlert = true
    }
    
    /// Create the Session
    func createSession(sessionid: String, networkStatus: Bool) async {
        self.uc = await ACBUC.uc(withConfiguration: sessionid, delegate: self)
        await self.uc?.setNetworkReachable(networkStatus)
        self.uc?.acceptAnyCertificate(true)
        self.uc?.useCookies = true
        Task.detached {
            await self.uc?.startSession()
        }
        self.connection = self.uc?.connection != nil
            
        await MainActor.run {
            self.sessionExists = true
        }
        
        performSegue(withIdentifier: "presentCommunication", sender: self)
    }

    
    /// Logout and stop the session
    func logout() async {
//        self.logger.info("Logging out of server: \(self.serverTextField.text ?? "") with: \(self.usernameTextField.text ?? "")")
        await MainActor.run {
        self.showProgress = true
        }
        let loginCredentials = Login(
            username: usernameTextField.text ?? "1001",
            password: passwordTextField.text ?? "123",
            server: serverTextField.text ?? "",
            port: portTextField.text ?? "",
            secureSwitch: true,
            useCookies: true,
            acceptUntrustedCertificates: true
        )
        await stopSession()
        do {
            guard let repository = networkRepository?.networkRepositoryDelegate else {return}
            let response = try await repository.asyncLogout(logoutReq: loginCredentials, sessionid: self.sessionID)
            await setSessionID(id: sessionID)
            
            await fireStatus(response: response)
            await MainActor.run {
                self.sessionExists = false
                self.acbuc = nil
            }
        } catch {
            await errorCaught(error: error)
//            self.logger.error("\(error.localizedDescription)")
            await MainActor.run {
                self.showProgress = false
            }
        }
    }
    
    func stopSession() async {
        await self.uc?.stopSession()
    }
    
    @MainActor
    func setSessionID(id: String) async {
        self.connectedToSocket = self.uc?.connection != nil
        sessionID = id
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! CommunicationViewController
        destinationVC.acbuc = self.acbuc
    }
}


extension AuthenticationViewController: ACBUCDelegate {
    func didStartSession(_ uc: ACBUC) async {
//        self.logger.info("Started Session \(String(describing: uc))")
    }
    
    func didFail(toStartSession uc: ACBUC) async {
//        self.logger.info("Failed to start Session \(String(describing: uc))")
    }
    
    func didReceiveSystemFailure(_ uc: ACBUC) async {
//        self.logger.info("Received system failure \(String(describing: uc))")
    }
    
    func didLoseConnection(_ uc: ACBUC) async {
//        self.logger.info("Did lose connection \(String(describing: uc))")
    }
    
    func uc(_ uc: ACBUC, willRetryConnection attemptNumber: Int, in delay: TimeInterval) async {
//        self.logger.info("We are trying to reconnect to the network \(uc), \(attemptNumber), \(delay)")
            await self.uc?.startSession()
            await MainActor.run {
            self.sessionExists = true
        }
    }
    
    func ucDidReestablishConnection(_ uc: ACBUC) {
//        self.logger.info("We restablished Network Connectivity \(uc)")
    }
}


extension UIViewController {
func dismissKeyboard() {
       let tap: UITapGestureRecognizer = UITapGestureRecognizer( target:     self, action:    #selector(UIViewController.dismissKeyboardTouchOutside))
       tap.cancelsTouchesInView = false
       view.addGestureRecognizer(tap)
    }
    
    @objc private func dismissKeyboardTouchOutside() {
       view.endEditing(true)
    }
}
