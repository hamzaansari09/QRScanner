import UIKit
import RxSwift
import RxCocoa
import AVFoundation


class QRScannerViewController: UIViewController, CallbackObservable {
    typealias Result = QRScanResult
    var result = PublishSubject<Result>()
    private let disposeBag = DisposeBag()

    private let config: QRScanConfig
    private let animView: QRScannerAnimationView
    private lazy var qrImageDetector: QRImageDetector = QRImageDetector.init(config: self.config)
    var delegate: DelegateProxy<AnyObject, Any>?
    private var session: AVCaptureSession?

    init(config: QRScanConfig) {
        self.config = config
        animView = QRScannerAnimationView.init(frame: CGRect.zero, color: config.scannerColor)
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.gray
        title = config.titleText
        let cancelButton = UIBarButtonItem.init(title: config.cancelText, style: .plain, target: nil, action: nil)
        navigationItem.leftBarButtonItem = cancelButton

        animView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animView)
        NSLayoutConstraint.activate([
            animView.widthAnchor.constraint(equalToConstant: 400),
            animView.heightAnchor.constraint(equalToConstant: 400),
            animView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            animView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        animView.alpha = 0

        Observable
            .merge([
                NotificationCenter.default.rx.notification(.UIApplicationDidBecomeActive).map { _ in true },
                NotificationCenter.default.rx.notification(.UIApplicationDidEnterBackground).map { _ in false },
            ])
            .filter { [weak self] _ in self?.view.window != nil }
            .subscribe(onNext: { [weak self] on in
                self?.toggleScan(on: on)
                self?.animView.toggleAnim(on: on)
            })
            .disposed(by: disposeBag)

        cancelButton.rx.tap
            .map { _ in QRScanResult.cancel }
            .subscribe(onNext: { [weak self] (rv) in
                self?.result.onNext(rv)
                self?.result.onCompleted()
                self?.navigationController?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)

        videoAccess()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (status) in
                switch status {
                case .authorized:
                    try? self?.initCamera()
                case .denied:
                    self?.showEmptyView()
                default:
                    break
                }
            })
            .disposed(by: disposeBag)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animView.toggleAnim(on: true)
    }

    private func initCamera() throws {
        // device has no camera
        guard let device = deviceWithMediaType(position: .front) else { return }
        let input = try AVCaptureDeviceInput.init(device: device)
        let session = AVCaptureSession()
        session.canSetSessionPreset(.high)
        session.addInput(input)

        let captureMetadataOutput = AVCaptureMetadataOutput()
        session.addOutput(captureMetadataOutput)

        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        captureMetadataOutput.rectOfInterest = CGRect(x: 0.15, y: 0.15, width: 0.7, height: 0.7)
        captureMetadataOutput.metadataObjectTypes = [.qr]

        let cameraLayer = AVCaptureVideoPreviewLayer(session: session)
        cameraLayer.videoGravity = .resizeAspectFill
        cameraLayer.frame = view.layer.bounds
        view.layer.insertSublayer(cameraLayer, below: animView.layer)
        view.layoutIfNeeded()
        self.session = session
        toggleScan(on: true)
    }

    private func deviceWithMediaType(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        
        if #available(iOS 10.0, *) {
            let avDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: position)
            return avDevice
        } else {
            // Fallback on earlier versions
            let avDevice = AVCaptureDevice.devices(for: AVMediaType.video)
            var avDeviceNum = 0
            for device in avDevice {
                print("deviceWithMediaType Position: \(device.position.rawValue)")
                if device.position == position {
                    break
                } else {
                    avDeviceNum += 1
                }
            }
            
            return avDevice[avDeviceNum]
        }
    }
    
    private func toggleScan(on: Bool) {
        if on {
            self.session?.startRunning()
        } else {
            self.session?.stopRunning()
        }
        UIView.animate(withDuration: 0.2) {
            if self.session == nil {
                self.animView.alpha = 0
            } else {
                self.animView.alpha = on ? 1 : 0
            }
        }
    }

    private func showEmptyView() {
        let emptyView = QREmptyView.init(type: .denied)
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyView)
        NSLayoutConstraint.activate([
            emptyView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            emptyView.topAnchor.constraint(equalTo: view.topAnchor),
            emptyView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }
}

// todo: replace with Rx Style
extension QRScannerViewController: AVCaptureMetadataOutputObjectsDelegate, UINavigationControllerDelegate {
    public func metadataOutput(_ output: AVCaptureMetadataOutput,
                               didOutput metadataObjects: [AVMetadataObject],
                               from connection: AVCaptureConnection) {
        guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject else { return }
        guard let str = object.stringValue else { return }
        session?.stopRunning()
        navigationController?.dismiss(animated: true, completion: nil)
        result.onNext(.success(str))
        result.onCompleted()
    }
}

fileprivate func videoAccess() -> Observable<AVAuthorizationStatus> {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    return Observable.create { (observer) -> Disposable in
        if case .notDetermined = status {
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { (success) in
                observer.onNext(success ? .authorized : .denied)
            })
        } else {
            observer.onNext(status)
        }
        return Disposables.create()
    }
}
