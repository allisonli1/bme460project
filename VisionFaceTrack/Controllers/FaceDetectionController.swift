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
import MediaPlayer


class FaceDetectionController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    // Storyboard variables
    @IBOutlet weak var previewView: UIView? // Main view for showing camera content.
    @IBOutlet weak var warningFeedback: UILabel!
    @IBOutlet var outerView: UIView!
    @IBOutlet weak var arrowImage: UIImageView!
    @IBOutlet weak var videoView: YTPlayerView!
    @IBOutlet weak var initialStackView: UIStackView!
    @IBOutlet weak var senseSlider: UISlider!
    @IBOutlet weak var senseLabel: UILabel!
    @IBOutlet weak var calibrateButton: UIButton!
    @IBOutlet weak var stopSessionButton: UIButton!
    @IBOutlet weak var selectPlaylistButton: UIButton!
    @IBOutlet weak var startWithoutButton: UIButton!
    @IBOutlet weak var initialCamLabel: UILabel!
    @IBOutlet weak var noVidLabel: UILabel!
    
    
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
    
    // Feedback indicators for tilting head
    var calibratedFaceOutline: VNFaceLandmarkRegion2D?
    var calibratedAffineTransform: CGAffineTransform?
    var anglesTiltForCalibration: [CGFloat] = []
    var calibratedTiltAngle: Float = 0.0
    var calibrated: Bool = false
    var isCalibrating = false
    var acceptableRangeInitial: Float = 5.0
    var acceptableRange: Float = 5.0
    var outTiltLeft = false
    var outTiltRight = false
    var prevOutOfRange = false
    
    // Feedback indicators for up + down movement
    var outDown = false
    var outUp = false
    var outRight = false
    var outLeft = false
    
    // Feedback indicators up and down
    var calibratedWidth: Float = 0.0
    var calibratedHeight: Float = 0.0
    var widthsForCalibration: [CGFloat] = []
    var heightsForCalibration: [CGFloat] = []
    var originalProp: Float = 0.95
    var originalPropUp: Float = 0.98
    var acceptableProp: Float = 0.90
    var acceptablePropUp: Float = 0.95
    var calibratedLeftEyeYPos: Float = 0.0
    var leftEyeHeightsForCalibration: [CGFloat] = []
    
    // Feedback indicators left and right
    var calibratedLeftEyeXPos: Float = 0.0
    var leftEyeXPosForCalibration: [CGFloat] = []
    
    var runningAvgCurrAngle: Float = -1
    var runningAvgCurrAngleArr: [Float] = []
    var runningAvgCurrXPos: Float = -1
    var runningAvgCurrXPosArr: [Float] = []
    var runningAvgCurrYPos: Float = -1
    var runningAvgCurrYPosArr: [Float] = []
    var sensitivityValue: Float = 1.0
    
    var prevAnimationType: Int = 0
    
    // Video Player Variables
    var videoRootLayer: CALayer?
    var vidIsOpen = false
    var videoList = [String]()
    var cued = false
 
    // MARK: UIViewController overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Initializing UI text
        overrideUserInterfaceStyle = .light
        videoView.delegate = self
        initialCamLabel.font = UIFont(name: "AppleSDGothicNeo-UltraLight", size: 20)
        noVidLabel.font = UIFont(name: "AppleSDGothicNeo-UltraLight", size: 20)
        senseLabel.font = UIFont(name: "AppleSDGothicNeo-UltraLight", size: 20)
        warningFeedback.font = UIFont(name: "AppleSDGothicNeo-UltraLight", size: 30)
        
        calibrateButton.layer.cornerRadius = 20
        calibrateButton.layer.backgroundColor = UIColor(red: 0.256, green: 0.389, blue: 0.740, alpha: 1).cgColor
        calibrateButton.setTitleColor(UIColor.white, for: .normal)
        calibrateButton.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-UltraLight", size: 30)
        
        stopSessionButton.layer.cornerRadius = 20
        stopSessionButton.layer.backgroundColor = UIColor(red: 0.256, green: 0.389, blue: 0.740, alpha: 1).cgColor
        stopSessionButton.setTitleColor(UIColor.white, for: .normal)
        stopSessionButton.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-UltraLight", size: 30)
        
        selectPlaylistButton.layer.cornerRadius = 20
        selectPlaylistButton.layer.backgroundColor = UIColor(red: 0.256, green: 0.389, blue: 0.740, alpha: 1).cgColor
        selectPlaylistButton.setTitleColor(UIColor.white, for: .normal)
        selectPlaylistButton.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-UltraLight", size: 30)
        
        startWithoutButton.layer.cornerRadius = 20
        startWithoutButton.layer.backgroundColor = UIColor(red: 0.256, green: 0.389, blue: 0.740, alpha: 1).cgColor
        startWithoutButton.setTitleColor(UIColor.white, for: .normal)
        startWithoutButton.titleLabel?.font = UIFont(name: "AppleSDGothicNeo-UltraLight", size: 30)

        warningFeedback.text = ""
        if let sense = UserDefaults.standard.object(forKey: "sensitivity") as? Float {
            senseSlider.value = sense
            self.sensitivityValue = sense
        }
        else {
            senseSlider.value = 1.0
            self.sensitivityValue = 1.0
        }
        senseLabel.text = String(format: "Sensitivity: %0.0f%%", senseSlider.value * 100)
        calibrateButton.isEnabled = false
        changeButtonStatus(button: calibrateButton)
        stopSessionButton.isEnabled = false
        changeButtonStatus(button: stopSessionButton)
        noVidLabel.text = ""
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.session?.stopRunning()
        if (self.videoList.count > 0) {
            self.videoView?.stopVideo()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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
            print("Videos: \(self.videoList)")
            
            let angleTilt = Float(tempAngle)

            if (runningAvgCurrAngleArr.count >= 10) {
                runningAvgCurrAngleArr.remove(at: 0)
                runningAvgCurrXPosArr.remove(at: 0)
                runningAvgCurrYPosArr.remove(at: 0)
            }
            runningAvgCurrAngleArr.append(angleTilt)
            runningAvgCurrXPosArr.append(Float(leftNorm.x))
            runningAvgCurrYPosArr.append(Float(leftNorm.y))
            runningAvgCurrAngle = calcAverage(numArr: runningAvgCurrAngleArr)
            runningAvgCurrXPos = calcAverage(numArr: runningAvgCurrXPosArr)
            runningAvgCurrYPos = calcAverage(numArr: runningAvgCurrYPosArr)
            
            if (self.isCalibrating) {
                self.anglesTiltForCalibration.append(tempAngle)
                self.widthsForCalibration.append(faceBounds.size.width)
                self.heightsForCalibration.append(faceBounds.size.height)
                self.calibratedFaceOutline = landmarks.faceContour
                self.calibratedAffineTransform = affineTransform
                self.leftEyeHeightsForCalibration.append(leftNorm.y)
                self.leftEyeXPosForCalibration.append(leftNorm.x)
            }
            if (self.calibrated) {
                if (self.sensitivityValue > 0) {
                    self.checkPosition(currAngle: runningAvgCurrAngle, currXPos: runningAvgCurrXPos, currYPos: runningAvgCurrYPos)
                }
                else {
                    warningFeedback.text = "0% Sensitivity"
                    self.arrowImage.image = nil
                }
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

    // MARK: Actions
    @IBAction func doneSession(_ sender: Any) {
        self.session?.stopRunning()
        self.previewLayer?.removeFromSuperlayer()
        self.videoView?.removeFromSuperview()
        // navigationController?.popViewController(animated: true)
        print("HERE in done")
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func startWithoutPlaylist(_ sender: UIButton) {
        if (startWithoutButton != nil) {
            startWithoutButton.removeFromSuperview()
        }
        noVidLabel.text = "Warning: No Videos Queued"
        if (initialCamLabel != nil) {
            initialCamLabel.removeFromSuperview()
        }
        self.session = self.setupAVCaptureSession()
        self.prepareVisionRequest()
        self.session?.startRunning()
        self.vidIsOpen = false
        calibrateButton.isEnabled = true
        changeButtonStatus(button: calibrateButton)
        stopSessionButton.isEnabled = true
        changeButtonStatus(button: stopSessionButton)
        
    }
    
    @IBAction func calibrate(_ sender: UIButton) {
        self.anglesTiltForCalibration.removeAll()
        self.leftEyeXPosForCalibration.removeAll()
        self.leftEyeHeightsForCalibration.removeAll()
        self.widthsForCalibration.removeAll()
        self.heightsForCalibration.removeAll()
        warningFeedback.text = "CALIBRATING..."
        arrowImage.image = nil
        self.isCalibrating = true
        self.calibrated = false
        _ = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) {_ in
            self.fixAngle()
            self.isCalibrating = false
        }
    }
    
    @IBAction func changeSensitivity(_ sender: UISlider) {
        self.acceptableProp = senseSlider.value * self.originalProp
        self.acceptablePropUp = senseSlider.value * self.originalPropUp
        self.acceptableRange = 30 - senseSlider.value * 100 * 0.25
        senseLabel.text = String(format: "Sensitivity: %0.0f%%", senseSlider.value * 100)
        self.sensitivityValue = senseSlider.value
        UserDefaults.standard.set(senseSlider.value, forKey: "sensitivity")
    }
    
    @IBAction func stopFeedback(_ sender: UIButton) {
        self.anglesTiltForCalibration.removeAll()
        self.leftEyeXPosForCalibration.removeAll()
        self.leftEyeHeightsForCalibration.removeAll()
        self.widthsForCalibration.removeAll()
        self.heightsForCalibration.removeAll()
        arrowImage.image = nil
        self.isCalibrating = false
        self.calibrated = false
        warningFeedback.text = "Not Calibrated"
        
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
        self.calibratedWidth = calcAverage(numArr: self.widthsForCalibration)
        self.calibratedHeight = calcAverage(numArr: self.heightsForCalibration)
        self.calibratedLeftEyeYPos = calcAverage(numArr: self.leftEyeHeightsForCalibration)
        self.calibratedLeftEyeXPos = calcAverage(numArr: self.leftEyeXPosForCalibration)
        
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
    
    fileprivate func checkPosition(currAngle: Float, currXPos: Float, currYPos: Float) {
        let outHorizontal = !(self.checkXPosInRange(currPos: currXPos))
        let outVertical = !(self.checkYPosInRange(currPos: currYPos))
        let outTilt = !(self.checkTiltInRange(currAngle: currAngle))
        
        
//        if ((outHorizontal || outVertical || outTilt) && !prevOutOfRange) {
//            _ = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) {_ in
//                if (self.prevOutOfRange) {
//                    if (self.vidIsOpen) {
//                        // self.rootLayer?.isHidden = false
//                    }
//                }
//            }
//        }
        if (outHorizontal || outVertical || outTilt) {
            prevOutOfRange = true
        }
        if (outHorizontal) {
            if (self.outLeft) {
                warningFeedback.text = "TURN RIGHT"
                arrowImage.image = UIImage(systemName: "arrow.right")
                arrowImage.tintColor = .black
                if (prevAnimationType != 2) {
                    self.animateArrows(animationType: 0)
                }
                self.animateArrows(animationType: 2)
                prevAnimationType = 2
            }
            else if (self.outRight) {
                warningFeedback.text = "TURN LEFT"
                arrowImage.image = UIImage(systemName: "arrow.left")
                arrowImage.tintColor = .black
                if (prevAnimationType != 1) {
                    self.animateArrows(animationType: 0)
                }
                self.animateArrows(animationType: 1)
                prevAnimationType = 1
            }
            if (self.vidIsOpen) {
                videoView.pauseVideo()
            }
        }
        else if (outVertical) {
            if (self.outUp) {
                warningFeedback.text = "TILT DOWN"
                arrowImage.image = UIImage(systemName: "arrow.down")
                arrowImage.tintColor = .black
                if (prevAnimationType != 3) {
                    self.animateArrows(animationType: 0)
                }
                self.animateArrows(animationType: 3)
                prevAnimationType = 3
            }
            else if (self.outDown) {
                warningFeedback.text = "TILT UP"
                arrowImage.image = UIImage(systemName: "arrow.up")
                arrowImage.tintColor = .black
                if (prevAnimationType != 4) {
                    self.animateArrows(animationType: 0)
                }
                self.animateArrows(animationType: 4)
                prevAnimationType = 4
            }
            if (self.vidIsOpen) {
                videoView.pauseVideo()
            }
        }
        else if (outTilt) {
            if (self.outTiltLeft) {
                warningFeedback.text = "TILT RIGHT"
                if (prevAnimationType != 2) {
                    self.animateArrows(animationType: 0)
                }
                arrowImage.image = UIImage(systemName: "arrow.right")
                arrowImage.tintColor = .black
                self.animateArrows(animationType: 2)
                prevAnimationType = 2
            }
            else if (self.outTiltRight) {
                warningFeedback.text = "TILT LEFT"
                arrowImage.image = UIImage(systemName: "arrow.left")
                arrowImage.tintColor = .black
                if (prevAnimationType != 1) {
                    self.animateArrows(animationType: 0)
                }
                self.animateArrows(animationType: 1)
                prevAnimationType = 1
            }
            if (self.vidIsOpen) {
                videoView.pauseVideo()
            }
        }
        else {
            warningFeedback.text = "GOOD JOB!"
            arrowImage.image = UIImage(systemName: "face.smiling")
            arrowImage.tintColor = .systemYellow
            self.animateArrows(animationType: 0)
            if (self.vidIsOpen) {
                videoView.playVideo()
            }
            prevOutOfRange = false
        }
        
    }
    
    fileprivate func checkYPosInRange(currPos: Float) -> Bool {
        if (self.calibrated) {
            let range = (1 - self.acceptableProp) * self.calibratedHeight
            let rangeUp = (1 - self.acceptablePropUp) * self.calibratedHeight
            if (currPos > self.calibratedLeftEyeYPos + rangeUp) {
                self.outUp = true
            }
            else if (currPos < self.calibratedLeftEyeYPos - range) {
                self.outDown = true
            }
            else {
                self.outUp = false
                self.outDown = false
            }
        }
        
        if (!self.outUp && !self.outDown) {
            return true
        }
        return false
    }
    
    fileprivate func checkXPosInRange(currPos: Float) -> Bool {
        if (self.calibrated) {
            let range = (1 - self.acceptableProp) * self.calibratedWidth
            if (currPos > self.calibratedLeftEyeXPos + range) {
                self.outRight = true
            }
            else if (currPos < self.calibratedLeftEyeXPos - range) {
                self.outLeft = true
            }
            else {
                self.outRight = false
                self.outLeft = false
            }
        }
        if (!self.outRight && !self.outLeft) {
            return true
        }
        return false
    }
    
    fileprivate func checkTiltInRange(currAngle: Float) -> Bool {
        if (self.calibrated) {
            if ((currAngle > self.calibratedTiltAngle + self.acceptableRange) && self.outTiltRight) {
                return false
            }
            if ((currAngle < self.calibratedTiltAngle - self.acceptableRange) && self.outTiltLeft) {
                return false
            }
            if (currAngle > self.calibratedTiltAngle + self.acceptableRange) {
                self.outTiltRight = true
            }
            else if (currAngle < self.calibratedTiltAngle - self.acceptableRange) {
                self.outTiltLeft = true
            }
            else {
                self.outTiltRight = false
                self.outTiltLeft = false
            }
        }
        if (!self.outTiltLeft && !self.outTiltRight) {
            return true
        }
        return false
    }
    
    
    fileprivate func initializeVideo() {
        if let previewVideoLayer = self.videoView?.layer {
            self.videoRootLayer = previewVideoLayer
            previewVideoLayer.masksToBounds = true
        }
        
        videoView.load(withVideoId: self.videoList[0], playerVars: ["playsinline":"1"])
        
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
                    default:
                        break
                    }
                }, completion: nil)
            }

        }
    }
    
    //MARK: Unwind Segues
    @IBAction func sendVideoList(sender: UIStoryboardSegue) {
        if let sourceViewController = sender.source as? EditPlaylistViewController, let plist = sourceViewController.playlist {
            print("\(plist.title)")
            
            self.videoList.append(contentsOf: plist.videoIDs)
        }
        self.session = self.setupAVCaptureSession()
        self.prepareVisionRequest()
        self.session?.startRunning()
        if (initialCamLabel != nil) {
            initialCamLabel.removeFromSuperview()
        }
        
        if (self.videoList.count != 0) {
            if (initialStackView != nil) {
                initialStackView.removeFromSuperview()
            }
            self.vidIsOpen = true
            self.initializeVideo()
        }
        else {
            self.vidIsOpen = false
            if (startWithoutButton != nil) {
                startWithoutButton.removeFromSuperview()
            }
            noVidLabel.text = "Warning: No Videos Queued"
        }
        calibrateButton.isEnabled = true
        changeButtonStatus(button: calibrateButton)
        stopSessionButton.isEnabled = true
        changeButtonStatus(button: stopSessionButton)
    }
    
    @IBAction func cancelFromPopup(_ unwindSegue: UIStoryboardSegue) {
        
    }
    
    fileprivate func changeButtonStatus(button: UIButton) {
        if (button.isEnabled) { // enabled a button
            button.layer.opacity = 1.0
        }
        else {
            button.layer.opacity = 0.2
        }
        
    }
    
}

extension FaceDetectionController: YTPlayerViewDelegate {
    func playerViewDidBecomeReady(_ playerView: YTPlayerView)
    {
        if (!self.cued) {
            playerView.cuePlaylist(byVideos: self.videoList, index: 0, startSeconds: 0)
            self.cued = true
        }
        
    }
}

