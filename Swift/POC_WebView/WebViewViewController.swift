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

class WebViewViewController: UIViewController,WKNavigationDelegate, WKScriptMessageHandler, UIImagePickerControllerDelegate, WKUIDelegate, UINavigationControllerDelegate {
    // Outlet
    @IBOutlet weak var loadingCircle: UIActivityIndicatorView!
    @IBOutlet weak var webviewContainer: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var pdfDownloadButton: UIButton!
    @IBOutlet weak var stackView: UIStackView!
    //
    var pdfURL: URL?
    var refreshControl = UIRefreshControl()
    var webView: WKWebView!
    var userToken: String? = ""
    var isSessionTimeout: Bool = false
    var firstLoad: Bool = false
    //
    
    // const
    let timeOut: Double = 100
    let hostURL = "http://127.0.0.1:3000/"

    override func viewDidLoad() {
        super.viewDidLoad()
        webviewSetup()
        timeOutSession()
        indicatorSetup()
    }

    func indicatorSetup(){
        self.webView.addSubview(self.loadingCircle)
        self.loadingCircle.startAnimating()
        self.loadingCircle.hidesWhenStopped = true
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("receiveToken('\(userToken!)')", completionHandler: nil)
        loadingCircle.stopAnimating()
        webView.evaluateJavaScript("setALAPAMODE()", completionHandler: nil)
        self.webView.scrollView.es.stopPullToRefresh()
       
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
        self.isModalInPresentation = true
        
        webView = WKWebView(frame: webviewContainer.frame)
        self.webView.navigationDelegate = self
        self.webView.uiDelegate = self
        self.webView.allowsBackForwardNavigationGestures = true
        self.createToken()
        self.webView.translatesAutoresizingMaskIntoConstraints = false
        self.webView.scrollView.automaticallyAdjustsScrollIndicatorInsets = true
        self.webviewContainer.addSubview(self.webView)

        //Setup communication with Javascript
        let contentController = self.webView.configuration.userContentController
        contentController.add(self, name: "toggleMessageHandler")
       
        webView.scrollView.es.addPullToRefresh { [self] in
            if(self.webView.url?.absoluteString == hostURL || self.webView.url?.absoluteURL == nil){
                self.webView.load(URLRequest(url: URL(string: self.hostURL)!))
                self.pdfDownloadButton.tintColor = .white
                self.pdfDownloadButton.isEnabled = false
            } else {
                self.pdfDownloadButton.tintColor = .blue
                self.pdfDownloadButton.isEnabled = true
                self.webView.scrollView.es.stopPullToRefresh()
                webView.evaluateJavaScript("setALAPAMODE()", completionHandler: nil)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func timeOutSession(){
        DispatchQueue.main.asyncAfter(deadline: .now() + timeOut) {
            print("---App out of Session---")
            if(self.webView.url?.absoluteString == self.hostURL){
                self.loadingCircle.startAnimating()
                self.isSessionTimeout = true
                self.webView!.evaluateJavaScript("logOut()", completionHandler: nil)
            } else {
                // find first item in history
                let historySize = self.webView.backForwardList.backList.count
                let firstItem = self.webView.backForwardList.item(at: -historySize)
                
                // go to it!
                self.webView.go(to: firstItem!)
                //
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.loadingCircle.startAnimating()
                self.isSessionTimeout = true
                self.webView!.evaluateJavaScript("logOut()", completionHandler: nil)
                }
            }
        }
    }
    
    func triggerRouteBack(){
        loadingCircle.stopAnimating()
        self.dismiss(animated: true, completion: nil)
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
        case "imagePermission":
            requestPermission()
        case "outOfSession":
            self.loadingCircle.startAnimating()
        case "submitPDF":
            let fileUrl =  URL(string: msgRecive)
            self.pdfURL = fileUrl
        default:
            print("none")
        }
    }
    
    func backtoRoot(){
        let previousView = UIApplication.getPresentedViewController()?.children[1] as! DashboardViewController
        previousView.navigationController?.popViewController(animated: true)
    }
    
    func logOut(){
        self.loadingCircle.startAnimating()
        if !self.isSessionTimeout {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.dismiss(animated: true, completion: backtoRoot)
        }
    }
    
    func requestPermission(){
        PHPhotoLibrary.requestAuthorization({ (status) -> Void in
            print(PHPhotoLibrary.authorizationStatus(),"permission")
         })
    }
  
    @IBAction func closeButton(_ sender: Any) {
        if(self.webView.url?.absoluteString == hostURL){
            print("request to logout")
            self.webView!.evaluateJavaScript("requestLogOut()", completionHandler: nil)
        } else {
            webView.goBack()
        }
    }
    
    @IBAction func pdfDownload(_ sender: Any) {
        let pdfData = NSData(contentsOf: (self.pdfURL!))
        let activityVC = UIActivityViewController(activityItems: [pdfData!], applicationActivities: nil)
        present(activityVC, animated: true, completion: nil)
    }
    
    
    func webView(_ webView: WKWebView,
                     runJavaScriptConfirmPanelWithMessage message: String,
                     initiatedByFrame frame: WKFrameInfo,
                     completionHandler: @escaping (Bool) -> Void) {

            let alertController = UIAlertController(title: nil, message: message, preferredStyle: .actionSheet)

            alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                self.loadingCircle.startAnimating()
                completionHandler(true)
            }))

            alertController.addAction(UIAlertAction(title: "Cancel", style: .default, handler: { (action) in
                completionHandler(false)
            }))

            self.present(alertController, animated: true, completion: nil)
        }
}



extension UIApplication{
    class func getPresentedViewController() -> UIViewController? {
        var presentViewController = UIApplication.shared.keyWindow?.rootViewController
        while let pVC = presentViewController?.presentedViewController
        {
            presentViewController = pVC
        }

        return presentViewController
      }
    }

