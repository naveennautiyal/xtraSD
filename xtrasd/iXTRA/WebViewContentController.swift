//
//  WebViewContentController.swift
//  iXTRA
//
//  Created by Fadi Asfour on 2015-10-09.
//  Copyright © 2015 iXTRA Technologies. All rights reserved.
//

import UIKit

class WebViewContentController: UIViewController
{

    @IBOutlet weak var webViewContainer: UIWebView!
    var fileUrl: NSURL?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        let request = NSURLRequest(URL: fileUrl!)
        webViewContainer.loadRequest(request)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
}
