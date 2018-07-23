import UIKit
import RxSwift
import RxCocoa


enum QREmptyViewType {
    case denied
    case restricted
}

class QREmptyView: UIView {

    let type: QREmptyViewType
    let disposeBag = DisposeBag()

    init(type: QREmptyViewType) {
        self.type = type
        super.init(frame: CGRect.zero)

        backgroundColor = UIColor.white

        let imageView = UIImageView(image: .bundleImage(named: "lock.png"))
        imageView.alpha = 0.5
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 128),
            imageView.heightAnchor.constraint(equalToConstant: 128),
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        let label = UILabel()
        label.text = "Please allow the access of camera to enable QR Scan."
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textColor = UIColor.init(white: 0.5 , alpha: 0.7)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 24)
        ])

        let button = UIButton()
        button.setTitle("Settings", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.translatesAutoresizingMaskIntoConstraints = false
        addSubview(button)
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: centerXAnchor),
            button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 0)
        ])

        button.rx.tap
            .subscribe(onNext: {
                UIApplication.shared.openURL(URL(string:UIApplicationOpenSettingsURLString)!)
            })
            .disposed(by: disposeBag)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
