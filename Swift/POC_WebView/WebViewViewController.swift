//
//  WebViewViewController.swift
//  POC_WebView
//
//  Created by Apple on 12/11/20.
//

import Foundation
import WebKit
import Photos

class WebViewViewController: UIViewController,WKNavigationDelegate, WKScriptMessageHandler, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    @IBOutlet weak var loadingCircle: UIActivityIndicatorView!
    
    var webView: WKWebView!
    var userToken: String? = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        createToken()
        webviewSetup()
    }
    
    func createToken()  {
        let length = 24
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        userToken = String((0..<length).map{ _ in letters.randomElement()! })
        print("currentToken",userToken)
    }
    
    func webviewSetup(){
        webView = WKWebView()
        webView.navigationDelegate = self
        view = webView
        let url = URL(string: "http://127.0.0.1:3000/")!
        webView.load(URLRequest(url: url))
        webView.allowsBackForwardNavigationGestures = true
        
        let contentController = self.webView.configuration.userContentController
        contentController.add(self, name: "toggleMessageHandler")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        webView!.evaluateJavaScript("receiveToken('\(userToken!)')", completionHandler: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isBeingDismissed {
            print("---Clear token---")
            webView!.evaluateJavaScript("deleteToken()", completionHandler: nil)
        }
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String : AnyObject] else {
            return
        }
        guard let type = dict["type"] as? String ?? "" else {
            return
        }
        guard let msgRecive = dict["msg"] as? String ?? "" else {
            return
        }
        guard let token = dict["token"] as? String ?? "" else {
            return
        }
        switch type {
        case "logout":
            print(msgRecive)
            logOut()
        case "deletetoken":
            print(msgRecive)
        case "imagePermission":
            print(msgRecive)
            requestPermission()
        default:
            print("none")
        }
    }
    
    func logOut(){
        dismiss(animated: true, completion: .none)
    }
    
    func requestPermission(){
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self;
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true, completion: nil)
        }
    }
    
    
    
}


