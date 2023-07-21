//
//  CommunicationViewController.swift
//  CBAFusionStoryboards
//
//  Created by Cole M on 7/21/23.
//

import UIKit
import FCSDKiOS

class CommunicationViewController: UIViewController {

    @IBOutlet var recipientTextField: UITextField!
    var acbuc: ACBUC?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dismissKeyboard()
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    @IBAction func callPressed(_ sender: Any) {
        performSegue(withIdentifier: "presentCall", sender: sender)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! CallViewController
        destinationVC.recipient = "1003"
//        recipientTextField.text ?? ""
        destinationVC.acbuc = self.acbuc
    }
    
    @IBAction func unwindSegue(_ sender: UIStoryboardSegue) {
        print("unwind")
    }
    
}
