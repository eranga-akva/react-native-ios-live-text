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
