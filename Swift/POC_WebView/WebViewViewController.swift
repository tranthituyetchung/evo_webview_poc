//
//  WebViewViewController.swift
//  POC_WebView
//
//  Created by Apple on 12/11/20.
//

import Foundation
import WebKit
import Photos
import AssetsLibrary
import ESPullToRefresh

class WebViewViewController: UIViewController,WKNavigationDelegate, WKScriptMessageHandler, UIImagePickerControllerDelegate & UINavigationControllerDelegate {
    
    @IBOutlet weak var loadingCircle: UIActivityIndicatorView!
    @IBOutlet weak var tableview: UITableView!
    
    var pdfURL: URL?
    var refreshControl = UIRefreshControl()
    var isNavigationOut: Bool = false
    var webView: WKWebView!
    var userToken: String? = ""
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webviewSetup()
        timeOutSession()
        indicatorSetup()
        navigationSetup()
    }
    
    func navigationSetup(){
        self.navigationItem.hidesBackButton = true
        let newBackButton = UIBarButtonItem(title: "Back", style: UIBarButtonItem.Style.plain, target: self, action: #selector(WebViewViewController.back(sender:)))
        self.navigationItem.leftBarButtonItem = newBackButton
    }
    
    @objc func back(sender: UIBarButtonItem) {
        if(webView.url?.absoluteString == "http://127.0.0.1:3000/"){
            _ = navigationController?.popViewController(animated: true)
        } else {
           webView.goBack()
        }
    }
    
    @objc func sharePdf(sender: UIBarButtonItem) {
        let pdfData = NSData(contentsOf: (self.pdfURL!))
       
        let activityVC = UIActivityViewController(activityItems: [pdfData!], applicationActivities: nil)
        present(activityVC, animated: true, completion: nil)
        
    }
    
    func indicatorSetup(){
        self.webView.addSubview(self.loadingCircle)
        self.loadingCircle.startAnimating()
        self.webView.navigationDelegate = self
        self.loadingCircle.hidesWhenStopped = true
        self.webView.scrollView
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("receiveToken('\(userToken!)')", completionHandler: nil)
        loadingCircle.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        loadingCircle.stopAnimating()
    }
    
    func createToken()  {
        let length = 24
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        userToken = String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    func webviewSetup(){
        webView = WKWebView()
        webView.navigationDelegate = self
        self.view = self.webView
        let contentController = self.webView.configuration.userContentController
        contentController.add(self, name: "toggleMessageHandler")
        self.webView.scrollView.es.addPullToRefresh {
            if((self.webView.url?.absoluteString == "http://127.0.0.1:3000/" || self.webView.url?.absoluteString == nil) && self.isNavigationOut == false ) {
                let url = URL(string: "http://127.0.0.1:3000/")! // URL of local website
                self.webView.load(URLRequest(url: url))
                self.webView.allowsBackForwardNavigationGestures = true
                self.createToken() // change token after refresh
                self.webView.translatesAutoresizingMaskIntoConstraints = false
                self.webView.scrollView.es.stopPullToRefresh(ignoreDate: false, ignoreFooter: false)
            } else {
                self.webView.scrollView.es.stopPullToRefresh(ignoreDate: false, ignoreFooter: false)
                let downloadButton = UIBarButtonItem(title: "DownLoad", style: UIBarButtonItem.Style.plain, target: self, action: #selector(WebViewViewController.sharePdf(sender:)))
                self.navigationItem.rightBarButtonItem = downloadButton
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // send token to website when first init
      
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("---Clear token---")
        // clear token when dismiss
        webView!.evaluateJavaScript("deleteToken()", completionHandler: nil)
        self.webView.scrollView.es.stopPullToRefresh()
        webView.evaluateJavaScript("receiveToken('\(userToken!)')", completionHandler: nil)
        self.isNavigationOut = true
    }
    
    func timeOutSession(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 999999) {
            print("---Out of Session---")
            self.loadingCircle.startAnimating()
            self.webView!.evaluateJavaScript("timeOutSession()", completionHandler: nil)
        }
    }
    
    func triggerRouteBack(){
        loadingCircle.stopAnimating()
        let refreshAlert = UIAlertController(title: "Notification", message: "Your session is time out", preferredStyle: UIAlertController.Style.alert)
        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            _ = self.navigationController?.popToRootViewController(animated: true)
        }))
        present(refreshAlert, animated: true, completion: nil)
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        // listener
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
        print(msgRecive)
        switch type {
        case "logout":
            logOut()
        case "deletetoken":
            print(msgRecive)
        case "imagePermission":
            requestPermission()
        case "outOfSession":
            triggerRouteBack()
        case "submitPDF":
            let fileUrl =  URL(string: msgRecive)
            

            self.pdfURL = fileUrl
        default:
            print("none")
        }
    }
    
    func logOut(){
        _ = self.navigationController?.popToRootViewController(animated: true)
    }
    
    func requestPermission(){
        self.loadingCircle.startAnimating()
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let imagePickerController = UIImagePickerController()
            imagePickerController.delegate = self;
            imagePickerController.sourceType = .photoLibrary
            self.present(imagePickerController, animated: true, completion: nil)
            self.loadingCircle.stopAnimating()
        }
    }
  
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
       
    }
    

}

