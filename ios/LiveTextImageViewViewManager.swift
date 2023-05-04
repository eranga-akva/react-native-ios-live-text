import UIKit
import VisionKit
import Vision

@objc(LiveTextImageViewViewManager)
class LiveTextImageViewViewManager: RCTViewManager {
    override func view() -> (UIView) {
        if #available(iOS 16.0, *) {
            return LiveTextImageViewView()
        } else {
            return UIView()
            // Fallback on earlier versions
        }
    }
    
    @objc override static func requiresMainQueueSetup() -> Bool {
        return false
    }
}

@available(iOS 16.0, *)
class LiveTextImageViewView : UIView {
    private lazy var interaction: ImageAnalysisInteraction = {
        let interaction = ImageAnalysisInteraction()
        interaction.preferredInteractionTypes = .automatic
        return interaction
    }()
    
    private let _imageAnalyzer = ImageAnalyzer()
    private var _mySub: Any? = nil;
    private var _imageView: UIImageView? = nil;

    let pinchGesture = UIPinchGestureRecognizer()
    let tapGesture = UITapGestureRecognizer()
    
    var originalTransform: CGAffineTransform?
    
    
    
    
    let scrollView = UIScrollView()

    // Initialize variables to store image position and scale
    var lastScale: CGFloat = 1.0
    var lastPoint = CGPoint.zero
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        // Set up the scroll view
        scrollView.frame = bounds
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0

        // Set up double tap gesture recognizer
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTap))
        doubleTapRecognizer.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapRecognizer)

        // Set up pinch gesture recognizer
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        scrollView.addGestureRecognizer(pinchRecognizer)

        // Set up pan gesture recognizer
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan))
        scrollView.addGestureRecognizer(panRecognizer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        scrollView.frame = bounds
//        self._imageView?.frame = scrollView.bounds
//    }
    
    // Zoom in on double tap
    @objc func doubleTap(_ recognizer: UITapGestureRecognizer) {
        guard let imageView = self._imageView else {
            return
        }
        if scrollView.zoomScale == 1.0 {
            let point = recognizer.location(in: imageView)
            let zoomRect = zoomRectForScale(scale: 2.0, center: point)
            scrollView.zoom(to: zoomRect, animated: true)
        } else {
            scrollView.setZoomScale(1.0, animated: true)
        }
    }

    // Handle pinch gesture
    @objc func pinch(_ recognizer: UIPinchGestureRecognizer) {
        guard let imageView = self._imageView else {
            return
        }
        if recognizer.state == .began {
            lastScale = 1.0
        }
        let scale = 1.0 - (lastScale - recognizer.scale)
        let currentTransform = imageView.transform
        let newTransform = currentTransform.scaledBy(x: scale, y: scale)
        imageView.transform = newTransform
        lastScale = recognizer.scale
    }
    
//    @objc func pinch(_ recognizer: UIPinchGestureRecognizer) {
//        guard let imageView = self._imageView else {
//            return
//        }
//        if recognizer.state == .began || recognizer.state == .changed {
//            let scale = recognizer.scale
//            let touchLocation = recognizer.location(ofTouch: 0, in: imageView)
//            let zoomRect = zoomRectForScale(scale: scale, center: touchLocation)
//            scrollView.zoom(to: zoomRect, animated: false)
//        }
//    }

    // Handle pan gesture
    @objc func pan(_ recognizer: UIPanGestureRecognizer) {
        guard let imageView = self._imageView else {
            return
        }
        let point = recognizer.translation(in: imageView)
        if recognizer.state == .began {
            lastPoint = imageView.center
        }
        let newPoint = CGPoint(x: lastPoint.x + point.x, y: lastPoint.y + point.y)
        imageView.center = newPoint
    }
    
//    @objc func pan(_ recognizer: UIPanGestureRecognizer) {
//        guard let imageView = imageView else {
//            return
//        }
//        let translation = recognizer.translation(in: imageView)
//        if recognizer.state == .began || recognizer.state == .changed {
//            if recognizer.numberOfTouches == 2 {
//                // Panning with two touches
//                imageView.center = CGPoint(x: imageView.center.x + translation.x, y: imageView.center.y + translation.y)
//                recognizer.setTranslation(CGPoint.zero, in: imageView)
//            }
//        }
//    }
    
    // Calculate zoom rectangle
    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        if let imageView = self._imageView {
            zoomRect.size.height = imageView.frame.size.height / scale
            zoomRect.size.width = imageView.frame.size.width / scale
            let newCenter = imageView.convert(center, from: scrollView)
            zoomRect.origin.x = newCenter.x - zoomRect.size.width / 2.0
            zoomRect.origin.y = newCenter.y - zoomRect.size.height / 2.0
        }
        return zoomRect
    }
    
    
    
    override func didMoveToWindow() {
        if let imageView = self.subviews.first?.subviews.first as? UIImageView {

            self._imageView = imageView

            self._imageView?.contentMode = .scaleAspectFit
            self._imageView?.isUserInteractionEnabled = true
            scrollView.frame = bounds
            self._imageView?.frame = scrollView.bounds
            scrollView.addSubview(self._imageView!)
            addSubview(scrollView)
            // -- custom moon pinch to zoom start

//            self._imageView?.isUserInteractionEnabled = true
//            self._imageView?.contentMode = .scaleAspectFit
//            self._imageView?.addGestureRecognizer(pinchGesture)
//            pinchGesture.addTarget(self, action: #selector(handlePinch(_:)))
//
//            self._imageView?.addGestureRecognizer(tapGesture)
//            tapGesture.numberOfTapsRequired = 2
//            tapGesture.addTarget(self, action: #selector(handleDoubleTap(_:)))

            // -- custom moon pinch to zoom end
            
            self._imageView?.addInteraction(interaction);
            
            self.attachAnalyzerToImage()
            
            self._mySub = _imageView?.observe(\.image, options: [.new]) { object, change in
                    self.attachAnalyzerToImage()
                }
            }
    }

    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else { return }

        view.transform = view.transform.scaledBy(x: gesture.scale, y: gesture.scale)
        gesture.scale = 1.0
    }

    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let view = gesture.view else { return }

        if let originalTransform = originalTransform {
            view.transform = originalTransform
            self.originalTransform = nil
        } else {
            originalTransform = view.transform
            view.transform = .identity
        }
    }
    
    func attachAnalyzerToImage() {
        guard let image = self._imageView?.image else {
                return
            }
        
        Task {
            let configuration = ImageAnalyzer.Configuration([.text, .machineReadableCode])
            
            do {
                let analysis = try await self._imageAnalyzer.analyze(image, configuration: configuration)
                
                DispatchQueue.main.async {
                    self.interaction.analysis = analysis
                    self.interaction.preferredInteractionTypes = .automatic
                }
            } catch {
                print(error.localizedDescription)
            }
        }
            
    }
    
    deinit {
        self._imageView = nil;
        self._mySub = nil
    }
}
