//
//  CallViewController.swift
//  CBAFusionStoryboards
//
//  Created by Cole M on 7/21/23.
//

import UIKit
import FCSDKiOS
import OSLog
import AVKit

class CallViewController: UIViewController {
    
    @IBOutlet var remoteVideoView: UIView!
    @IBOutlet var localVideoView: UIView!
    
    @IBOutlet var localWidthContraint: NSLayoutConstraint!
    @IBOutlet var localHeightConstraint: NSLayoutConstraint!
    @IBOutlet var localVideoTopConstraint: NSLayoutConstraint!
    @IBOutlet var localVideoBottomConstraint: NSLayoutConstraint!
    @IBOutlet var localVideoTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet var remoteVideoTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var remoteVideoTopConstraint: NSLayoutConstraint!
    @IBOutlet var remoteVideoLeadingConstraint: NSLayoutConstraint!
    
    
    var call: ACBClientCall?
    var acbuc: ACBUC?
    var recipient = ""
//    var logger = Logger(subsystem: "CallViewController", category: "CallViewController")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dismissKeyboard()
        
        // Do any additional setup after loading the view.
        Task {
            await ACBClientPhone.requestMicrophoneAndCameraPermission(true, video: true)
            self.call = try await initializeFCSDKCall()
        }
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
    var isFrontCamera = true
    @IBAction func switchViews(_ sender: Any) {

        Task { @MainActor in
            if isFrontCamera {
                self.acbuc?.phone.setCamera(.back)
                acbuc?.phone.previewView = self.remoteVideoView
                self.call?.remoteView = self.localVideoView
                isFrontCamera = false
            } else {
                self.acbuc?.phone.setCamera(.front)
                acbuc?.phone.previewView = self.localVideoView
                self.call?.remoteView = self.remoteVideoView
                isFrontCamera = true
            }
        }
    }
    
    @IBAction func unwindSegue(_ sender: UIStoryboardSegue) {
        Task {
            await endCall()
        }
    }
    
    func initializeFCSDKCall() async throws -> ACBClientCall? {
        guard let uc = self.acbuc else { throw OurErrors.nilACBUC }
        await setPhoneDelegate(uc)
        Task { @MainActor [weak self] in
            guard let self else { return }
            uc.phone.previewView = self.localVideoView
        }
        
        let outboundCall = await uc.phone.createCall(
            toAddress: self.recipient,
            withAudio: .sendAndReceive,
            video: .sendAndReceive,
            delegate: self
        )
        uc.phone.mirrorFrontFacingCameraPreview = true
        self.call = outboundCall
        self.call?.enableLocalVideo(true)
        
        Task { @MainActor [weak self] in
            guard let self else { return }
            self.call?.remoteView = self.remoteVideoView
        }
        return self.call
    }
    
    func setPhoneDelegate(_ uc: ACBUC) async {
        uc.phone.delegate = self
    }
    
}

extension CallViewController: ACBClientCallDelegate {
    
    
    @MainActor private func endCall() async {
        await call?.end()
    }
    
    
    @MainActor
    func notifyInCall() async {
        //        await self.inCall()
        //        isStreaming = true
    }
    
    func didChange(_ status: ACBClientCallStatus, call: ACBClientCall) async {
        print("STATUS____", status)
        Task { @MainActor in
            //            self.callStatus = status.rawValue
        }
        switch status {
        case .setup:
            break
        case .preparingBufferViews:
            //Just wait a second if we are answering from callkit for the view
            if #available(iOS 16.0, *) {
                try? await Task.sleep(until: .now + .seconds(1), clock: .suspending)
            } else {
                try? await Task.sleep(nanoseconds: NSEC_PER_SEC)
            }
            //            if isBuffer {
            //                await setupBufferViews()
            //            }
        case .alerting:
            await self.alerting()
        case .ringing:
            await ringing()
        case .mediaPending:
            break
        case .inCall:
            await notifyInCall()
        case .timedOut:
            await setErrorMessage(message: "Call timed out")
        case .busy:
            await setErrorMessage(message: "User is Busy")
        case .notFound:
            await setErrorMessage(message: "Could not find user")
        case .error:
            await setErrorMessage(message: "Unkown Error")
        case .ended:
            Task { @MainActor in
                await self.endCall()
            }
        @unknown default:
            break
        }
    }
    
    @MainActor
    func alerting() async {
        //        self.hasStartedConnecting = true
    }
    
    @MainActor
    func inCall() async {
        //        self.isRinging = false
        //        self.hasConnected = true
        //        self.connectDate = Date()
    }
    
    @MainActor
    func ringing() async {
        //        self.hasStartedConnecting = false
        //        self.connectingDate = Date()
        //        self.isRinging = true
    }
    
    @MainActor
    func setErrorMessage(message: String) async {
        //        self.sendErrorMessage = true
        //        self.errorMessage = message
    }
    
    func didReceiveSessionInterruption(_ message: String, call: ACBClientCall) async {
        if message == "Session interrupted" {
            //            if  self.fcsdkCall?.call != nil {
            //                if self.fcsdkCall?.call?.status == .inCall {
            //                    if !self.isOnHold {
            //                        call.hold()
            //                        self.isOnHold = true
            //                    }
            //                }
            //            }
        }
    }
    
    func didReceiveCallFailure(with error: Error, call: ACBClientCall) async {
        await MainActor.run {
            //            self.sendErrorMessage = true
            //            self.errorMessage = error.localizedDescription
        }
    }
    
    
    func didReceiveDialFailure(with error: Error, call: ACBClientCall) async {
        await MainActor.run {
            //            self.sendErrorMessage = true
            //            self.errorMessage = error.localizedDescription
        }
    }
    
    func didReceiveCallRecordingPermissionFailure(_ message: String, call: ACBClientCall?) async {
        await MainActor.run {
            //            self.sendErrorMessage = true
            //            self.errorMessage = message
        }
    }
    
    func call(_ call: ACBClientCall, didReceiveSSRCsForAudio audioSSRCs: [String], andVideo videoSSRCs: [String]) {
//        self.logger.info("Received SSRC information for AUDIO \(audioSSRCs) and VIDEO \(videoSSRCs)")
    }
    
    internal func call(_ call: ACBClientCall, didReportInboundQualityChange inboundQuality: Int) {
//        self.logger.info("Call Quality: \(inboundQuality)")
    }
    
    func didReceiveMediaChangeRequest(_ call: ACBClientCall) async {
        let audio = call.hasRemoteAudio
        let video = call.hasRemoteVideo
//        self.logger.info("HAS AUDIO \(audio)")
//        self.logger.info("HAS VIDEO \(video)")
    }
}






extension CallViewController: ACBClientPhoneDelegate  {
    
    
    //Receive calls with FCSDK
    func phone(_ phone: ACBClientPhone, received call: ACBClientCall) async {

    }
 
    func phone(_ phone: ACBClientPhone, didChange settings: ACBVideoCaptureSetting?, forCamera camera: AVCaptureDevice.Position) async {
//        self.logger.info("didChangeCaptureSetting - resolution=\(String(describing: settings?.resolution.rawValue)) frame rate=\(String(describing: settings?.frameRate)) camera=\(camera.rawValue)")
    }
}

extension UIView {
    func findConstraint(layoutAttribute: NSLayoutConstraint.Attribute) -> NSLayoutConstraint? {
        if let constraints = superview?.constraints {
            for constraint in constraints where itemMatch(constraint: constraint, layoutAttribute: layoutAttribute) {
                return constraint
            }
        }
        return nil
    }

    func itemMatch(constraint: NSLayoutConstraint, layoutAttribute: NSLayoutConstraint.Attribute) -> Bool {
        let firstItemMatch = constraint.firstItem as? UIView == self && constraint.firstAttribute == layoutAttribute
        let secondItemMatch = constraint.secondItem as? UIView == self && constraint.secondAttribute == layoutAttribute
        return firstItemMatch || secondItemMatch
    }
}
