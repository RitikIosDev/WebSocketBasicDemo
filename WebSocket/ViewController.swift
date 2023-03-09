//
//  ViewController.swift
//  WebSocket
//
//  Created by Ritik on 21/12/22.
//

import UIKit
import Foundation

class ViewController: UIViewController {

    @IBOutlet private weak var currentStatusLabel: UILabel!
    
    private let USER_TOKEN = "UserToken"
    
    internal override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        let maxLabelWidth = view.bounds.width - 20
        let widthConstraint = NSLayoutConstraint(item: currentStatusLabel, attribute: .width, relatedBy: .lessThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: maxLabelWidth)
        currentStatusLabel.addConstraint(widthConstraint)
    }
    
    private func updateLabelText(labelText: String){
        DispatchQueue.main.async {
            self.currentStatusLabel.text = labelText
        }
    }
    
    private func requestOtp() {
        
        guard let requestURL = URL(string: "https://www.example.com/api/auth/otp") else {
            return
        }
        
        var request = URLRequest(url: requestURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token \(USER_TOKEN)", forHTTPHeaderField: "Authorization")
        self.updateLabelText(labelText: "Token Generated")

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            self.updateLabelText(labelText: "Session Started")
            if let error = error {
                print(error)
                self.updateLabelText(labelText: "Error Occured: \(error.localizedDescription)")
                return
            }
            else if let data = data {
                self.updateLabelText(labelText: "Data Received")

                do{
                    if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {
                        print("statusCode should be 200, but is \(httpStatus.statusCode)")
                        self.updateLabelText(labelText: "statusCode should be 200, but is \(httpStatus.statusCode)")
                        print("response = \(response)")
                        self.updateLabelText(labelText: "response = \(response)")
                        
                    }
                    if let dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]{
                        print(dictionary)
                        self.updateLabelText(labelText: "response = \(dictionary)")
                        self.startSession(otp: dictionary["otp"])
                        self.updateLabelText(labelText: "Starting Web Socket Session")
                    }
                    
                } catch {
                    print(error)
                    self.updateLabelText(labelText: "Error Occured: \(error.localizedDescription)")
                    return
                }
            }
        }
        task.resume()
        
    }
    
    private func startSession(otp: Any){
        guard let url = URL(string: "wss://notifications.example.com/subscribe") else {
            return
        }
        let session = URLSession(configuration: .default)
        let request = URLRequest(url: url)
        let task = session.webSocketTask(with: request)
        task.delegate = self
        self.updateLabelText(labelText: "WebSocket Connection initialized")
        
        task.receive { result in
            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received text message: \(text)")
                    self.updateLabelText(labelText: "Received text message: \(text)")
//                    task.cancel(with: .normalClosure, reason: nil)
                case .data(let data):
                    print("Received binary data: \(data)")
                    self.updateLabelText(labelText: "Received binary data: \(data)")
                @unknown default:
                    print("Received an unknown message type")
                    self.updateLabelText(labelText: "Received an unknown message type")
                }
            case .failure(let error):
                print("Failed to receive message: \(error)")
                self.updateLabelText(labelText: "Failed to receive message: \(error)")
                if error._code == 5000 ||  error._code == 1006{
                    self.requestOtp()
                    self.updateLabelText(labelText: "Re-establishing WebSocket Connection")
                }
            }
        }
        
        let pseudocode = ["otp" : otp]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: pseudocode, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                let message = URLSessionWebSocketTask.Message.string(jsonString)
                task.send(message) { error in
                    if let error = error {
                        print("Failed to send message: \(error)")
                        self.updateLabelText(labelText: "Failed to send message: \(error)")
                    }
                }
                self.updateLabelText(labelText: "Sending Message")
                task.resume()
            } else {
                print("Could not convert Dictionary to Data")
                self.updateLabelText(labelText: "Could not convert Dictionary to Data")

            }
            
        } catch {
            print(error)
            self.updateLabelText(labelText: "Error Occured: \(error.localizedDescription)")
            return
        }

    }

    @IBAction private func ButtonGetDataClicked(_ sender: UIButton) {
        requestOtp()
    }
    
}

extension ViewController: URLSessionWebSocketDelegate {
    internal func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        self.updateLabelText(labelText: "WebSocket Connection established")
    }
    internal func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        self.updateLabelText(labelText: "WebSocket Connection Lost with closeCode: \(closeCode) and reason: \(reason)")
        print("WebSocket Connection Lost with closeCode: \(closeCode) and reason: \(reason)")
            self.requestOtp()
            print(closeCode)
        self.updateLabelText(labelText: "Re-establishing WebSocket Connection")
    }
    internal func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError: Error?) {
        self.updateLabelText(labelText: "WebSocket Connection completed with error: \(didCompleteWithError)")
    }
    internal func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        self.updateLabelText(labelText: "WebSocket Connection lost with error: \(error)")
    }
}

