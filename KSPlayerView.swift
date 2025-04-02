import SwiftUI
#if os(iOS)
import KSPlayer
import UIKit

// Customize iOS ksplayer UI
class CustomVideoPlayerView: IOSVideoPlayerView {
    override func updateUI(isLandscape: Bool) {
        super.updateUI(isLandscape: isLandscape)
//        toolBar.playbackRateButton.isHidden = true
        self.backButton.isHidden = (!isLandscape)
        self.titleLabel.isHidden = (!isLandscape)
        //self.backButton.setImage(<#T##image: UIImage?##UIImage?#>, for: <#T##UIControl.State#>)
    }

    override func onButtonPressed(type: PlayerButtonType, button: UIButton) {
        if type == .landscape {
            // Your own button press behaviour here
            if(self.backButton.isHidden == false){
                updateUI(isLandscape: false)
                updateUI(isFullScreen: false)
                //self.centerRotate(byDegrees: -90)
            }else{
                updateUI(isFullScreen: true)
                updateUI(isLandscape: true)
                //self.centerRotate(byDegrees: 90)
            }
            self.landscapeButton.isHidden = false
            //rotateToLandscape()
        }else if type == .back{
            updateUI(isLandscape: false)
            updateUI(isFullScreen: false)
            self.backButton.isHidden = true
            self.titleLabel.isHidden = true
            //rotateToPortrait()
        }
        else {
            super.onButtonPressed(type: type, button: button)
        }
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if(toolBar.isLiveStream){
            toolBar.playbackRateButton.isHidden = true
            toolBar.timeLabel.isHidden = true
            toolBar.timeSlider.isHidden = true
            toolBar.srtButton.isHidden = true
        }
        
//        if UIApplication.shared.statusBarOrientation.isLandscape {
//            self.updateUI(isFullScreen: true)
//            self.updateUI(isLandscape: true)
//        }
    }
}

struct KSPlayerView: UIViewControllerRepresentable {
    let url: String
    let title: String
    let isLive: Bool  // 是否是直播
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = VideoPlayerViewController(url: url, title: title, isLive: isLive)
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}

    static func dismantleUIViewController(_ uiViewController: UIViewController, coordinator: ()) {
        if let playerVC = uiViewController as? VideoPlayerViewController {
            playerVC.cleanUp()
        }
    }
}

// UIViewController 版播放器
class VideoPlayerViewController: UIViewController {
    let url: String
    let titleText: String
    let isLive: Bool
    
#if os(iOS)
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }
    
    override var prefersStatusBarHidden: Bool {
        !playerView.isMaskShow
    }
    
    //private let playerView = IOSVideoPlayerView()
    private let playerView = CustomVideoPlayerView()
#elseif os(tvOS)
    private let playerView = VideoPlayerView()
#else
    private let playerView = CustomVideoPlayerView()
#endif
    
    init(url: String, title: String, isLive: Bool) {
        self.url = url
        self.titleText = title
        self.isLive = isLive
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad(){
        super.viewDidLoad()
        setupPlayer()
    }

    func setupPlayer(){
        KSOptions.secondPlayerType = KSMEPlayer.self
        
        //New testing feature
        KSOptions.canBackgroundPlay = true
        KSOptions.isAutoPlay = true
        
        playerView.backgroundColor = .black
        playerView.backButton.isHidden = true
        playerView.titleLabel.isHidden = true
        
        view.addSubview(playerView)
        
        playerView.translatesAutoresizingMaskIntoConstraints = false
#if os(iOS)
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: view.readableContentGuide.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
#else
        NSLayoutConstraint.activate([
            playerView.topAnchor.constraint(equalTo: view.topAnchor),
            playerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
#endif
        view.layoutIfNeeded()
        playerView.backBlock = { [unowned self] in
            #if os(iOS)
            if UIApplication.shared.statusBarOrientation.isLandscape {
                playerView.updateUI(isLandscape: false)
            }
            else{
                navigationController?.popViewController(animated: true)
            }
            #else
            navigationController?.popViewController(animated: true)
            #endif
        }
        
        
        playerView.becomeFirstResponder()
        
        
        guard let videoURL = URL(string: url) else { return }
        let header = ["User-Agent": "IPTV-Fluent"]
        let options = KSOptions()
        options.avOptions = ["AVURLAssetHTTPHeaderFieldsKey": header]
        let definition = KSPlayerResourceDefinition(url: videoURL, definition: "default", options: options)
        let asset = KSPlayerResource(name: titleText, definitions: [definition])

        playerView.set(resource: asset)
        //playerView.play()
    }

    func cleanUp() {
        playerView.pause()
        playerView.removeFromSuperview()
    }
}

#elseif os(macOS)
import KSPlayer
import AppKit

class KSPlayerMacViewController: NSViewController {
    var player: KSMEPlayer!
    
    init(url: String) {
        super.init(nibName: nil, bundle: nil)
        setupPlayer(with: url)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupPlayer(with url: String) {
        guard let videoURL = URL(string: url) else { return }
        
        let header = ["User-Agent": "IPTV-Fluent"]
        let options = KSOptions()
        options.avOptions = ["AVURLAssetHTTPHeaderFieldsKey": header]
        
        player = KSMEPlayer(url: videoURL, options:options)
        
        guard let playerView = player.view else {
            print("❌ player.view is nil")
            return
        }
        
        playerView.frame = view.bounds
        playerView.autoresizingMask = [.width, .height]
        view.addSubview(playerView)
        
        player.prepareToPlay()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        setupControls()
        player?.play()
    }
    
    private func setupControls() {
        let playPauseButton = NSButton(title: "Play/Pause", target: self, action: #selector(togglePlayPause))
        playPauseButton.frame = CGRect(x: 20, y: 20, width: 100, height: 30)
        view.addSubview(playPauseButton)
    }
    
    @objc private func togglePlayPause() {
        if player.isPlaying {
            player.pause()
        } else {
            player.play()
        }
    }
}

struct KSPlayerView: NSViewControllerRepresentable {
    let url: String
    let title: String
    let isLive: Bool
    func makeNSViewController(context: Context) -> NSViewController {
        return KSPlayerMacViewController(url: url)
    }
    
    func updateNSViewController(_ nsViewController: NSViewController, context: Context) {}
    
    static func dismantleNSViewController(_ nsViewController: NSViewController, coordinator: ()) {
        if let playerVC = nsViewController as? KSPlayerMacViewController {
            playerVC.player?.pause()
        }
    }
}
#endif
