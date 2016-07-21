//
//  ViewController.swift
//  BarCodeScanner
//
//  Created by favre on 19/07/2016.
//  Copyright © 2016 favre. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

  @IBOutlet weak var scannerView: CodeScannerView!
  override func viewDidLoad() {
    super.viewDidLoad()
    
    self.scannerView.scanDelegate = self
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}

extension ViewController: ScannerViewDelegate {
  
  func canFilter() -> Bool {
    return true
  }
  
  func scannerView(scanView:CodeScannerView, didScanCode code:String) {
    //do something with the scanned code
  }
  
  func allowedCodeInScanView(scanView:CodeScannerView) -> [String] {
    return ["test"]
  }
  
  func scannerView(scanView:CodeScannerView, didDenyScanCode code:String) {
    //do something with the code
  }
  
  func scannerView(scanView:CodeScannerView, didValidateScanCode code:String) {
    //do something with the code
  }
}

