//
//  CommunicationViewController.swift
//  CBAFusionStoryboards
//
//  Created by Cole M on 7/21/23.
//

import UIKit
import AVKit
import FCSDKiOS

class CommunicationViewController: UIViewController {
    
    @IBOutlet var recipientTextField: UITextField!
    var acbuc: ACBUC?
    var call: ACBClientCall?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let uc = acbuc else { return }
        setPhoneDelegate(uc)
        dismissKeyboard()
        // Do any additional setup after loading the view.
    }

    
    @IBAction func callPressed(_ sender: Any) {
        performSegue(withIdentifier: "presentCall", sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as? CallViewController
        destinationVC?.recipient = recipientTextField.text ?? ""
        destinationVC?.acbuc = self.acbuc
    }

    func setPhoneDelegate(_ uc: ACBUC) {
        uc.phone.delegate = self
    }
}

//Inbound Delegate
extension CommunicationViewController: ACBClientPhoneDelegate  {
    
    
    //Receive calls with FCSDK
    func phone(_ phone: ACBClientPhone, received call: ACBClientCall) async {
        
        //Present an alert
        let alertController = UIAlertController(
            title: "Incoming Call",
            message: "Answer?",
            preferredStyle: .alert
        )
        
        let cancelAction = UIAlertAction(
            title: "Cancel",
            style: .destructive) { action in
                alertController.dismiss(animated: true)
            }
        
        let answerAction = UIAlertAction(
            title: "OK", style: .default) { action in
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                guard let vc = storyboard.instantiateViewController(withIdentifier: "CallViewController") as? CallViewController else { return }
                vc.phone = phone
                vc.call = call
                vc.isManualSegue = true
                self.present(vc, animated: true)
            }
        
        alertController.addAction(answerAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
        
        
    }
    
    func phone(_ phone: ACBClientPhone, didChange settings: ACBVideoCaptureSetting?, forCamera camera: AVCaptureDevice.Position) async {
        //        print("didChangeCaptureSetting - resolution=\(String(describing: settings?.resolution.rawValue)) frame rate=\(String(describing: settings?.frameRate)) camera=\(camera.rawValue)")
    }
}
