//
//  MusicPlayerViewController.swift
//  IRMusicPlayer-swift
//
//  Created by Phil on 2021/2/18.
//  Copyright © 2021 Phil. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import MediaPlayer

open class MusicPlayerViewController: UIViewController {
    @IBOutlet weak var mainView: UIView!
    @IBOutlet weak var musicNameLbl: UILabel!
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var startTimeLbl: UILabel!
    @IBOutlet weak var endTimeLbl: UILabel!
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var randomBtn: UIButton!
    @IBOutlet weak var circleBtn: UIButton!
    @IBOutlet weak var coverView: UIImageView!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var playBarView: UIView!
    
    open override var canBecomeFirstResponder: Bool {
        get {
            return true
        }
    }
    
    open var musicListArray: NSMutableArray!
    open var musicIndex: NSInteger! = 0
    
    open weak var delegate: MusicPlayerViewCallBackDelegate?
    
    
    
    var musicLength: CGFloat = 0.0
    var downloadSeconds: CGFloat = 0.0
    var audioNowTime: CGFloat = 0.0
    var tagIfControl: Bool = false, tagIfStop: Bool = false
    var controlMediaInfo: NSMutableDictionary = [:]
    
    var dwnProgressTimer, goProgressTimer: Timer?
    var randomCount: NSInteger = 0
    
    var player: AVQueuePlayer?
    
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.musicListArray = NSMutableArray.init()
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        //        self.titleLbl.textColor =
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Turn on remote control event delivery
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        // Set itself as the first responder
        self.becomeFirstResponder()
        
        //button Status
        self.randomBtn.isSelected = UserDefaults.standard.bool(forKey: PLAYER_RANDOM_BUTTON_STATUS_KEY)
        self.randomBtn.alpha = self.randomBtn.isSelected ? 1.0 : 0.3
        if UserDefaults.standard.integer(forKey: PLAYER_CIRCLE_BUTTON_STATUS_KEY) == 0 {
            self.circleBtn.tag = 0;
            self.circleBtn.setImage(UIImage.imageNamedForCurrentBundle(named: "btn_repeat_all"), for: .normal)
            self.circleBtn.alpha = 0.3
        } else if UserDefaults.standard.integer(forKey: PLAYER_CIRCLE_BUTTON_STATUS_KEY) == 1 {
            self.circleBtn.tag = 1;
            self.circleBtn.setImage(UIImage.imageNamedForCurrentBundle(named: "btn_repeat_all"), for: .normal)
        } else if UserDefaults.standard.integer(forKey: PLAYER_CIRCLE_BUTTON_STATUS_KEY) == 2 {
            self.circleBtn.tag = 2;
            self.circleBtn.setImage(UIImage.imageNamedForCurrentBundle(named: "btn_repeat_1"), for: .normal)
        }
        
        self.coverView.image = UIImage.imageNamedForCurrentBundle(named: "img_cover")
        let musicAddress: String = (self.musicListArray.object(at: self.musicIndex) as! NSDictionary).value(forKey: "musicAddress") as! String
        self.performSelector(inBackground: #selector(getMusicCover(urlString:)), with: musicAddress)
        
        var firstItem: AVPlayerItem
        if musicAddress.contains("http://") {
            firstItem = AVPlayerItem.init(url: URL.init(string: musicAddress)!)
        } else {
            firstItem = AVPlayerItem.init(url: URL.init(fileURLWithPath: musicAddress))
        }
        
        self.player = AVQueuePlayer.init(items: [firstItem])
        self.player?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.initial, context: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(itemDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: firstItem)
        if let resultText = try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback) {
            print(resultText)
        } else {
            print("error")
        }
        
        self.slider.isEnabled = false;
        self.slider.addTarget(self, action: #selector(sliderValueChangedAction(_:)), for: .touchUpInside)
        self.slider.maximumTrackTintColor = UIColor.clear
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // Turn off remote control event delivery
        UIApplication.shared.endReceivingRemoteControlEvents()
        
        // Resign as first responder
        self.resignFirstResponder()
        
        self.tagIfStop = true
        StatusClass.shared.isAudioPlaying = false
        self.musicNameLbl.text = ""
        self.player?.pause()
        self.playBtn.setImage(UIImage.imageNamedForCurrentBundle(named: "btn_play"), for: .normal)
        self.setControlMedia(title: self.musicNameLbl.text as NSString?, artist: "", length: Int(musicLength), rate: 0, seekTime: Int(audioNowTime))
        self.setClean()
        self.musicListArray.removeAllObjects()
        dwnProgressTimer?.invalidate()
        dwnProgressTimer = nil
        goProgressTimer?.invalidate()
        goProgressTimer = nil
        
        self.player?.removeObserver(self, forKeyPath: "status", context: nil)
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        NSLog("Ready to Play.")
        
        if object as? NSObject == self.player && keyPath == "status" {
            if self.player?.status == AVPlayer.Status.readyToPlay {
                goProgressTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(goProgress(theTimer:)), userInfo: nil, repeats: true)
                
                self.player?.play()
                self.playBtn.setImage(UIImage.imageNamedForCurrentBundle(named: "btn_pause"), for: .normal)
                
                tagIfControl = true
                NSLog("Play")
                StatusClass.shared.isAudioPlaying = true
            } else if self.player?.status == AVPlayer.Status.failed {
                NSLog("Play failure")
                StatusClass.shared.isAudioPlaying = false
            }
        }
    }

    @objc func updateProgress(theTimer: Timer) {
        if self.progressBar.progress == 1 { //stop
            dwnProgressTimer?.invalidate()
            dwnProgressTimer = nil
        } else {
            let loadedTimeRanges: [NSValue]? = self.player?.currentItem?.loadedTimeRanges
            let timeRange = loadedTimeRanges?[0].timeRangeValue
            let startSeconds = CMTimeGetSeconds(timeRange?.start ?? CMTime.init())
            let durationSeconds = CMTimeGetSeconds(timeRange?.duration ?? CMTime.init())
            let result = startSeconds + durationSeconds
            downloadSeconds  = CGFloat(result)
            
            if downloadSeconds > 0 {
                self.progressBar.progress = Float(downloadSeconds / musicLength)
            }
            if tagIfStop == false {
                if self.player?.rate == 0.0 && downloadSeconds > audioNowTime + 5 {
                    self.player?.play()
                    self.playBtn.setImage(UIImage.imageNamedForCurrentBundle(named: "btn_pause"), for: .normal)
                    self.setControlMedia(title: self.musicNameLbl.text as NSString?, artist: "", length: Int(musicLength), rate: 1, seekTime: Int(audioNowTime))
                }
            }
        }
    }
    
    @objc func goProgress(theTimer: Timer) {
        if self.player?.currentItem?.status == AVPlayerItem.Status.readyToPlay {
            StatusClass.shared.isAudioPlaying = true
            
            if self.player?.rate == 1.0 {
                let currentItem = self.player?.currentItem
                let currentTime = currentItem?.currentTime()
                //playing time
                audioNowTime = CGFloat(CMTimeGetSeconds(currentTime ?? CMTime.init()))
                if audioNowTime / 3600 >= 1 {
                    if (Int(audioNowTime) % 3600) % 60 < 10{
                        self.startTimeLbl.text = String.init(format: "%d:%d:0%d", Int(audioNowTime / 3600), (Int(audioNowTime) % 3600) / 60, (Int(audioNowTime) % 3600) % 60)
                    } else {
                        self.startTimeLbl.text = String.init(format: "%d:%d:%d", Int(audioNowTime / 3600), (Int(audioNowTime) % 3600) / 60, (Int(audioNowTime) % 3600) % 60)
                    }
                } else {
                    if (Int(audioNowTime) % 60) < 10{
                        self.startTimeLbl.text = String.init(format: "%d:0%d", Int(audioNowTime / 60), (Int(audioNowTime) % 60))
                    } else {
                        self.startTimeLbl.text = String.init(format: "%d:%d", Int(audioNowTime / 60), (Int(audioNowTime) % 60))
                    }
                }
                
                if (Int(audioNowTime) % 60 > 0) {
                    if self.tagIfControl == true {
                        dwnProgressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateProgress(theTimer:)), userInfo: nil, repeats: true)
                        self.getMusicLength()
                        self.setControlMedia(title: self.musicNameLbl.text as NSString?, artist: "", length: Int(musicLength), rate: 1, seekTime: 0)
                        self.tagIfControl = false
                    }
                    
                    //update slider
                    let diff = 1 / musicLength
                    var progress = self.slider.value
                    progress = progress + Float(diff)
                    self.slider.value = progress
                }
                
                self.playBtn.setImage(UIImage.imageNamedForCurrentBundle(named: "btn_pause"), for: .normal)
                
                if downloadSeconds < musicLength {
                    self.loadingView.isHidden = false
                } else {
                    self.loadingView.isHidden = true
                }
            } else {
                if tagIfStop == false {
                    if downloadSeconds > audioNowTime + 5 {
                        self.player?.play()
                        self.playBtn.setImage(UIImage.imageNamedForCurrentBundle(named: "btn_pause"), for: .normal)
                        self.setControlMedia(title: self.musicNameLbl.text as NSString?, artist: "", length: Int(musicLength), rate: 1, seekTime: Int(audioNowTime))
                    } else {
                        self.player?.pause()
                        self.playBtn.setImage(UIImage.imageNamedForCurrentBundle(named: "btn_play"), for: .normal)
                        self.setControlMedia(title: self.musicNameLbl.text as NSString?, artist: "", length: Int(musicLength), rate: 0, seekTime: Int(audioNowTime))
                    }
                } else {
                    self.player?.pause()
                    self.playBtn.setImage(UIImage.imageNamedForCurrentBundle(named: "btn_play"), for: .normal)
                    self.setControlMedia(title: self.musicNameLbl.text as NSString?, artist: "", length: Int(musicLength), rate: 0, seekTime: Int(audioNowTime))
                }
            }
        } else {
            NSLog("downloading...")
            
            self.loadingView.isHidden = false
            self.playBtn.setImage(UIImage.imageNamedForCurrentBundle(named: "btn_pause"), for: .normal)
            self.setControlMedia(title: self.musicNameLbl.text as NSString?, artist: "", length: Int(musicLength), rate: 0, seekTime: Int(audioNowTime))
        }
    }

    func getMusicLength() {
        let duration = self.player?.currentItem?.asset.duration
        musicLength = CGFloat(CMTimeGetSeconds(duration ?? CMTime.init()))
        self.slider.isEnabled = true
        
        NSLog("musicLength %f", musicLength)
        
        if musicLength / 3600 >= 1 {
            if (Int(musicLength) % 3600) % 60 < 10{
                self.endTimeLbl.text = String.init(format: "%d:%d:0%d", Int(musicLength / 3600), (Int(musicLength) % 3600) / 60, (Int(musicLength) % 3600) % 60)
            } else {
                self.endTimeLbl.text = String.init(format: "%d:%d:%d", Int(musicLength / 3600), (Int(musicLength) % 3600) / 60, (Int(musicLength) % 3600) % 60)
            }
        } else {
            if (Int(musicLength) % 60) < 10{
                self.endTimeLbl.text = String.init(format: "%d:0%d", Int(musicLength / 60), (Int(musicLength) % 60))
            } else {
                self.endTimeLbl.text = String.init(format: "%d:%d", Int(musicLength / 60), (Int(musicLength) % 60))
            }
        }
        
        let musicAddress = (self.musicListArray.object(at: self.musicIndex) as! NSDictionary).value(forKey: "musicAddress") as! String
        let array = musicAddress.components(separatedBy: "/")
        self.musicNameLbl.text = array.last
    }

    @objc func getMusicCover(urlString: String) {
        guard let url = URL.init(string: urlString) else { return }
        let asset = AVAsset.init(url: url)
        DispatchQueue.main.async {
            self.coverView.image = UIImage.imageNamedForCurrentBundle(named:"img_cover")
            for metadataItem: AVMetadataItem in asset.commonMetadata {
                if metadataItem.keySpace == AVMetadataKeySpace.id3 {
                    if (metadataItem.value?.isKind(of: NSDictionary.self)) != nil {
                        let imageDataDictionary = metadataItem.value as! NSDictionary
                        let imageData = imageDataDictionary.object(forKey: "data")
                        let image = UIImage.init(data: imageData as! Data)
                        // Display this image on my UIImageView property imageView
                        if ((image) != nil) {
                            self.coverView.image = image
                            break
                        }
                    } else if (metadataItem.value?.isKind(of: NSData.self)) != nil {
                        let image = UIImage.init(data: metadataItem.value as! Data)
                        if ((image) != nil) {
                            self.coverView.image = image
                            break
                        }
                    }
                } else if metadataItem.keySpace == AVMetadataKeySpace.iTunes {
                    if ((metadataItem.value?.copy(with: nil) as? AVMetadataItem)?.isKind(of: NSData.self)) != nil {
                        let image = UIImage.init(data: (metadataItem.value?.copy(with: nil)) as! Data)
                        if ((image) != nil) {
                            self.coverView.image = image;
                            break;
                        }
                    }
                }
            }
        }
    }
    
    @objc func itemDidFinishPlaying() {
        self.doNextWithIgnoreCircleStatus(ignoreCircleStatus: false)
    }
    
    func doNextWithIgnoreCircleStatus(ignoreCircleStatus: Bool) {
        self.setClean()
        
        if ignoreCircleStatus {
            
            if self.randomBtn.isSelected {
                self.musicIndex = NSInteger(self.random())
                self.doChangeMusic()
            } else {
                if (self.musicIndex < self.musicListArray.count - 1) {
                    self.musicIndex += 1
                } else {
                    self.musicIndex = 0
                }
                
                self.doChangeMusic()
            }
            
        } else if (self.circleBtn.tag == 0) {//play all musics once.
            
            if (self.randomBtn.isSelected) {
                self.musicIndex = NSInteger(self.random())
                randomCount += 1
                
                if randomCount == self.musicListArray.count {
                    self.close()
                } else {
                    self.doChangeMusic()
                }
            } else {
                
                if (self.musicIndex < self.musicListArray.count - 1) {
                    self.musicIndex += 1
                    self.doChangeMusic()
                } else {//done
                    self.close()
                }
                
            }
            
        } else if (self.circleBtn.tag == 1) {//circle
            
            if (self.randomBtn.isSelected) {
                self.musicIndex = NSInteger(self.random())
            } else {
                if (self.musicIndex < self.musicListArray.count - 1) {
                    self.musicIndex += 1
                } else {
                    self.musicIndex = 0
                }
            }
            
            self.doChangeMusic()
        } else if (self.circleBtn.tag == 2) {//repeat
            self.doChangeMusic()
        }
    }
    
    func setClean() {
        StatusClass.shared.isAudioPlaying = false
        self.progressBar.progress = 0;
        self.slider.value = 0;
        
        self.startTimeLbl.text = "00:00";
        self.endTimeLbl.text = "00:00";
        
        dwnProgressTimer?.invalidate()
        dwnProgressTimer = nil
        
        self.setControlMedia(title: "Loading...", artist: "", length: 0, rate: 0, seekTime: 0)
    }
    
    func setControlMedia(title: NSString?, artist: NSString?, length: Int, rate: Int, seekTime: Int) {
        let keys = Array<NSCopying>.init(arrayLiteral: MPMediaItemPropertyTitle as NSString, MPMediaItemPropertyArtist as NSString, MPMediaItemPropertyPlaybackDuration as NSString, MPNowPlayingInfoPropertyPlaybackRate as NSString)
        let values = Array.init(arrayLiteral:title, artist, NSNumber.init(value: length), NSNumber.init(value: rate))
        controlMediaInfo = NSMutableDictionary.init(objects: values, forKeys: keys)
        controlMediaInfo.setObject(NSNumber.init(value: seekTime), forKey: MPNowPlayingInfoPropertyElapsedPlaybackTime as NSString)
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = controlMediaInfo as? [String : Any]
    }
    
    func random() -> UInt32 {
        if self.musicListArray.count > 1 {
            var i = arc4random() % UInt32(self.musicListArray.count)
            if (i == self.musicIndex) {
                i = UInt32(self.random())
            }
            return i
        } else {
            return 0
        }
    }
    
    @IBAction func sliderValueChangedAction(_ sender: Any) {
        audioNowTime = musicLength * CGFloat((sender as! UISlider).value)
        
        if audioNowTime / 3600 >= 1 {
            if (Int(audioNowTime) % 3600) % 60 < 10{
                self.startTimeLbl.text = String.init(format: "%d:%d:0%d", Int(audioNowTime / 3600), (Int(audioNowTime) % 3600) / 60, (Int(audioNowTime) % 3600) % 60)
            } else {
                self.startTimeLbl.text = String.init(format: "%d:%d:%d", Int(audioNowTime / 3600), (Int(audioNowTime) % 3600) / 60, (Int(audioNowTime) % 3600) % 60)
            }
        } else {
            if (Int(audioNowTime) % 60) < 10{
                self.startTimeLbl.text = String.init(format: "%d:0%d", Int(audioNowTime / 60), (Int(audioNowTime) % 60))
            } else {
                self.startTimeLbl.text = String.init(format: "%d:%d", Int(audioNowTime / 60), (Int(audioNowTime) % 60))
            }
        }
        
        let cmTime: CMTime = CMTimeMake(value: Int64(audioNowTime), timescale: 1)
        self.player?.seek(to: cmTime)
        
        if downloadSeconds < audioNowTime {
            self.player?.pause()
            self.playBtn.setImage(UIImage.imageNamedForCurrentBundle(named: "btn_play"), for: .normal)
            self.setControlMedia(title: self.musicNameLbl.text as NSString?, artist: "", length: Int(musicLength), rate: 0, seekTime: Int(audioNowTime))
        } else {
            self.setControlMedia(title: self.musicNameLbl.text as NSString?, artist: "", length: Int(musicLength), rate: 1, seekTime: Int(audioNowTime))
        }
    }
    
    func doChangeMusic() {
        self.slider.isEnabled = false
        let nextItem: AVPlayerItem
        let musicAddress = (((self.musicListArray[self.musicIndex]) as! NSDictionary).value(forKey: "musicAddress") as!NSString)
        if musicAddress.range(of: "http://").length > 0 {
            nextItem = AVPlayerItem.init(url: URL.init(string: musicAddress as String)!)
        } else {
            nextItem = AVPlayerItem.init(url: URL.init(fileURLWithPath: musicAddress as String))
        }
        
        self.player?.insert(nextItem, after: nil)
        self.player?.advanceToNextItem()
        NotificationCenter.default.addObserver(self, selector: #selector(itemDidFinishPlaying), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nextItem)
        
        self.performSelector(inBackground: #selector(getMusicCover(urlString:)), with: musicAddress)
        
        self.tagIfControl = true
        self.delegate?.didMusicChange(path: musicAddress)
    }
    
    func close() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func doPlay() {
        if self.player?.rate == 1.0 {
            self.tagIfStop = true
            self.player?.pause()
            self.playBtn.setImage(UIImage.imageNamedForCurrentBundle(named: "btn_play"), for: .normal)
            self.setControlMedia(title: self.musicNameLbl.text as NSString?, artist: "", length: Int(musicLength), rate: 0, seekTime: Int(audioNowTime))
        } else {
            self.tagIfStop = false
            self.player?.play()
            self.playBtn.setImage(UIImage.imageNamedForCurrentBundle(named: "btn_pause"), for: .normal)
            self.setControlMedia(title: self.musicNameLbl.text as NSString?, artist: "", length: Int(musicLength), rate: 1, seekTime: Int(audioNowTime))
        }
    }
    
    func doPrev() {
        self.setClean()
        
        if self.randomBtn.isSelected {
            self.musicIndex = NSInteger(self.random())
            self.doChangeMusic()
        } else {
            if self.musicIndex > 0 {
                self.musicIndex -= 1
            } else {
                self.musicIndex = self.musicListArray.count - 1
            }
            
            self.doChangeMusic()
        }
    }
    
    @IBAction func close(_ sender: Any) {
        self.close()
    }
    
    @IBAction func doPlay(_ sender: Any) {
        self.doPlay()
    }
    
    @IBAction func doNext(_ sender: Any) {
        self.doNextWithIgnoreCircleStatus(ignoreCircleStatus: true)
    }
    
    @IBAction func doPrev(_ sender: Any) {
        self.doPrev()
    }
    
    @IBAction func doRandom(_ sender: Any) {
        randomCount = 0
        self.randomBtn.isSelected = !self.randomBtn.isSelected
        self.randomBtn.alpha = self.randomBtn.isSelected ? 1.0 : 0.3
        
        let userDefault = UserDefaults.standard
        userDefault.setValue(String.init(format: "%d", self.randomBtn.isSelected), forKey: PLAYER_RANDOM_BUTTON_STATUS_KEY)
        userDefault.synchronize()
    }
    
    @IBAction func doCircle(_ sender: Any) {
        if (self.circleBtn.tag == 0) {
            self.circleBtn.tag = 1;
            self.circleBtn.setImage(UIImage.imageNamedForCurrentBundle(named: "btn_repeat_all"), for: .normal)
            self.circleBtn.alpha = 1.0
        }else if (self.circleBtn.tag == 1) {
            self.circleBtn.tag = 2;
            self.circleBtn.setImage(UIImage.imageNamedForCurrentBundle(named: "btn_repeat_1"), for: .normal)
        }else if (self.circleBtn.tag == 2) {
            self.circleBtn.tag = 0;
            self.circleBtn.setImage(UIImage.imageNamedForCurrentBundle(named: "btn_repeat_all"), for: .normal)
            self.circleBtn.alpha = 0.3
        }
        
        let userDefault = UserDefaults.standard
        userDefault.setValue(String.init(format: "%ld", self.circleBtn.tag), forKey: PLAYER_CIRCLE_BUTTON_STATUS_KEY)
        userDefault.synchronize()
    }
    
    open override func remoteControlReceived(with event: UIEvent?) {
        if (event?.type == .remoteControl) {
            
            switch (event?.subtype) {
            case .remoteControlPlay:
                self.doPlay()
                break;
            case .remoteControlPause:
                self.doPlay()
                break;
            case .remoteControlPreviousTrack:
                self.doPlay()
                break;
            case .remoteControlNextTrack:
                self.doNextWithIgnoreCircleStatus(ignoreCircleStatus: true)
                break;
            default:
                break;
            }
        }
    }
}

public protocol MusicPlayerViewCallBackDelegate: NSObjectProtocol {
    func didMusicChange(path: NSString);
}
