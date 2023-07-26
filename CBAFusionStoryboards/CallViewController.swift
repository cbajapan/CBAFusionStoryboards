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

class CallViewController: UIViewController, ACBClientCallDelegate {
    
    @IBOutlet var remoteVideoView: UIView!
    @IBOutlet var localVideoView: UIView!
    
    
    var call: ACBClientCall?
    var phone: ACBClientPhone?
    var acbuc: ACBUC?
    var recipient = ""
    var isManualSegue = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dismissKeyboard()
        // Do any additional setup after loading the view.
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        if isManualSegue {
            Task { [weak self] in
                guard let self else { return }
                guard let phone = self.phone else { return }
                guard let call = self.call else { return }
                call.delegate = self
                await self.answerCall(phone, received: call)
            }
        } else {
            Task { [weak self] in
                guard let self else { return }
                self.call = try await initializeFCSDKCall()
            }
        }
    }
    
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     Get the new view controller using segue.destination.
     Pass the selected object to the new view controller.
     }
     */
    
    var isFrontCamera = true
    @IBAction func switchViews(_ sender: Any) {
        
        Task { @MainActor [weak self] in
            guard let self else { return }
            if isFrontCamera {
                self.acbuc?.phone.setCamera(.back)
                self.acbuc?.phone.previewView = self.remoteVideoView
                self.call?.remoteView = self.localVideoView
                self.isFrontCamera = false
            } else {
                self.acbuc?.phone.setCamera(.front)
                self.acbuc?.phone.previewView = self.localVideoView
                self.call?.remoteView = self.remoteVideoView
                self.isFrontCamera = true
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        Task {
            await self.endCall()
        }
    }
    
    
    func initializeFCSDKCall() async throws -> ACBClientCall? {
        guard let uc = self.acbuc else { throw OurErrors.nilACBUC }
        await MainActor.run { [weak self] in
            guard let self else { return }
            uc.phone.previewView = self.localVideoView
        }
        
        let outboundCall = await uc.phone.createCall(
            toAddress: self.recipient,
            withAudio: .sendAndReceive,
            video: .sendAndReceive,
            delegate: self
        )
        outboundCall?.delegate = self
        
        uc.phone.mirrorFrontFacingCameraPreview = true
        self.call = outboundCall
        self.call?.enableLocalVideo(true)
        
        await MainActor.run { [weak self] in
            guard let self else { return }
            self.call?.remoteView = self.remoteVideoView
        }
        return self.call
    }
    
}

extension CallViewController {
    
    
    private func endCall() async {
        await call?.end()
        if isManualSegue {
            dismiss(animated: true)
        }
    }
    
    func didChange(_ status: ACBClientCallStatus, call: ACBClientCall) async {
        switch status {
        case .setup:
            break
        case .preparingBufferViews:
            break
        case .alerting:
            break
        case .ringing:
            break
        case .mediaPending:
            break
        case .inCall:
            break
        case .timedOut:
            break
        case .busy:
            break
        case .notFound:
            break
        case .error:
            break
        case .ended:
            await self.endCall()
        @unknown default:
            break
        }
    }
    
    func didReceiveSessionInterruption(_ message: String, call: ACBClientCall) async {
        if message == "Session interrupted" {
            
        }
    }
    
    func didReceiveCallFailure(with error: Error, call: ACBClientCall) async {
        
    }
    
    
    func didReceiveDialFailure(with error: Error, call: ACBClientCall) async {
        
    }
    
    func didReceiveCallRecordingPermissionFailure(_ message: String, call: ACBClientCall?) async {
        
    }
    
    func call(_ call: ACBClientCall, didReceiveSSRCsForAudio audioSSRCs: [String], andVideo videoSSRCs: [String]) {
        //        print("Received SSRC information for AUDIO \(audioSSRCs) and VIDEO \(videoSSRCs)")
    }
    
    internal func call(_ call: ACBClientCall, didReportInboundQualityChange inboundQuality: Int) {
        print("Call Quality: \(inboundQuality)")
    }
    
    func didReceiveMediaChangeRequest(_ call: ACBClientCall) async {
        print("HAS AUDIO \(call.hasRemoteAudio)")
        print("HAS VIDEO \(call.hasRemoteVideo)")
    }
    
    func answerCall(_ phone: ACBClientPhone, received call: ACBClientCall) async {
        await MainActor.run { [weak self] in
            guard let self else { return }
            call.remoteView = self.remoteVideoView
            phone.previewView = self.localVideoView
        }
        await call.answer(withAudio: .sendAndReceive, andVideo: .sendAndReceive)
    }
}
