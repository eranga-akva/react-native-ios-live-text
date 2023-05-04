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
    
    override func didMoveToWindow() {
        if let imageView = self.subviews.first?.subviews.first as? UIImageView {

            self._imageView = imageView

            // -- custom moon pinch to zoom start
            
            self._imageView?.isUserInteractionEnabled = true
            self._imageView?.contentMode = .scaleAspectFit
            self._imageView?.addGestureRecognizer(pinchGesture)
            pinchGesture.addTarget(self, action: #selector(handlePinch(_:)))

            self._imageView?.addGestureRecognizer(tapGesture)
            tapGesture.numberOfTapsRequired = 2
            tapGesture.addTarget(self, action: #selector(handleDoubleTap(_:)))
            
//            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
//            self._imageView?.addGestureRecognizer(panGesture)

            // -- custom moon pinch to zoom end
            
            self._imageView?.addInteraction(interaction);
            
            self.attachAnalyzerToImage()
            
            self._mySub = _imageView?.observe(\.image, options: [.new]) { object, change in
                    self.attachAnalyzerToImage()
                }
            }
    }
    
//    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
//        guard let view = gesture.view else { return }
//
//        // Get the translation of the gesture
//        let translation = gesture.translation(in: view.superview)
//
//        // Move the view by the translation
//        view.center = CGPoint(x: view.center.x + translation.x,
//                               y: view.center.y + translation.y)
//
//        // Reset the gesture's translation
//        gesture.setTranslation(.zero, in: view.superview)
//    }
    
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let view = gesture.view else { return }
        
        // Check if the image is scaled beyond its original size
        let isScaled = view.transform.a != 1.0 || view.transform.d != 1.0
        
        // Only allow panning if the image is scaled
        if isScaled {
            // Get the translation of the gesture
            let translation = gesture.translation(in: view.superview)
            
            // Move the view by the translation
            view.center = CGPoint(x: view.center.x + translation.x,
                                   y: view.center.y + translation.y)
            
            // Reset the gesture's translation
            gesture.setTranslation(.zero, in: view.superview)
        }
    }

//    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
//        guard let view = gesture.view else { return }
//
//        view.transform = view.transform.scaledBy(x: gesture.scale, y: gesture.scale)
//        gesture.scale = 1.0
//    }
    
    @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let view = gesture.view else { return }
        
        // Calculate the midpoint of the pinch gesture
        let pinchMidPoint = CGPoint(x: gesture.location(in: view).x - view.bounds.midX,
                                    y: gesture.location(in: view).y - view.bounds.midY)
        
        // Translate the view's origin to the midpoint of the pinch gesture
        var transform = view.transform.translatedBy(x: pinchMidPoint.x, y: pinchMidPoint.y)
        
        // Scale the view
        transform = transform.scaledBy(x: gesture.scale, y: gesture.scale)
        
        // Translate the view's origin back to its original position
        transform = transform.translatedBy(x: -pinchMidPoint.x, y: -pinchMidPoint.y)
        
        // Set the view's transform
        view.transform = transform
        
        // Reset the gesture's scale
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
