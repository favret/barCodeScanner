# barCodeScanner
A simple draggable scannerView for barCode and QRCode.

## Synopsis
ScannerView can detect a machine readable code, represented by AVMetadataMachineReadableCodeObject (QRCode, BarCode93, BarCode127, etc... 
[see ios documentation](https://developer.apple.com/library/ios/documentation/AVFoundation/Reference/AVMetadataMachineReadableCodeObject_Class/index.html).

You can use two class :
  - BarCodeScannerView, who allows you to read code.
  - CodeScannerView, who allows you to read and validate readable codes.

## How to use
1. In your ViewController (define in storyboard or xib), create a UIView.
2. Define this UIView's class to CodeScannerView or BarCodeScannerView.
3. Wait the Building for Designable... you should see a camera.
4. Now, in your ViewController, implement CodeScannerDelegate or BarCodeScannerDelegate.

## Installation
1. Download BarCodeScannerView and ScannerView files
2. Add BarCodeScannerView and ScannerView to your project.

## Exemple

![barCodeScanner demo](./barcodeScanner_presentation.gif)


## Delegates
- BarCodeScannerViewDelegate
 
 `func scanner(scanner:BarCodeScannerView, didScanCode code:String, withType type:String)`
  
- ScannerViewDelegate
  `func canFilter() -> Bool`
  
  `func scannerView(scanView:CodeScannerView, didScanCode code:String)`
  
  `func allowedCodeInScanView(scanView:CodeScannerView) -> [String]`
  
  `func scannerView(scanView:CodeScannerView, didDenyScanCode code:String)`
  
  `func scannerView(scanView:CodeScannerView, didValidateScanCode code:String)`
