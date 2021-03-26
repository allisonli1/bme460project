/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Contains the main app implementation using Vision.
*/

import UIKit
import AVKit
import Vision
import youtube_ios_player_helper
import Alamofire

class FaceDetectionController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    // Storyboard variables
    @IBOutlet weak var previewView: UIView? // Main view for showing camera content.
    @IBOutlet weak var warningFeedback: UILabel!
    @IBOutlet var outerView: UIView!
    @IBOutlet weak var arrowImage: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    // @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var videoView: YTPlayerView!
    @IBOutlet weak var testLab: UILabel!
    
    
    // AVCapture variables to hold sequence data
    var session: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    var videoDataOutput: AVCaptureVideoDataOutput?
    var videoDataOutputQueue: DispatchQueue?
    
    var captureDevice: AVCaptureDevice?
    var captureDeviceResolution: CGSize = CGSize()
    
    // Layer UI for drawing Vision results
    var rootLayer: CALayer?
    var detectionOverlayLayer: CALayer?
    var detectedFaceRectangleShapeLayer: CAShapeLayer?
    var detectedFaceLandmarksShapeLayer: CAShapeLayer?
    var detectedLineLayer: CAShapeLayer?
    
    
    // Vision requests
    private var detectionRequests: [VNDetectFaceRectanglesRequest]?
    private var trackingRequests: [VNTrackObjectRequest]?
    
    lazy var sequenceRequestHandler = VNSequenceRequestHandler()
    
    var runningAvgArr: [Float] = []
    var runningAvg: Float = -1
    // Feedback indicators for tilting head
    var calibratedFaceOutline: VNFaceLandmarkRegion2D?
    var calibratedAffineTransform: CGAffineTransform?
    var anglesTiltForCalibration: [CGFloat] = []
    var calibratedTiltAngle: Float = 0.0
    var calibrated: Bool = false
    var isCalibrating = false
    var acceptableRange: Float = 4.0
//    var acceptableUpRange: Float = 1.0
    var outTiltLeft = false
    var outTiltRight = false
    
    // Feedback indicators for up + down movement
//    var fromLeftForCalibration: [CGFloat] = []
//    var fromRightForCalibration: [CGFloat] = []
//    var calibratedfromLeftAngle: Float = 0.0
//    var calibratedfromRightAngle: Float = 0.0
    var outDown = false
    var outUp = false
    var outRight = false
    var outLeft = false
    
    // Feedback indicators up and down
    var calibratedWidth: Float = 0.0
    var calibratedHeight: Float = 0.0
    var widthsForCalibration: [CGFloat] = []
    var heightsForCalibration: [CGFloat] = []
    var acceptableProp: Float = 0.9
    var calibratedLeftEyeYPos: Float = 0.0
    var leftEyeHeightsForCalibration: [CGFloat] = []
    
    // Feedback indicators left and right
    var calibratedLeftEyeXPos: Float = 0.0
    var leftEyeXPosForCalbration: [CGFloat] = []
    
    // AV Player
    // var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    var videoRootLayer: CALayer?
    var playerLayer: AVPlayerLayer?
    var vidIsOpen = false
    
    var player: AVPlayer? {
      return playerLayer?.player
    }

 
    // MARK: UIViewController overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.session = self.setupAVCaptureSession()
        
        self.prepareVisionRequest()
        
        self.session?.startRunning()
        
        self.videoView?.layer.isHidden = true
        
        // Initializing UI text
        warningFeedback.text = ""
        self.updatePlayButtonTitle(isPlaying: false)
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "containerViewSegue" {
            (segue.destination as? AngleInfoViewController)?.layerViewController = self
        }
    }
    
    // Ensure that the interface stays locked in Portrait.
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    // Ensure that the interface stays locked in Portrait.
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        return .portrait
    }
    
    // MARK: AVCapture Setup
    
    /// - Tag: CreateCaptureSession
    fileprivate func setupAVCaptureSession() -> AVCaptureSession? {
        let captureSession = AVCaptureSession()
        do {
            let inputDevice = try self.configureFrontCamera(for: captureSession)
            self.configureVideoDataOutput(for: inputDevice.device, resolution: inputDevice.resolution, captureSession: captureSession)
            self.designatePreviewLayer(for: captureSession)
            return captureSession
        } catch let executionError as NSError {
            self.presentError(executionError)
        } catch {
            self.presentErrorAlert(message: "An unexpected failure has occured")
        }
        
        self.teardownAVCapture()
        
        return nil
    }
    
    /// - Tag: ConfigureDeviceResolution
    fileprivate func highestResolution420Format(for device: AVCaptureDevice) -> (format: AVCaptureDevice.Format, resolution: CGSize)? {
        var highestResolutionFormat: AVCaptureDevice.Format? = nil
        var highestResolutionDimensions = CMVideoDimensions(width: 0, height: 0)
        
        for format in device.formats {
            let deviceFormat = format as AVCaptureDevice.Format
            
            let deviceFormatDescription = deviceFormat.formatDescription
            if CMFormatDescriptionGetMediaSubType(deviceFormatDescription) == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange {
                let candidateDimensions = CMVideoFormatDescriptionGetDimensions(deviceFormatDescription)
                if (highestResolutionFormat == nil) || (candidateDimensions.width > highestResolutionDimensions.width) {
                    highestResolutionFormat = deviceFormat
                    highestResolutionDimensions = candidateDimensions
                }
            }
        }
        
        if highestResolutionFormat != nil {
            let resolution = CGSize(width: CGFloat(highestResolutionDimensions.width), height: CGFloat(highestResolutionDimensions.height))
            return (highestResolutionFormat!, resolution)
        }
        
        return nil
    }
    
    fileprivate func configureFrontCamera(for captureSession: AVCaptureSession) throws -> (device: AVCaptureDevice, resolution: CGSize) {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
        
        if let device = deviceDiscoverySession.devices.first {
            if let deviceInput = try? AVCaptureDeviceInput(device: device) {
                if captureSession.canAddInput(deviceInput) {
                    captureSession.addInput(deviceInput)
                }
                
                if let highestResolution = self.highestResolution420Format(for: device) {
                    try device.lockForConfiguration()
                    device.activeFormat = highestResolution.format
                    device.unlockForConfiguration()
                    
                    return (device, highestResolution.resolution)
                }
            }
        }
        
        throw NSError(domain: "ViewController", code: 1, userInfo: nil)
    }
    
    /// - Tag: CreateSerialDispatchQueue
    fileprivate func configureVideoDataOutput(for inputDevice: AVCaptureDevice, resolution: CGSize, captureSession: AVCaptureSession) {
        
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        
        // Create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured.
        // A serial dispatch queue must be used to guarantee that video frames will be delivered in order.
        let videoDataOutputQueue = DispatchQueue(label: "com.example.apple-samplecode.VisionFaceTrack")
        videoDataOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
        
        videoDataOutput.connection(with: .video)?.isEnabled = true
        
        if let captureConnection = videoDataOutput.connection(with: AVMediaType.video) {
            if captureConnection.isCameraIntrinsicMatrixDeliverySupported {
                captureConnection.isCameraIntrinsicMatrixDeliveryEnabled = true
            }
        }
        
        self.videoDataOutput = videoDataOutput
        self.videoDataOutputQueue = videoDataOutputQueue
        
        self.captureDevice = inputDevice
        self.captureDeviceResolution = resolution
    }
    
    /// - Tag: DesignatePreviewLayer
    fileprivate func designatePreviewLayer(for captureSession: AVCaptureSession) {
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        self.previewLayer = videoPreviewLayer
        
        videoPreviewLayer.name = "CameraPreview"
        videoPreviewLayer.backgroundColor = UIColor.black.cgColor
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        if let previewRootLayer = self.previewView?.layer {
            self.rootLayer = previewRootLayer
            
            previewRootLayer.masksToBounds = true
            videoPreviewLayer.frame = previewRootLayer.bounds
            previewRootLayer.addSublayer(videoPreviewLayer)
        }
    }
    
    // Removes infrastructure for AVCapture as part of cleanup.
    fileprivate func teardownAVCapture() {
        self.videoDataOutput = nil
        self.videoDataOutputQueue = nil
        
        if let previewLayer = self.previewLayer {
            previewLayer.removeFromSuperlayer()
            self.previewLayer = nil
        }
    }
    
    // MARK: Helper Methods for Error Presentation
    
    fileprivate func presentErrorAlert(withTitle title: String = "Unexpected Failure", message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        self.present(alertController, animated: true)
    }
    
    fileprivate func presentError(_ error: NSError) {
        self.presentErrorAlert(withTitle: "Failed with error \(error.code)", message: error.localizedDescription)
    }
    
    // MARK: Helper Methods for Handling Device Orientation & EXIF
    
    fileprivate func radiansForDegrees(_ degrees: CGFloat) -> CGFloat {
        return CGFloat(Double(degrees) * Double.pi / 180.0)
    }
    
    func exifOrientationForDeviceOrientation(_ deviceOrientation: UIDeviceOrientation) -> CGImagePropertyOrientation {
        
        switch deviceOrientation {
        case .portraitUpsideDown:
            return .rightMirrored
            
        case .landscapeLeft:
            return .downMirrored
            
        case .landscapeRight:
            return .upMirrored
            
        default:
            return .leftMirrored
        }
    }
    
    func exifOrientationForCurrentDeviceOrientation() -> CGImagePropertyOrientation {
        return exifOrientationForDeviceOrientation(UIDevice.current.orientation)
    }
    
    // MARK: Performing Vision Requests
    
    /// - Tag: WriteCompletionHandler
    fileprivate func prepareVisionRequest() {
        
        //self.trackingRequests = []
        var requests = [VNTrackObjectRequest]()
        
        let faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: { (request, error) in
            
            if error != nil {
                print("FaceDetection error: \(String(describing: error)).")
            }
            
            guard let faceDetectionRequest = request as? VNDetectFaceRectanglesRequest,
                let results = faceDetectionRequest.results as? [VNFaceObservation] else {
                    return
            }
            DispatchQueue.main.async {
                // Add the observations to the tracking list
                for observation in results {
                    let faceTrackingRequest = VNTrackObjectRequest(detectedObjectObservation: observation)
                    requests.append(faceTrackingRequest)
                }
                self.trackingRequests = requests
            }
        })
        
        // Start with detection.  Find face, then track it.
        self.detectionRequests = [faceDetectionRequest]
        
        self.sequenceRequestHandler = VNSequenceRequestHandler()
        
        self.setupVisionDrawingLayers()
    }
    
    // MARK: Drawing Vision Observations
    
    fileprivate func setupVisionDrawingLayers() {
        let captureDeviceResolution = self.captureDeviceResolution
        
        let captureDeviceBounds = CGRect(x: 0,
                                         y: 0,
                                         width: captureDeviceResolution.width,
                                         height: captureDeviceResolution.height)
        
        let captureDeviceBoundsCenterPoint = CGPoint(x: captureDeviceBounds.midX,
                                                     y: captureDeviceBounds.midY)
        
        let normalizedCenterPoint = CGPoint(x: 0.5, y: 0.5)
        
        guard let rootLayer = self.rootLayer else {
            self.presentErrorAlert(message: "view was not property initialized")
            return
        }
        
        let overlayLayer = CALayer()
        overlayLayer.name = "DetectionOverlay"
        overlayLayer.masksToBounds = true
        overlayLayer.anchorPoint = normalizedCenterPoint
        overlayLayer.bounds = captureDeviceBounds
        overlayLayer.position = CGPoint(x: rootLayer.bounds.midX, y: rootLayer.bounds.midY)
        
        let faceRectangleShapeLayer = CAShapeLayer()
        faceRectangleShapeLayer.name = "RectangleOutlineLayer"
        faceRectangleShapeLayer.bounds = captureDeviceBounds
        faceRectangleShapeLayer.anchorPoint = normalizedCenterPoint
        faceRectangleShapeLayer.position = captureDeviceBoundsCenterPoint
        faceRectangleShapeLayer.fillColor = nil
        faceRectangleShapeLayer.strokeColor = UIColor.green.withAlphaComponent(0.7).cgColor
        faceRectangleShapeLayer.lineWidth = 5
        faceRectangleShapeLayer.shadowOpacity = 0.7
        faceRectangleShapeLayer.shadowRadius = 5
        
        let faceLandmarksShapeLayer = CAShapeLayer()
        faceLandmarksShapeLayer.name = "FaceLandmarksLayer"
        faceLandmarksShapeLayer.bounds = captureDeviceBounds
        faceLandmarksShapeLayer.anchorPoint = normalizedCenterPoint
        faceLandmarksShapeLayer.position = captureDeviceBoundsCenterPoint
        faceLandmarksShapeLayer.fillColor = nil
        faceLandmarksShapeLayer.strokeColor = UIColor.yellow.withAlphaComponent(0.7).cgColor
        faceLandmarksShapeLayer.lineWidth = 3
        faceLandmarksShapeLayer.shadowOpacity = 0.7
        faceLandmarksShapeLayer.shadowRadius = 5
        
        let detectedLineLayer = CAShapeLayer()
        detectedLineLayer.name = "LineLayer"
        detectedLineLayer.bounds = captureDeviceBounds
        detectedLineLayer.anchorPoint = normalizedCenterPoint
        detectedLineLayer.position = captureDeviceBoundsCenterPoint
        detectedLineLayer.fillColor = nil
        detectedLineLayer.strokeColor = UIColor.yellow.withAlphaComponent(0.7).cgColor
        detectedLineLayer.lineWidth = 10
        detectedLineLayer.shadowOpacity = 0.7
        detectedLineLayer.shadowRadius = 5
        
        faceRectangleShapeLayer.addSublayer(detectedLineLayer)
        overlayLayer.addSublayer(faceRectangleShapeLayer)
        faceRectangleShapeLayer.addSublayer(faceLandmarksShapeLayer)
        rootLayer.addSublayer(overlayLayer)
        
        self.detectionOverlayLayer = overlayLayer
        self.detectedFaceRectangleShapeLayer = faceRectangleShapeLayer
        self.detectedFaceLandmarksShapeLayer = faceLandmarksShapeLayer
        self.detectedLineLayer = detectedLineLayer
        
        self.updateLayerGeometry()
    }
    
    fileprivate func updateLayerGeometry() {
        guard let overlayLayer = self.detectionOverlayLayer,
            let rootLayer = self.rootLayer,
            let previewLayer = self.previewLayer
            else {
            return
        }
        
        CATransaction.setValue(NSNumber(value: true), forKey: kCATransactionDisableActions)
        
        let videoPreviewRect = previewLayer.layerRectConverted(fromMetadataOutputRect: CGRect(x: 0, y: 0, width: 1, height: 1))
        
        var rotation: CGFloat
        var scaleX: CGFloat
        var scaleY: CGFloat
        
        // Rotate the layer into screen orientation.
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            rotation = 180
            scaleX = videoPreviewRect.width / captureDeviceResolution.width
            scaleY = videoPreviewRect.height / captureDeviceResolution.height
            
        case .landscapeLeft:
            rotation = 90
            scaleX = videoPreviewRect.height / captureDeviceResolution.width
            scaleY = scaleX
            
        case .landscapeRight:
            rotation = -90
            scaleX = videoPreviewRect.height / captureDeviceResolution.width
            scaleY = scaleX
            
        default:
            rotation = 0
            scaleX = videoPreviewRect.width / captureDeviceResolution.width
            scaleY = videoPreviewRect.height / captureDeviceResolution.height
        }
        
        // Scale and mirror the image to ensure upright presentation.
        let affineTransform = CGAffineTransform(rotationAngle: radiansForDegrees(rotation))
            .scaledBy(x: scaleX, y: -scaleY)
        overlayLayer.setAffineTransform(affineTransform)
        
        // Cover entire screen UI.
        let rootLayerBounds = rootLayer.bounds
        overlayLayer.position = CGPoint(x: rootLayerBounds.midX, y: rootLayerBounds.midY)
    }
    
    fileprivate func addPoints(in landmarkRegion: VNFaceLandmarkRegion2D, to path: CGMutablePath, applying affineTransform: CGAffineTransform, closingWhenComplete closePath: Bool) {
        let pointCount = landmarkRegion.pointCount
        if pointCount > 1 {
            let points: [CGPoint] = landmarkRegion.normalizedPoints
            path.move(to: points[0], transform: affineTransform)
            path.addLines(between: points, transform: affineTransform)
            if closePath {
                path.addLine(to: points[0], transform: affineTransform)
                path.closeSubpath()
            }
        }
    }
    
    fileprivate func addPointsforLine(in pointsArr: [CGPoint], to path: CGMutablePath, applying affineTransform: CGAffineTransform, closingWhenComplete closePath: Bool) {
        let pointCount = pointsArr.count
        if pointCount > 1 {
            path.move(to: pointsArr[0], transform: affineTransform)
            path.addLines(between: pointsArr, transform: affineTransform)
            if closePath {
                path.addLine(to: pointsArr[0], transform: affineTransform)
                path.closeSubpath()
            }
        }
    }
    
    fileprivate func addPointsNonNorm(in pointsArr: [CGPoint], to path: CGMutablePath) {
        let pointCount = pointsArr.count
        if pointCount > 1 {
            path.move(to: pointsArr[0])
            path.addLines(between: pointsArr)
        }
    }
    
    fileprivate func addIndicators(to faceRectanglePath: CGMutablePath, faceLandmarksPath: CGMutablePath, linePath: CGMutablePath, for faceObservation: VNFaceObservation) {
        let displaySize = self.captureDeviceResolution
        
        let faceBounds = VNImageRectForNormalizedRect(faceObservation.boundingBox, Int(displaySize.width), Int(displaySize.height))
        faceRectanglePath.addRect(faceBounds)

        
        if let landmarks = faceObservation.landmarks {
            // Landmarks are relative to -- and normalized within --- face bounds
            let affineTransform = CGAffineTransform(translationX: faceBounds.origin.x, y: faceBounds.origin.y)
                .scaledBy(x: faceBounds.size.width, y: faceBounds.size.height)
            
            // Treat eyebrows and lines as open-ended regions when drawing paths.
            let openLandmarkRegions: [VNFaceLandmarkRegion2D?] = [
                landmarks.leftEyebrow,
                landmarks.rightEyebrow,
                // landmarks.faceContour,
                landmarks.noseCrest,
                landmarks.medianLine
            ]
            for openLandmarkRegion in openLandmarkRegions where openLandmarkRegion != nil {
                self.addPoints(in: openLandmarkRegion!, to: faceLandmarksPath, applying: affineTransform, closingWhenComplete: false)
            }
            
            // Draw eyes, lips, and nose as closed regions.
            let closedLandmarkRegions: [VNFaceLandmarkRegion2D?] = [
                landmarks.leftEye,
                landmarks.rightEye,
                landmarks.outerLips,
                landmarks.innerLips,
                landmarks.nose
            ]
            // testing = landmarks.leftEye?.normalizedPoints[0]
            for closedLandmarkRegion in closedLandmarkRegions where closedLandmarkRegion != nil {
                self.addPoints(in: closedLandmarkRegion!, to: faceLandmarksPath, applying: affineTransform, closingWhenComplete: true)
            }
            let leftEye = closedLandmarkRegions[0]
            let rightEye = closedLandmarkRegions[1]
            let pointsL: [CGPoint] = leftEye!.normalizedPoints
            let pointsR: [CGPoint] = rightEye!.normalizedPoints
            let leftist: CGPoint = pointsL[0]
            let rightist: CGPoint = pointsR[0]
            // let myLine: [CGPoint] = [leftist, rightist]
            let anchor: CGPoint = CGPoint.init(x: leftist.x, y: 2*leftist.y)
            // let anchorLine: [CGPoint] = [leftist, anchor]
            
            let captureDeviceResolution = self.captureDeviceResolution
            print(captureDeviceResolution.height)

            let leftNorm = leftist.applying(affineTransform)
            let rightNorm = rightist.applying(affineTransform)
            let leftCorner = CGPoint(x: 0.0, y: 0.0)
            let rightCorner = CGPoint(x: displaySize.width, y: 0.0)
            
            let tempAngle = self.angleBetweenThreePoints(center: leftist, firstPoint: anchor, secondPoint: rightist)
            
            let fromLeftAngle = self.angleBetweenThreePoints(center: leftCorner, firstPoint: leftNorm, secondPoint: rightCorner)
            let fromRightAngle = self.angleBetweenThreePoints(center: rightCorner, firstPoint: leftCorner, secondPoint: rightNorm)
            print("FromLeftAngle: \(fromLeftAngle)")
            print("FromRightAngle: \(fromRightAngle)")
            print("Width: \(faceBounds.size.width)")
            print("Height: \(faceBounds.size.height)")
            print("Left Eye: \(leftNorm.y)")
            
            let angleTilt = Float(tempAngle)
            let angleFL = Float(fromLeftAngle)
            let angleFR = Float(fromRightAngle)
            

            if (runningAvgArr.count >= 5) {
                runningAvgArr.remove(at: 0)
            }
            runningAvgArr.append(angleTilt)
            runningAvg = calcAverage(numArr: runningAvgArr)
            
            self.sendTiltData(text: String(format: "%.2f", runningAvg), calibrated: false)
            self.sendVertData(textLeft: String(format: "%.2f", angleFL),
                              textRight: String(format: "%.2f", angleFR),
                              calibrated: false)
            
            if (self.isCalibrating) {
                self.anglesTiltForCalibration.append(tempAngle)
//                self.fromLeftForCalibration.append(fromLeftAngle)
//                self.fromRightForCalibration.append(fromRightAngle)
                self.widthsForCalibration.append(faceBounds.size.width)
                self.heightsForCalibration.append(faceBounds.size.height)
                self.calibratedFaceOutline = landmarks.faceContour
                self.calibratedAffineTransform = affineTransform
                self.leftEyeHeightsForCalibration.append(leftNorm.y)
                self.leftEyeXPosForCalbration.append(leftNorm.x)
            }
            if (self.calibrated) {
                self.checkRange(currAngle: runningAvg, currLeftAngle: angleFL, currRightAngle: angleFR)
                self.checkYPos(currPos: Float(leftNorm.y))
                self.checkXPos(currPos: Float(leftNorm.x))
                if let calibratedFace = self.calibratedFaceOutline {
                    if let calibratedAT = self.calibratedAffineTransform {
                        self.addPoints(in: calibratedFace, to: linePath, applying: calibratedAT, closingWhenComplete: false)
                    }
                }

            }
           
        }
    }
    
    /// - Tag: DrawPaths
    fileprivate func drawFaceObservations(_ faceObservations: [VNFaceObservation]) {
        guard let faceRectangleShapeLayer = self.detectedFaceRectangleShapeLayer,
              let faceLandmarksShapeLayer = self.detectedFaceLandmarksShapeLayer, let detectedLineLayer = self.detectedLineLayer
            else {
            return
        }
        
        CATransaction.begin()
        
        CATransaction.setValue(NSNumber(value: true), forKey: kCATransactionDisableActions)
        
        let faceRectanglePath = CGMutablePath()
        let faceLandmarksPath = CGMutablePath()
        let linePath = CGMutablePath()
        
        
        for faceObservation in faceObservations {
            self.addIndicators(to: faceRectanglePath,
                               faceLandmarksPath: faceLandmarksPath, linePath: linePath,
                               for: faceObservation)

        }
        
        faceRectangleShapeLayer.path = faceRectanglePath
        faceLandmarksShapeLayer.path = faceLandmarksPath
        detectedLineLayer.path = linePath
        
        self.updateLayerGeometry()
        
        CATransaction.commit()
    }
    
    // MARK: AVCaptureVideoDataOutputSampleBufferDelegate
    /// - Tag: PerformRequests
    // Handle delegate method callback on receiving a sample buffer.
    public func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        var requestHandlerOptions: [VNImageOption: AnyObject] = [:]
        
        let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil)
        if cameraIntrinsicData != nil {
            requestHandlerOptions[VNImageOption.cameraIntrinsics] = cameraIntrinsicData
        }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to obtain a CVPixelBuffer for the current output frame.")
            return
        }
        
        let exifOrientation = self.exifOrientationForCurrentDeviceOrientation()
        
        guard let requests = self.trackingRequests, !requests.isEmpty else {
            // No tracking object detected, so perform initial detection
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                            orientation: exifOrientation,
                                                            options: requestHandlerOptions)
            
            do {
                guard let detectRequests = self.detectionRequests else {
                    return
                }
                try imageRequestHandler.perform(detectRequests)
            } catch let error as NSError {
                NSLog("Failed to perform FaceRectangleRequest: %@", error)
            }
            return
        }
        
        do {
            try self.sequenceRequestHandler.perform(requests,
                                                     on: pixelBuffer,
                                                     orientation: exifOrientation)
        } catch let error as NSError {
            NSLog("Failed to perform SequenceRequest: %@", error)
        }
        
        // Setup the next round of tracking.
        var newTrackingRequests = [VNTrackObjectRequest]()
        for trackingRequest in requests {
            
            guard let results = trackingRequest.results else {
                return
            }
            
            guard let observation = results[0] as? VNDetectedObjectObservation else {
                return
            }
            
            if !trackingRequest.isLastFrame {
                if observation.confidence > 0.3 {
                    trackingRequest.inputObservation = observation
                } else {
                    trackingRequest.isLastFrame = true
                }
                newTrackingRequests.append(trackingRequest)
            }
        }
        self.trackingRequests = newTrackingRequests
        
        if newTrackingRequests.isEmpty {
            // Nothing to track, so abort.
            return
        }
        
        // Perform face landmark tracking on detected faces.
        var faceLandmarkRequests = [VNDetectFaceLandmarksRequest]()
        
        // Perform landmark detection on tracked faces.
        for trackingRequest in newTrackingRequests {
            
            let faceLandmarksRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request, error) in
                
                if error != nil {
                    print("FaceLandmarks error: \(String(describing: error)).")
                }
                
                guard let landmarksRequest = request as? VNDetectFaceLandmarksRequest,
                    let results = landmarksRequest.results as? [VNFaceObservation] else {
                        return
                }
                
                // Perform all UI updates (drawing) on the main queue, not the background queue on which this handler is being called.
                DispatchQueue.main.async {
                    self.drawFaceObservations(results)
                }
            })
            
            guard let trackingResults = trackingRequest.results else {
                return
            }
            
            guard let observation = trackingResults[0] as? VNDetectedObjectObservation else {
                return
            }
            let faceObservation = VNFaceObservation(boundingBox: observation.boundingBox)
            faceLandmarksRequest.inputFaceObservations = [faceObservation]
            
            // Continue to track detected facial landmarks.
            faceLandmarkRequests.append(faceLandmarksRequest)
            
            let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                            orientation: exifOrientation,
                                                            options: requestHandlerOptions)
            
            do {
                try imageRequestHandler.perform(faceLandmarkRequests)
            } catch let error as NSError {
                NSLog("Failed to perform FaceLandmarkRequest: %@", error)
            }
        }
    }
    
    // MARK: Navigation
    @IBAction func doneCapturing(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: Actions
    @IBAction func calibrate(_ sender: UIButton) {
        self.anglesTiltForCalibration.removeAll()
//        self.fromLeftForCalibration.removeAll()
//        self.fromRightForCalibration.removeAll()
        self.leftEyeXPosForCalbration.removeAll()
        self.leftEyeHeightsForCalibration.removeAll()
        self.widthsForCalibration.removeAll()
        self.heightsForCalibration.removeAll()
        warningFeedback.text = "CALIBRATING..."
        self.isCalibrating = true
        self.calibrated = false
        _ = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) {_ in
            self.fixAngle()
            self.isCalibrating = false
        }
    }
    
    @IBAction func playVideo(_ sender: UIButton) {
        if self.videoRootLayer == nil {
            initializeVideo()
        }
        
        if (!self.vidIsOpen) {
            self.rootLayer?.isHidden = true
            self.videoRootLayer?.isHidden = false
            self.playerLayer?.isHidden = false
            self.updatePlayButtonTitle(isPlaying: true)
            self.vidIsOpen = true
            //self.player?.rate = 1.0
        } else {
            self.rootLayer?.isHidden = false
            self.videoRootLayer?.isHidden = true
            self.playerLayer?.isHidden = true

            self.updatePlayButtonTitle(isPlaying: false)
            //self.player?.rate = 0.0
            videoView.pauseVideo()
            self.vidIsOpen = false
        }
        
    }
    
}


// MARK: - Helpers
extension FaceDetectionController {
    fileprivate func angleBetweenThreePoints(center: CGPoint, firstPoint: CGPoint, secondPoint: CGPoint) -> CGFloat {
        let firstAngle: CGFloat = atan2(firstPoint.y - center.y, firstPoint.x - center.x)
        let secondAngle: CGFloat = atan2(secondPoint.y - center.y, secondPoint.x - center.x)
        var angleDiff: CGFloat = firstAngle - secondAngle

        angleDiff = angleDiff * CGFloat(180.0) / CGFloat(Double.pi)
        
        return angleDiff
    }
    
    fileprivate func fixAngle() {
        self.calibrated = true
        
        self.calibratedTiltAngle = calcAverage(numArr: self.anglesTiltForCalibration)
//        self.calibratedfromLeftAngle = calcAverage(numArr: self.fromLeftForCalibration)
//        self.calibratedfromRightAngle = calcAverage(numArr: self.fromRightForCalibration)
        self.calibratedWidth = calcAverage(numArr: self.widthsForCalibration)
        self.calibratedHeight = calcAverage(numArr: self.heightsForCalibration)
        self.calibratedLeftEyeYPos = calcAverage(numArr: self.leftEyeHeightsForCalibration)
        self.calibratedLeftEyeXPos = calcAverage(numArr: self.leftEyeXPosForCalbration)
        
        self.sendTiltData(text: String(format: "%.2f", self.calibratedTiltAngle), calibrated: true)
//        self.sendVertData(textLeft: String(format: "%.2f", self.calibratedfromLeftAngle),
//                          textRight: String(format: "%.2f", self.calibratedfromRightAngle),
//                          calibrated: true)
        
    }
    
    fileprivate func calcAverage(numArr: [CGFloat]) -> Float {
        let count = numArr.count
        let sum = numArr.reduce(0, +)
        return Float(sum) / Float(count)
    }
    
    fileprivate func calcAverage(numArr: [Float]) -> Float {
        let count = numArr.count
        let sum = numArr.reduce(0, +)
        return Float(sum) / Float(count)
    }
    
    fileprivate func checkYPos(currPos: Float) {
        if (self.calibrated) {
            let range = (1 - self.acceptableProp) * self.calibratedHeight
            if (currPos > self.calibratedLeftEyeYPos + range) {
                testLab.text = "TILT DOWN"
            }
            else if (currPos < self.calibratedLeftEyeYPos - range) {
                testLab.text = "TILT UP"
            }
            else {
                testLab.text = "GOOD"
            }
        }
    }
    
    fileprivate func checkXPos(currPos: Float) {
        if (self.calibrated) {
            let range = (1 - self.acceptableProp) * self.calibratedWidth
            if (currPos > self.calibratedLeftEyeXPos + range) {
                testLab.text = "TURN RIGHT"
            }
            else if (currPos < self.calibratedLeftEyeXPos - range) {
                testLab.text = "TURN LEFT"
            }
            else {
                testLab.text = "GOOD"
            }
        }
    }
    
    fileprivate func checkRange(currAngle: Float, currLeftAngle: Float, currRightAngle: Float) {
        if (self.calibrated) {
            self.checkTiltRange(currAngle: currAngle)
            // self.checkVerticalRange(currLeftAngle: currLeftAngle, currRightAngle: currRightAngle)
            if (!self.outTiltLeft && !self.outTiltRight && !self.outDown && !self.outUp) {
                warningFeedback.text = "GOOD JOB!"
                arrowImage.image = UIImage(systemName: "face.smiling")
                arrowImage.tintColor = .systemYellow
                self.animateArrows(animationType: 0)
            }
            else {
                warningFeedback.text = "RETURN TO POSITION"
            }

        }
    }
    
    fileprivate func checkTiltRange(currAngle: Float) {
        if ((currAngle > self.calibratedTiltAngle + self.acceptableRange) && self.outTiltRight) {
            return
        }
        if ((currAngle < self.calibratedTiltAngle - self.acceptableRange) && self.outTiltLeft) {
            return
        }
        if (currAngle > self.calibratedTiltAngle + self.acceptableRange) {
            // warningFeedback.text = "WARNING TILT LEFT"
            // outerView.backgroundColor = UIColor.systemRed
            arrowImage.image = UIImage(systemName: "arrow.left")
            arrowImage.tintColor = .black
            
            self.animateArrows(animationType: 1)
            if (self.vidIsOpen) {
                // self.player?.rate = 0.0
                videoView.pauseVideo()
            }
            
            self.outTiltRight = true

        }
        else if (currAngle < self.calibratedTiltAngle - self.acceptableRange) {
            // warningFeedback.text = "WARNING TILT RIGHT"
            // outerView.backgroundColor = UIColor.systemRed
            arrowImage.image = UIImage(systemName: "arrow.right")
            arrowImage.tintColor = .black

            self.animateArrows(animationType: 2)
            if (self.vidIsOpen) {
                // self.player?.rate = 0.0
                videoView.pauseVideo()
            }
            
            self.outTiltLeft = true
        }
        else {
            // warningFeedback.text = "GOOD JOB"
            // outerView.backgroundColor = UIColor.white
            // arrowImage.image = UIImage(systemName: "face.smiling")
            // arrowImage.tintColor = .systemYellow
            if (self.vidIsOpen) {
                // self.player?.rate = 1.0
                videoView.playVideo()
            }
            // self.animateArrows(animationType: 0)
            self.outTiltRight = false
            self.outTiltLeft = false
            
        }
        
    }
    
//    fileprivate func checkVerticalRange(currLeftAngle: Float, currRightAngle: Float) {
//        if (currRightAngle > self.calibratedfromRightAngle + self.acceptableUpRange && currLeftAngle > self.calibratedfromLeftAngle + self.acceptableUpRange)  {
//            if (self.outUp) {
//                return
//            }
//            // warningFeedback.text = "WARNING TILT DOWN"
//            // outerView.backgroundColor = UIColor.systemRed
//            arrowImage.image = UIImage(systemName: "arrow.down")
//            arrowImage.tintColor = .black
//
//            self.animateArrows(animationType: 3)
//            if (self.vidIsOpen) {
//                videoView.pauseVideo()
//                //self.player?.rate = 0.0
//            }
//            self.outUp = true
//
//        }
//        else if (currRightAngle < self.calibratedfromRightAngle - self.acceptableRange && currLeftAngle < self.calibratedfromLeftAngle - self.acceptableRange)  {
//            if (self.outDown) {
//                return
//            }
//            // warningFeedback.text = "WARNING TILT UP"
//            // outerView.backgroundColor = UIColor.systemRed
//            arrowImage.image = UIImage(systemName: "arrow.up")
//            arrowImage.tintColor = .black
//
//            self.animateArrows(animationType: 4)
//            if (self.vidIsOpen) {
//                videoView.pauseVideo()
//                //self.player?.rate = 0.0
//            }
//            self.outDown = true
//
//        }
//        else {
//            // warningFeedback.text = "GOOD JOB"
//            // outerView.backgroundColor = UIColor.white
//            // arrowImage.image = UIImage(systemName: "face.smiling")
//            // arrowImage.tintColor = .systemYellow
//            if (self.vidIsOpen) {
//                // self.player?.rate = 1.0
//                videoView.playVideo()
//            }
//            // self.animateArrows(animationType: 5)
//            self.outUp = false
//            self.outDown = false
//
//        }
//    }
    
    fileprivate func updatePlayButtonTitle(isPlaying: Bool) {
      if isPlaying {
        playButton.setTitle("Pause", for: .normal)
      } else {
        playButton.setTitle("Play", for: .normal)
      }
    }
    
    fileprivate func initializeVideo() {
        
        // let playerLayer = AVPlayerLayer()
        
        
        // playerLayer.name = "VideoPreview"
        // playerLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        if let previewVideoLayer = self.videoView?.layer {
            self.videoRootLayer = previewVideoLayer
            previewVideoLayer.masksToBounds = true
            // playerLayer.frame = previewVideoLayer.bounds
            // previewVideoLayer.addSublayer(playerLayer)
        }
        
        videoView.load(withVideoId: "cBd7eQ3UXOE", playerVars: ["playsinline":"1"])

//
//        // 2
//        let url = Bundle.main.url(forResource: "colorfulStreak", withExtension: "m4v")!
//        let item = AVPlayerItem(asset: AVAsset(url: url))
//        let player = AVPlayer(playerItem: item)
//
//        // 3
//        player.actionAtItemEnd = .none
//
//        // 4
//        player.volume = 1.0
//        player.rate = 0.0
//
//        playerLayer.player = player
//        self.playerLayer = playerLayer

    }
    
    fileprivate func animateArrows(animationType: Int) {
        DispatchQueue.main.async {
            if (self.calibrated) {
                if (animationType == 0) {
                    UIView.animate(withDuration: 1, delay: 0, animations: {
                        self.arrowImage.transform = .identity
                        return
                    })
                }
                if (animationType == 5) {
                    UIView.animate(withDuration: 1, delay: 0, animations: {
                        self.arrowImage.transform = .identity
                        return
                    })
                }
                UIView.animate(withDuration: 3, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 1, options: [.curveEaseOut, .repeat], animations: {
                    switch animationType {
                    case 0:
                        self.arrowImage.transform = .identity
                        break
                    case 1:
                        self.arrowImage.transform = CGAffineTransform(translationX: -100, y: 0)
                        break
                    case 2:
                        self.arrowImage.transform = CGAffineTransform(translationX: 100, y: 0)
                        break
                    case 3: // up
                        self.arrowImage.transform = CGAffineTransform(translationX: 0, y: 50)
                        break
                    case 4: // down
                        self.arrowImage.transform = CGAffineTransform(translationX: 0, y: -50)
                        break
                    case 5:
                        self.arrowImage.transform = .identity
                    default:
                        break
                    }
                }, completion: nil)
            }

        }
    }
    
    fileprivate func sendTiltData(text: String, calibrated: Bool) {
        let CVC = children.last as! AngleInfoViewController
        if (calibrated) { // send calibrated value
            CVC.changeCalibratedLabel(textLeft: text, textRight: "", type: 0)
        }
        else {
            CVC.changeLiveLabel(textLeft: text, textRight: "", type: 0)
        }
    }
    
    fileprivate func sendVertData(textLeft: String, textRight: String, calibrated: Bool) {
        let CVC = children.last as! AngleInfoViewController
        if (calibrated) {
            CVC.changeCalibratedLabel(textLeft: textLeft, textRight: textRight, type: 1)
        }
        else {
            CVC.changeLiveLabel(textLeft: textLeft, textRight: textRight, type: 1)
        }


    }
    
}

