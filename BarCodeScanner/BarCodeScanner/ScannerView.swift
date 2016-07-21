//
//  ScannerView.swift
//  ScannerView
//
//  Created by favre on 01/04/2016.
//  Copyright © 2016 favre. All rights reserved.
//

import UIKit
import AVFoundation

/**
 The ScannerViewDelegate protocol must be adopted by the delegate of an ScannerView object .
 The methods allows a delegate to validate or deny a captured metadata output object.
 */
public protocol ScannerViewDelegate: class {
  
  /**
   Inform the ScannerView if it have to validate or not some value.
   */
  func canFilter() -> Bool
  
  /**
   Inform the delegate that a metadata is captured.
   
   - Parameter scanView: The ScannerView object that captured and emitted the metadata object.
   - Parameter code: The String value of the metadata object.
   */
  func scannerView(scanView:CodeScannerView, didScanCode code:String)
  
  /**
   Return an Array that contain all the allowed barcode.
   
   - Returns: an Array that contain all the allowed barcode.
   */
  func allowedCodeInScanView(scanView:CodeScannerView) -> [String]
  
  /**
   Inform the delegate that a metadata has been denied.
   
   - Parameter code: The String value of the denied metadata object.
   */
  func scannerView(scanView:CodeScannerView, didDenyScanCode code:String)
  
  /**
   Inform the delegate that a metadata has been validate.
   
   - Parameter code: The String value of the validate metadata object.
   */
  func scannerView(scanView:CodeScannerView, didValidateScanCode code:String)
}

/**
 ScannerView allows you to read barcodes unsing the metadata scanning capabilities introduced with iOS7.
 Each readen barcodes can be validate or deny according to it delegate.
 */
public class CodeScannerView : BarCodeScannerView, BareCodeScannerDelegate {
  
  lazy var successAudioPlayer: AVAudioPlayer? = {
    
    guard let filePath  = NSBundle(forClass: CodeScannerView.self).pathForResource("beep", ofType: "mp3")
      else { return nil }
    
    let fileURL     = NSURL(fileURLWithPath: filePath)
    let audioPlayer = try! AVAudioPlayer(contentsOfURL: fileURL)
    
    audioPlayer.prepareToPlay()
    
    return audioPlayer
  }()
  
  lazy var failureAudioPlayer: AVAudioPlayer? = {
    
    guard let filePath  = NSBundle(forClass: CodeScannerView.self).pathForResource("fail", ofType: "wav")
      else { return nil }
    
    let fileURL     = NSURL(fileURLWithPath: filePath)
    let audioPlayer = try! AVAudioPlayer(contentsOfURL: fileURL)
    
    audioPlayer.prepareToPlay()
    
    return audioPlayer
  }()
  
  public weak var scanDelegate: ScannerViewDelegate?
  
  override public func initialize(){
    super.initialize()
    self.delegate = self
  }
  
  func playSound(withAudioPlayer audioPlayer: AVAudioPlayer) {
    audioPlayer.currentTime = 0
    audioPlayer.play()
  }
  
  func flashScreen(withColor color: UIColor, completion: (() -> ())? = nil) {
    
    //guard let videoPreviewLayer = self.videoPreviewLayer
    //  else { return }
    
    
    let flashView = UIView(frame: self.bounds)
    flashView.backgroundColor = color
    flashView.alpha = 0
    self.addSubview(flashView)
    
    UIView.animateWithDuration(
      0.12,
      delay: 0,
      options: [.CurveEaseOut],
      animations: { flashView.alpha = 1 }
    ) { finished in
      guard finished else { return }
      
      UIView.animateWithDuration(
        0.7,
        delay: 0,
        options: [.CurveEaseIn],
        animations: { flashView.alpha = 0 }
      ) { finished in
        guard finished else { return }
        
        flashView.removeFromSuperview()
        completion?()
      }
    }
  }
  
  /*public var resource_bundle: NSBundle {
   guard let path = core__bundle.pathForResource("Core", ofType: "bundle") else {
   return core__bundle
   }
   
   return NSBundle(path: path)!
   }*/
  
  
  func isCodeValid(code: String) -> Bool {
    if let delegate = self.scanDelegate {
      return delegate.allowedCodeInScanView(self).contains(code)
    }
    
    return true
  }
  
  public func showDeny() {
    if let failureAudioPlayer = self.failureAudioPlayer{
      self.playSound(withAudioPlayer: failureAudioPlayer)
    }
    
    self.flashScreen(withColor: UIColor(
      red: 222.0/255.0,
      green: 36.0/255.0,
      blue: 51.0/255.0,
      alpha: 1))
  }
  
  public func showSuccess() {
    if let successAudioPlayer = self.successAudioPlayer{
      self.playSound(withAudioPlayer: successAudioPlayer)
    }
    
    self.flashScreen(withColor: UIColor(
      red: 47.0/255.0,
      green: 201.0/255.0,
      blue: 135.0/255.0,
      alpha: 1))
  }
  
  public func addCode(code: String) {
    func denyCode() {
      
      if let delegate = self.scanDelegate{
        delegate.scannerView(self, didDenyScanCode: code)
      }
      
      self.showDeny()
    }
    
    if let delegate = self.scanDelegate{
      delegate.scannerView(self, didScanCode: code)
    }
    
    guard self.isCodeValid(code) else {
      denyCode()
      return
    }
    
    if let delegate = self.scanDelegate{
      delegate.scannerView(self, didValidateScanCode: code)
    }
    
    self.showSuccess()
  }
  
  
  //MARK: BareCodeScannerDelegate
  public func scanner(scanner: BarCodeScannerView, didScanCode code: String, withType type: String) {
    dispatch_async(dispatch_get_main_queue()) {
      if let delegate = self.scanDelegate {
        if delegate.canFilter() {
          self.addCode(code)
        } else {
          delegate.scannerView(self, didScanCode: code)
        }
      } else {
        self.addCode(code)
      }
    }
  }
}
