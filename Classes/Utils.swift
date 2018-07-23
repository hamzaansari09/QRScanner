import UIKit
import RxSwift

extension UIImage {
    class func bundleImage(named: String) -> UIImage? {
        let frameworkBundle = Bundle.init(for: QRScanner.self)
        guard
            let url = frameworkBundle.resourceURL?.appendingPathComponent("RxQRScanner.bundle"),
            let bundle = Bundle.init(url: url)
        else { return nil }
        return UIImage(named: named, in: bundle, compatibleWith: nil)
    }
}

class NavigationController: UINavigationController {
    init(rootViewController: UIViewController, config: QRScanConfig) {
        super.init(rootViewController: rootViewController)
        if let navTintColor = config.navTintColor {
            navigationBar.tintColor = navTintColor
        }
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .portrait }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { return .portrait }
}

protocol CallbackObservable {
    associatedtype Result
    var result: PublishSubject<Result> { get }
}

extension CallbackObservable where Self: UIViewController {
    func popup(on: UIViewController, animated: Bool = true) -> Observable<Result> {
        on.present(self, animated: animated, completion: nil)
        return self.result
    }
}
