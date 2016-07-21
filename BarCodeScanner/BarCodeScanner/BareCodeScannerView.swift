//
//  SaveBarCodeScannerView.swift
//  SaveBarCodeScanner
//
//  Created by favre on 01/04/2016.
//  Copyright © 2016 favre. All rights reserved.
//

import UIKit
import AVFoundation

/**
 The BareCodeScannerDelegate protocol must be adopted by the delegate of an BarCodeScannerView object . 
 The method allows a delegate to respond when a capture metadata output object receives relevant metadata objects through its connection.
 */
public protocol BareCodeScannerDelegate: class {
  
  /**
   Informs the delegate that the capture output object emitted new metadata object.
   
   - Parameter scanner: The BarCodeScannerView object that captured and emitted the metadata object
   - Parameter code: The String value of the metadata object.
   - Parameter type: The type of the metadata object.
   */
  func scanner(scanner:BarCodeScannerView, didScanCode code:String, withType type:String)
}

/**
 BareCodeScannerView allows you to read barcodes unsing the metadata scanning capabilities introduced with iOS7.
 */
@IBDesignable
public class BarCodeScannerView : UIView, AVCaptureMetadataOutputObjectsDelegate {
  
  let dispatchQueueUUID = "fr.favre.barcodes.metadata"
  
  public lazy var device  = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
  
  public lazy var frontDevice:AVCaptureDevice? = {
    for device in AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) {
      if let _device = device as? AVCaptureDevice where _device.position == AVCaptureDevicePosition.Front {
        return _device
      }
    }
    return nil
  }()
  
  lazy var deviceInput: AVCaptureDeviceInput? = {
    return try? AVCaptureDeviceInput(device: self.device)
  }()
  
  lazy var frontDeviceInput: AVCaptureDeviceInput?  = {
    if let _frontDevice = self.frontDevice {
      return try? AVCaptureDeviceInput(device: _frontDevice)
    }
    
    return nil
  }()
  
  public lazy var output  = AVCaptureMetadataOutput()
  public lazy var session = AVCaptureSession()
  
  //private var input:AVCaptureInput?
  var videoPreviewLayer: AVCaptureVideoPreviewLayer?
  public weak var delegate: BareCodeScannerDelegate? = nil
  
  private let cameraImageView:UIImageView = UIImageView(image:  UIImage(named: "camera-swipe", inBundle:  NSBundle(forClass: CodeScannerView.self), compatibleWithTraitCollection: nil))
  
  private var timer:NSTimer?
  private var wait:Bool = false

  private var started:Bool = false
  
  public var position: AVCaptureDevicePosition = AVCaptureDevicePosition.Back {
    didSet {
      self.switchCameraView(self.position)
    }
  }
  
  private func switchCameraView(position:AVCaptureDevicePosition) {
    self.session.beginConfiguration()

    if let currentInput = self.session.inputs.first as? AVCaptureDeviceInput {
      self.session.removeInput(currentInput)
    }
    
    switch position {
    case .Front where self.frontDeviceInput != nil:
      self.session.addInput(self.frontDeviceInput!)
    case .Back where self.deviceInput != nil:
      self.session.addInput(self.deviceInput)
    default: ()
    }
    
    self.session.commitConfiguration()
  }
  
  func configureDevice() {
    if let device = self.device {
      
      do{
        try device.lockForConfiguration()
        
        if self.device.isFocusModeSupported(.ContinuousAutoFocus){
          self.device.focusMode = .ContinuousAutoFocus
        }
        
        if self.device.autoFocusRangeRestrictionSupported{
          self.device.autoFocusRangeRestriction = .Near
        } else {
          device.exposureMode = .ContinuousAutoExposure
        }
        
        self.device.unlockForConfiguration()
      }catch _{ }
    }
  }
  
  func initializeInput() {
    if self.session.canAddInput(self.deviceInput){
      self.session.addInput(self.deviceInput)
    }
  }
  
  func initializeOutput() {
    let queue = dispatch_queue_create(dispatchQueueUUID, DISPATCH_QUEUE_CONCURRENT)
    self.output.setMetadataObjectsDelegate(self, queue: queue)
    
    if self.session.canAddOutput(self.output){
      self.session.addOutput(self.output)
      self.output.metadataObjectTypes = self.output.availableMetadataObjectTypes
    }
  }
  
  func initializeLayer() {
    self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.session)
    if let videoPreviewLayer = self.videoPreviewLayer{
      videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
      videoPreviewLayer.frame = self.bounds
      videoPreviewLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))

      self.layer.addSublayer(videoPreviewLayer)
    }
  }
  
  //MARK: Initialize
  public func initialize(){
    
    //let input: AVCaptureInput!
    self.initializeInput()

    //configuration du device
    self.configureDevice()
    
    //init  camera layer & add it to self.layer
    self.initializeLayer()
    
    //init output
    self.initializeOutput()

    //init orientation
    self.updateOrientation()
    
    //init Gesture
    let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(onTap(_:)))
    self.addGestureRecognizer(tapGestureRecognizer)
    
    //subscribe rotation change notif
    NSNotificationCenter.defaultCenter().addObserver(
      self,
      selector: #selector(updateOrientation),
      name: UIApplicationDidChangeStatusBarOrientationNotification,
      object: nil)
    
    self.backgroundColor = UIColor.clearColor()
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.initialize()
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.initialize()
  }
  
  //MARK: start/stop
  
  /**
   Run the scanner. This method will capture all the metadata emit by the AVCaptureMetadataOutput.
   All the captured metadata is send with his delegate.
   */
  public func start(){
    if self.started == false {
      self.session.startRunning()
      self.started = true
    }
  }
  
  /**
   Stop the scanner.
   */
  public func stop(){
    if self.started == true {
      self.session.stopRunning()
      self.started = false
    }
  }
  
  //MARK: UITapGestureRecognizer
  func onTap(gesture: UITapGestureRecognizer) {
    guard let _ = try? device.lockForConfiguration() else {
      return
    }

    // Re-set focus point at center of screen
    if device.focusPointOfInterestSupported {
      device.focusPointOfInterest = CGPointMake(0.5, 0.5)
    }

    // Re-trigger auto-focus
    if device.isFocusModeSupported(.AutoFocus) {
      device.focusMode = .AutoFocus
    }

    self.device.unlockForConfiguration()
  }

  public func updateOrientationWithVideoOrientation(videoOrientation: AVCaptureVideoOrientation) {
    guard
      let videoPreviewLayer = self.videoPreviewLayer,
      let connection = videoPreviewLayer.connection
      where connection.supportsVideoOrientation
      else { return }

    videoPreviewLayer.connection.videoOrientation = videoOrientation
    videoPreviewLayer.frame = self.bounds
  }

  public func updateOrientation() {
    let orientation = UIApplication.sharedApplication().statusBarOrientation
    let captureOrientation = self.interfaceOrientationToVideoOrientation(orientation)
    self.updateOrientationWithVideoOrientation(captureOrientation)
  }

  private func interfaceOrientationToVideoOrientation(orientation: UIInterfaceOrientation) -> AVCaptureVideoOrientation {
    switch (orientation) {
    case .LandscapeLeft:
      return AVCaptureVideoOrientation.LandscapeLeft
    case .LandscapeRight:
      return AVCaptureVideoOrientation.LandscapeRight
    case .Portrait:
      return AVCaptureVideoOrientation.Portrait
    case .PortraitUpsideDown:
      return AVCaptureVideoOrientation.PortraitUpsideDown
    case .Unknown:
      return AVCaptureVideoOrientation.Portrait
    }
  }

  //MARK: Timer
  func onTick() {
    if let timer = self.timer {
      timer.invalidate()
      self.timer = nil
      self.wait = false
    }
  }
  
  private func startTimer(){
    self.wait = true
    dispatch_async(dispatch_get_main_queue(), { () -> Void in
      if let timer = self.timer {
        timer.invalidate()
      }
       self.timer = NSTimer.scheduledTimerWithTimeInterval(2, target: self, selector: #selector(BarCodeScannerView.onTick), userInfo: nil, repeats: true)
    })
    
  }
  
  //MARK: AVCaptureMetadataOutputObjectsDelegate
  public func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {
    
    if (self.wait == true){
      return
    }
    
    
    for object: AnyObject in metadataObjects {
      
      guard let metadataObject:AVMetadataObject = object as? AVMetadataObject
        else { continue }
    
      print("[BarCodeScanner : \(#function)] metadata.type: \(metadataObject.type)")
      
      guard let videoPreviewLayer = self.videoPreviewLayer
        else { continue }
      
      let transformedMetadataObject = videoPreviewLayer.transformedMetadataObjectForMetadataObject(metadataObject)
      
      if transformedMetadataObject.isKindOfClass(AVMetadataMachineReadableCodeObject.self) {
        let codeObject = transformedMetadataObject as! AVMetadataMachineReadableCodeObject
        print("\(#function)\tcodevalue : \(codeObject.stringValue)")

      
        if let delegate = self.delegate{
          delegate.scanner(self, didScanCode: codeObject.stringValue, withType: codeObject.type)
        }
        
        self.startTimer()
        
      }
    }
  }
  
  public func reverseCameraTapped(sender:AnyObject) {
    switch self.position {
    case .Back : self.position = .Front
    case .Front: self.position = .Back
    
    default:()
    }
  }
  
  public override func drawRect(rect: CGRect) {
    super.drawRect(rect)
    self.updateOrientation()
    
    if !self.subviews.contains(self.cameraImageView) {
      self.addSubview(self.cameraImageView)

      self.cameraImageView.frame = CGRect(x: rect.width - (50 + 20), y: 0 + 20, width: 50, height: 50)
      self.cameraImageView.contentMode = UIViewContentMode.ScaleAspectFit
      
      self.cameraImageView.userInteractionEnabled = true
      self.cameraImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(BarCodeScannerView.reverseCameraTapped(_:))))
      
    }
    
    self.start()
  }
  
  public override func removeFromSuperview() {
    self.stop()
  }
  
  deinit{
    self.stop()
   // self.destroy()
  }


  //MARK: InterfaceBuilder
  public override func prepareForInterfaceBuilder() {
    /*
    let center = CALayer()
    center.frame = CGRect(x: (self.frame.size.width / 2) - (self.frame.size.width / 18), y: (self.frame.size.height / 2) - (self.frame.size.height / 18), width: self.frame.size.width / 2, height: self.frame.size.height / 2)
    setupLayers(center)
    
    self.layer.addSublayer(center)
 */
  }
  
  func setupLayers(layer:CALayer){
    let polygon = CAShapeLayer()
    polygon.frame       = CGRectMake(21.03, -24.06, 23, 36.08)
    polygon.setValue(-90 * CGFloat(M_PI)/180, forKeyPath:"transform.rotation")
    polygon.fillColor   = UIColor(red:0.922, green: 0.376, blue:0.357, alpha:1).CGColor
    polygon.strokeColor = UIColor(red:0.329, green: 0.329, blue:0.329, alpha:1).CGColor
    polygon.path        = polygonPath().CGPath;
    layer.addSublayer(polygon)
    
    let roundedrect = CAShapeLayer()
    roundedrect.frame       = CGRectMake(-31.35, -6.02, 126.94, 75.2)
    roundedrect.fillColor   = UIColor(red:0.922, green: 0.376, blue:0.357, alpha:1).CGColor
    roundedrect.strokeColor = UIColor(red:0.329, green: 0.329, blue:0.329, alpha:1).CGColor
    roundedrect.path        = roundedRectPath().CGPath;
    layer.addSublayer(roundedrect)
    
    let oval2 = CAShapeLayer()
    oval2.frame       = CGRectMake(10.75, 13.17, 42.73, 36.81)
    oval2.fillColor   = UIColor(red:0.922, green: 0.922, blue:0.922, alpha:1).CGColor
    oval2.strokeColor = UIColor(red:0.329, green: 0.329, blue:0.329, alpha:1).CGColor
    oval2.path        = oval2Path().CGPath;
    layer.addSublayer(oval2)
    
    let oval = CAShapeLayer()
    oval.frame       = CGRectMake(14.9, 16.66, 34.43, 29.84)
    oval.fillColor   = UIColor(red:0.922, green: 0.376, blue:0.357, alpha:1).CGColor
    oval.strokeColor = UIColor(red:0.329, green: 0.329, blue:0.329, alpha:1).CGColor
    oval.path        = ovalPath().CGPath;
    layer.addSublayer(oval)
    
    let oval3 = CAShapeLayer()
    oval3.frame       = CGRectMake(49.84, 9.65, 7.27, 7.05)
    oval3.fillColor   = UIColor(red:0.922, green: 0.922, blue:0.922, alpha:1).CGColor
    oval3.strokeColor = UIColor(red:0.329, green: 0.329, blue:0.329, alpha:1).CGColor
    oval3.path        = oval3Path().CGPath;
    layer.addSublayer(oval3)
  }
  
  
  @IBAction func startAllAnimations(sender: AnyObject!){
    
  }
  
  //MARK: - Bezier Path
  
  func polygonPath() -> UIBezierPath{
    let polygonPath = UIBezierPath()
    polygonPath.moveToPoint(CGPointMake(11.5, 0))
    polygonPath.addLineToPoint(CGPointMake(0, 9.02))
    polygonPath.addLineToPoint(CGPointMake(0, 27.06))
    polygonPath.addLineToPoint(CGPointMake(11.5, 36.08))
    polygonPath.addLineToPoint(CGPointMake(23, 27.06))
    polygonPath.addLineToPoint(CGPointMake(23, 9.02))
    polygonPath.closePath()
    polygonPath.moveToPoint(CGPointMake(11.5, 0))
    
    return polygonPath;
  }
  
  func roundedRectPath() -> UIBezierPath{
    let roundedRectPath = UIBezierPath(roundedRect:CGRectMake(0, 0, 127, 75), cornerRadius:20)
    return roundedRectPath;
  }
  
  func oval2Path() -> UIBezierPath{
    let oval2Path = UIBezierPath(ovalInRect: CGRectMake(0, 0, 43, 37))
    return oval2Path;
  }
  
  func ovalPath() -> UIBezierPath{
    let ovalPath = UIBezierPath(ovalInRect: CGRectMake(0, 0, 34, 30))
    return ovalPath;
  }
  
  func oval3Path() -> UIBezierPath{
    let oval3Path = UIBezierPath(ovalInRect: CGRectMake(0, 0, 7, 7))
    return oval3Path;
  }

  
}
