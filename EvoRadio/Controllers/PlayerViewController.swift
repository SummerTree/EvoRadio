//
//  PlayerViewController.swift
//  EvoRadio
//
//  Created by Jarvis on 16/4/18.
//  Copyright © 2016年 JQTech. All rights reserved.
//

import UIKit
import Alamofire
import SnapKit
import AudioKit

class PlayerViewController: ViewController {
    
    let cellID = "playerControllerPlaylistCellID"
    let toolButtonWidth: CGFloat = 50
    
    fileprivate var coverImageView = CDCoverImageView(frame: CGRect.zero)
    var backgroundView: UIImageView!
    
    fileprivate var controlView = UIView()
    let progressSlider = UISlider()
    let currentTimeLabel = UILabel()
    let totalTimeLabel = UILabel()
    let playButton = UIButton()
    let nextButton = UIButton()
    let prevButton = UIButton()
    let loopButton = UIButton()
    let timerButton = UIButton()
    let titleLabel = UILabel()
    let subTitleLabel = UILabel()
    let playlistTableView = UITableView(frame: CGRect.zero, style: .grouped)
    let playlistContentView = UIView()
    var playlistTableViewBottomConstraint: Constraint?
    
    var progressTimer: Timer?
    var autoStopTimer: Timer?
    var leftTime: TimeInterval = 3600
    
    var coverRotateAnimation: CABasicAnimation?;
    
    //MARK: instance
    open static let mainController = PlayerViewController()
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
    
    //MARK: life cycle functions
    override func viewDidLoad() {
        super.viewDidLoad()
        debugPrint("player viewDidLoad")
        
        MusicManager.shared.audioPlayer.delegate = self
        progressTimer = Timer(timeInterval: 1, target: self, selector: #selector(progressHandle), userInfo: nil, repeats: true)
        RunLoop.current.add(progressTimer!, forMode: RunLoopMode.commonModes)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        PlayerView.main.hide()
        
        if MusicManager.shared.isPlaying() {
            coverImageView.layer.removeAllAnimations()
            coverRotateAnimation = nil
            prepareAnimation()
        } else if MusicManager.shared.isPaused() {
            coverRotateAnimation = nil
        }
        
        AssistiveTouch.shared.hide()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        PlayerView.main.show()
        
        AssistiveTouch.shared.show()
    }

    //MARK: prepare ui
    func prepare() {
        
        prepareBackgroundView()
        preparePlayerControlView()
        prepareToolsView()
        prepareNavigationBar()
        prepareTableView()

        NotificationManager.shared.addUpdatePlayerObserver(self, action: #selector(PlayerViewController.updatePlayer(_:)))
        
    }
    
    func prepareBackgroundView() {
        view.addSubview(coverImageView)
        coverImageView.image = UIImage.placeholder_cover()
        coverImageView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 240, height: 240))
            make.centerX.equalTo(view.snp.centerX)
            let topMargin = (Device.height()-200-64)*0.5-100+64
            make.topMargin.equalTo(topMargin)
        }
        
        backgroundView = UIImageView()
        view.insertSubview(backgroundView, belowSubview: coverImageView)
        backgroundView.snp.makeConstraints { (make) in
            make.edges.equalTo(UIEdgeInsets.zero)
        }
        
        // add blur effect
        let blur = UIBlurEffect(style: .light)
        let effectView = UIVisualEffectView(effect: blur)
        backgroundView.addSubview(effectView)
        effectView.snp.makeConstraints { (make) in
            make.edges.equalTo(UIEdgeInsets.zero)
        }
    }
    
    func prepareCoverView() {
        
        let coverWidth: CGFloat = 200
        let coverView = UIImageView()
        view.addSubview(coverView)
        coverView.clipsToBounds = true
        coverView.layer.cornerRadius = coverWidth*0.5
        
        coverView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: coverWidth, height: coverWidth))
            make.center.equalTo(view.snp.center)
        }
    }
    
    func prepareNavigationBar() {
        let navBarHeight: CGFloat = 64
        
        let navBar = UIView()
        view.addSubview(navBar)
        navBar.snp.makeConstraints { (make) in
            make.height.equalTo(navBarHeight)
            make.top.equalTo(view.snp.top)
            make.left.equalTo(view.snp.left)
            make.right.equalTo(view.snp.right)
        }
        
        navBar.addSubview(subTitleLabel)
        subTitleLabel.textAlignment = .center
        subTitleLabel.font = UIFont.size12()
        subTitleLabel.textColor = UIColor.grayColorBF()
        subTitleLabel.snp.makeConstraints { (make) in
            make.height.equalTo(20)
            make.leftMargin.equalTo(60)
            make.rightMargin.equalTo(-60)
            make.bottom.equalTo(navBar.snp.bottom)
        }
        
        navBar.addSubview(titleLabel)
        titleLabel.textAlignment = .center
        titleLabel.font = UIFont.size14()
        titleLabel.textColor = UIColor.white
        titleLabel.snp.makeConstraints { (make) in
            make.height.equalTo(20)
            make.leftMargin.equalTo(60)
            make.rightMargin.equalTo(-60)
            make.bottom.equalTo(subTitleLabel.snp.top)
        }
        
        let closeButton = UIButton()
        navBar.addSubview(closeButton)
        closeButton.setImage(UIImage(named: "nav_dismiss"), for: UIControlState())
        closeButton.addTarget(self, action: #selector(PlayerViewController.closeButtonPressed), for: .touchUpInside)
        closeButton.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 40, height: 40))
            make.leftMargin.equalTo(10)
            make.topMargin.equalTo(20)
        }
  
    }

    func prepareToolsView() {
        let itemWidth: CGFloat = min(Device.width() / 5, 60)
        
        let toolsView = UIView()
        view.addSubview(toolsView)
//        toolsView.backgroundColor = UIColor(white: 0.5, alpha: 0.8)
        toolsView.snp.makeConstraints { (make) in
            make.height.equalTo(itemWidth)
            make.left.equalTo(view.snp.left)
            make.right.equalTo(view.snp.right)
            make.bottom.equalTo(view.snp.bottom)
        }
        
//        let infoButton = UIButton()
//        toolsView.addSubview(infoButton)
//        infoButton.setImage(UIImage(named: "player_info"), forState: .Normal)
//        infoButton.addTarget(self, action: #selector(PlayerViewController.infoButtonPressed(_:)), forControlEvents: .TouchUpInside)
//        infoButton.snp.makeConstraints { (make) in
//            make.size.equalTo(CGSizeMake(itemWidth, itemWidth))
//            make.center.equalTo(toolsView.center)
//        }
        
        toolsView.addSubview(timerButton)
        timerButton.setImage(UIImage(named: "player_timer"), for: UIControlState())
        timerButton.setImage(UIImage(named: "player_timer_selected"), for: .selected)
        timerButton.addTarget(self, action: #selector(PlayerViewController.timerButtonPressed(_:)), for: .touchUpInside)
        timerButton.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: itemWidth, height: itemWidth))
            make.center.equalTo(toolsView.snp.center)
        }
        
        let downloadButton = UIButton()
        toolsView.addSubview(downloadButton)
        downloadButton.setImage(UIImage(named: "player_download"), for: UIControlState())
        downloadButton.setImage(UIImage(named: "player_download_selected"), for: .selected)
        downloadButton.addTarget(self, action: #selector(PlayerViewController.downloadButtonPressed(_:)), for: .touchUpInside)
        downloadButton.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: itemWidth, height: itemWidth))
            make.centerY.equalTo(toolsView.snp.centerY)
            make.right.equalTo(timerButton.snp.left)
        }
        
        let shareButton = UIButton()
        toolsView.addSubview(shareButton)
        shareButton.setImage(UIImage(named: "player_share"), for: UIControlState())
        shareButton.addTarget(self, action: #selector(PlayerViewController.shareButtonPressed(_:)), for: .touchUpInside)
        shareButton.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: itemWidth, height: itemWidth))
            make.centerY.equalTo(toolsView.snp.centerY)
            make.left.equalTo(timerButton.snp.right)
        }
        
        toolsView.addSubview(loopButton)
        loopButton.setImage(UIImage(named: "player_cycle_list"), for: UIControlState())
        loopButton.addTarget(self, action: #selector(PlayerViewController.loopButtonPressed(_:)), for: .touchUpInside)
        loopButton.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: itemWidth, height: itemWidth))
            make.centerY.equalTo(toolsView.snp.centerY)
            make.right.equalTo(downloadButton.snp.left)
        }
        
        let listButton = UIButton()
        toolsView.addSubview(listButton)
        listButton.setImage(UIImage(named: "player_list"), for: UIControlState())
        listButton.addTarget(self, action: #selector(PlayerViewController.listButtonPressed(_:)), for: .touchUpInside)
        listButton.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: itemWidth, height: itemWidth))
            make.centerY.equalTo(toolsView.snp.centerY)
            make.left.equalTo(shareButton.snp.right)
        }

        loadDefaultData()
        
    }
    
    func preparePlayerControlView() {
        view.addSubview(controlView)
        controlView.snp.makeConstraints { (make) in
            make.height.equalTo(180)
            make.bottom.equalTo(view.snp.bottom)
            make.left.equalTo(view.snp.left)
            make.right.equalTo(view.snp.right)
        }
        
        controlView.addSubview(playButton)
        playButton.setImage(UIImage(named: "player_play"), for: UIControlState())
        playButton.setImage(UIImage(named: "player_play_pressed"), for: .highlighted)
        playButton.addTarget(self, action: #selector(PlayerViewController.playButtonPressed(_:)), for: .touchUpInside)
        playButton.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 60, height: 60))
            make.center.equalTo(controlView.snp.center)
        }
        
        controlView.addSubview(nextButton)
        nextButton.setImage(UIImage(named: "player_next"), for: UIControlState())
        nextButton.addTarget(self, action: #selector(PlayerViewController.nextButtonPressed(_:)), for: .touchUpInside)
        nextButton.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: toolButtonWidth, height: toolButtonWidth))
            make.centerY.equalTo(controlView.snp.centerY)
            make.left.equalTo(playButton.snp.right).inset(-20)
        }
        
        
        controlView.addSubview(prevButton)
        prevButton.setImage(UIImage(named: "player_prev"), for: UIControlState())
        prevButton.addTarget(self, action: #selector(PlayerViewController.prevButtonPressed(_:)), for: .touchUpInside)
        prevButton.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: toolButtonWidth, height: toolButtonWidth))
            make.centerY.equalTo(controlView.snp.centerY)
            make.right.equalTo(playButton.snp.left).inset(-20)
        }
        
        controlView.addSubview(progressSlider)
        progressSlider.setThumbImage(UIImage(named: "dot_white")!, for: UIControlState())
        progressSlider.tintColor = UIColor.goldColor()
        progressSlider.addTarget(self, action: #selector(PlayerViewController.progressSliderChanged(_:)), for: .valueChanged)
        progressSlider.snp.makeConstraints { (make) in
            make.height.equalTo(20)
            make.left.equalTo(controlView.snp.left).inset(50)
            make.right.equalTo(controlView.snp.right).inset(50)
            make.top.equalTo(controlView.snp.top).offset(10)
        }
        
        controlView.addSubview(currentTimeLabel)
        currentTimeLabel.textAlignment = .center
        currentTimeLabel.font = UIFont.size10()
        currentTimeLabel.textColor = UIColor.white
        currentTimeLabel.text = "0:00"
        currentTimeLabel.snp.makeConstraints { (make) in
            make.left.equalTo(view.snp.left)
            make.right.equalTo(progressSlider.snp.left)
            make.centerY.equalTo(progressSlider.snp.centerY)
        }
        
        controlView.addSubview(totalTimeLabel)
        totalTimeLabel.textAlignment = .center
        totalTimeLabel.font = UIFont.size10()
        totalTimeLabel.textColor = UIColor.white
        totalTimeLabel.text = "0:00"
        totalTimeLabel.snp.makeConstraints { (make) in
            make.right.equalTo(view.snp.right)
            make.left.equalTo(progressSlider.snp.right)
            make.centerY.equalTo(progressSlider.snp.centerY)
        }
        
    }
    
    func prepareTableView() {

        view.addSubview(playlistContentView)
        playlistContentView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        playlistContentView.snp.makeConstraints { (make) in
            make.edges.equalTo(UIEdgeInsets.zero)
        }
        
        let emptyButton = UIButton()
        playlistContentView.addSubview(emptyButton)
        emptyButton.addTarget(self, action: #selector(PlayerViewController.emptyButtonPressed(_:)), for: .touchUpInside)
        emptyButton.snp.makeConstraints { (make) in
            make.edges.equalTo(UIEdgeInsets.zero)
        }
        
        playlistContentView.addSubview(playlistTableView)
        playlistTableView.delegate = self
        playlistTableView.dataSource = self
        playlistTableView.backgroundColor = UIColor(white: 0, alpha: 0.8)
        playlistTableView.separatorStyle = .none
        playlistTableView.snp.makeConstraints({(make) in
            make.height.equalTo(Device.height()*0.6)
            make.left.equalTo(playlistContentView.snp.left)
            make.right.equalTo(playlistContentView.snp.right)
            playlistTableViewBottomConstraint = make.top.equalTo(playlistContentView.snp.bottom).offset(0).constraint
        })
        
        playlistTableView.register(SongListTableViewCell.self, forCellReuseIdentifier: cellID)
        
        playlistContentView.isHidden = true
    }
    
    func prepareAnimation() {
        if coverRotateAnimation == nil {
            coverRotateAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
            coverRotateAnimation!.duration = 30
            coverRotateAnimation!.fromValue = NSNumber(value: 0 as Double)
            coverRotateAnimation!.toValue = NSNumber(value: M_PI * 2 as Double)
            coverRotateAnimation!.repeatCount = MAXFLOAT
            coverRotateAnimation!.autoreverses = false
            coverRotateAnimation!.isCumulative = true
            coverImageView.layer.speed = 1
            coverImageView.layer.add(coverRotateAnimation!, forKey: "coverRotateAnimation")
        }
    }
    
    //MARK: events
    func playButtonPressed(_ button: UIButton) {
        
        if MusicManager.shared.isStoped() {
            return
        }
        
        if MusicManager.shared.isPaused() {
            MusicManager.shared.resume()
            
            let stopTime = coverImageView.layer.timeOffset
            coverImageView.layer.beginTime = 0
            coverImageView.layer.timeOffset = 0
            coverImageView.layer.speed = 1
            let tempTime = coverImageView.layer.convertTime(CACurrentMediaTime(), from: nil) - stopTime
            coverImageView.layer.beginTime = tempTime
            
            
        } else if MusicManager.shared.isPlaying() {
            MusicManager.shared.pause()
            NotificationManager.shared.postPlayMusicProgressPausedNotification()
            
            let stopTime = coverImageView.layer.convertTime(CACurrentMediaTime(), from: nil)
            coverImageView.layer.speed = 0
            coverImageView.layer.timeOffset = stopTime
        }else {
            debugPrint("鬼知道发生了什么！")
        }
        
    }
    func nextButtonPressed(_ button: UIButton) {
        MusicManager.shared.playNext()
        
        coverImageView.layer.removeAllAnimations()
        coverRotateAnimation = nil
    }
    
    func prevButtonPressed(_ button: UIButton) {
        MusicManager.shared.playPrev()
        
        coverImageView.layer.removeAllAnimations()
        coverRotateAnimation = nil
    }
    
    func loopButtonPressed(_ button: UIButton) {
        var imageAssetName: String
        var showText: String
        let newMode = MusicManager.shared.changePlayMode()
        switch newMode {
        case .ListLoop:
            imageAssetName = "player_cycle_list"
            showText = "列表循环"
        case .SingleLoop:
            imageAssetName = "player_cycle_single"
            showText = "单曲循环"
        case .Random:
            imageAssetName = "player_cycle_random"
            showText = "随机播放"
        }
        
        loopButton.setImage(UIImage(named: imageAssetName), for: UIControlState())
        HudManager.showText(showText, inView: view)
    }
    
    func listButtonPressed(_ button: UIButton) {
        showPlaylistTableView(true)
    }
    
    func heartButtonPressed(_ button: UIButton) {
        button.isSelected = !button.isSelected
    }
    
    func downloadButtonPressed(_ button: UIButton) {
        if let cSong = MusicManager.shared.currentSong() {
//            CoreDB.addSongToDownloadingList(cSong)
//            button.selected = true
            HudManager.showText("已经加入下载列表")
        }
    }
    
    func shareButtonPressed(_ button: UIButton) {
        if let currentSong = MusicManager.shared.currentSong() {
            
            let link = URL(string: currentSong.audioURL!)
            let message = String(format: "EvoRadio请您欣赏：%@", currentSong.songName)
            
            let shareItems: [Any] = [message, link as Any]
            let activityController = UIActivityViewController(activityItems: shareItems, applicationActivities: nil)
            
            self.present(activityController, animated: true, completion: nil)
        }
    }
    
    func infoButtonPressed(_ button: UIButton) {
        debugPrint("infoButtonPressed")
    }
    
    func closeButtonPressed() {
        self.dismiss(animated: true, completion: nil)
    }
    
    func timerButtonPressed(_ button: UIButton) {
        if button.isSelected {
            button.isSelected = false
            if let _ = autoStopTimer {
                autoStopTimer?.invalidate()
                autoStopTimer = nil
            }
            
        }else {
            let alertController = UIAlertController(title: "设置自动停止播放时间", message: nil, preferredStyle: .actionSheet)
            let action1 = UIAlertAction(title: "10 minutes", style: .default, handler: { (action) in
                button.isSelected = true
                self.leftTime = 600
                if self.autoStopTimer == nil {
                    self.autoStopTimer = Timer(timeInterval: 5, target: self, selector: #selector(PlayerViewController.autoStopHandle), userInfo: nil, repeats: true)
                    RunLoop.main.add(self.autoStopTimer!, forMode: RunLoopMode.commonModes)
                }
                
            })
            let action2 = UIAlertAction(title: "15 minutes", style: .default, handler: { (action) in
                button.isSelected = true
                self.leftTime = 900
            })
            let action3 = UIAlertAction(title: "30 minutes", style: .default, handler: { (action) in
                button.isSelected = true
                self.leftTime = 1800
            })
            let action4 = UIAlertAction(title: "1 hour", style: .default, handler: { (action) in
                button.isSelected = true
                self.leftTime = 3600
            })
            let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
            
            alertController.addAction(action1)
            alertController.addAction(action2)
            alertController.addAction(action3)
            alertController.addAction(action4)
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true, completion: nil)
        }
        
    }
    
    func progressSliderChanged(_ slider: UISlider) {
        let timePlayed = slider.value
        MusicManager.shared.playAtSecond(Int(timePlayed))
    }
    
    func updatePlayer(_ noti: Notification) {
        if let song = MusicManager.shared.currentSong() {
            updateCoverImage(song)
        }
    }
    
    func autoStopHandle() {
        debugPrint("Timer: \(leftTime)")
        leftTime -= 5
        if leftTime <= 0 {
            debugPrint("Time out, will stop music")
            
            autoStopTimer?.invalidate()
            autoStopTimer = nil
            
            MusicManager.shared.pause()
            timerButton.isSelected = false
        }
    }
    
    func progressHandle() {
        let duration:Float = Float(MusicManager.shared.audioPlayer.duration)
        let timePlayed: Float = Float(MusicManager.shared.audioPlayer.progress)
        
        progressSlider.maximumValue = duration
        progressSlider.value = timePlayed
        
        totalTimeLabel.text = Date.secondsToMinuteString(Int(duration))
        currentTimeLabel.text = Date.secondsToMinuteString(Int(timePlayed))
        
        MusicManager.shared.updatePlaybackTime(Double(timePlayed))
    }
    
    
    //MARK: other
    
    func updateCoverImage(_ song: Song) {
        debugPrint("update cover image")
        titleLabel.text = song.songName
        if let album = song.salbumsName {
            subTitleLabel.text = song.artistsName?.appending(" - ").appending(album)
        }
        
        if let picURLString = song.picURL {
            if let picURL = URL(string: picURLString) {
                coverImageView.kf.setImage(with: picURL, placeholder: UIImage.placeholder_cover(), completionHandler: {[weak self] (image, error, cacheType, imageURL) in
                    if let _ = image{
                        UIView.animate(withDuration: 0.5, animations: {
                            self?.backgroundView.alpha = 0.2
                        }, completion: { (complete) in
                            self?.backgroundView.image = image!
                            UIView.animate(withDuration: 1, animations: {
                                self?.backgroundView.alpha = 1
                            })
                        })
                    }
                })
            }
        }
    }
    
    func showPlaylistTableView(_ show: Bool) {
        let offset: CGFloat = show ? -Device.height()*0.6 : 0
        playlistTableViewBottomConstraint?.update(offset: offset)
        
        playlistTableView.setNeedsLayout()
        
        if show {
            playlistContentView.isHidden = false
            playlistTableView.reloadData()
            UIView.animate(withDuration: 0.25, animations: {[weak self] Void in
                self?.playlistTableView.layoutIfNeeded()
                })
        }else {
            UIView.animate(withDuration: 0.25, animations: {[weak self] Void in
                self?.playlistTableView.layoutIfNeeded()
                }, completion: {Void in
                    self.playlistContentView.isHidden = true
            })
        }
    }
    
    func loadDefaultData() {
        var imageAssetName: String
        let currentMode = MusicManager.shared.currentPlayMode()
        switch currentMode {
        case .ListLoop:
            imageAssetName = "player_cycle_list"
        case .SingleLoop:
            imageAssetName = "player_cycle_single"
        case .Random:
            imageAssetName = "player_cycle_random"
        }
        loopButton.setImage(UIImage(named: imageAssetName), for: UIControlState())
        
        
    }

}

extension PlayerViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  MusicManager.shared.playlist.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID) as! SongListTableViewCell
        cell.delegate = self
        
        let song =  MusicManager.shared.playlist[(indexPath as NSIndexPath).row]
        cell.updateSongInfo(song)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0,y: 0,width: tableView.bounds.width,height: 40))
        
        let downloadButton = UIButton()
        headerView.addSubview(downloadButton)
        downloadButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        downloadButton.backgroundColor = UIColor.grayColor1C()
        downloadButton.clipsToBounds = true
        downloadButton.layer.cornerRadius = 15
        downloadButton.setTitle("Download All", for: UIControlState())
        downloadButton.addTarget(self, action: #selector(PlayerViewController.downloadAllButtonPressed(_:)), for: .touchUpInside)
        downloadButton.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 100, height: 30))
            make.centerY.equalTo(headerView.snp.centerY)
            make.leftMargin.equalTo(10)
        }
        
        let clearButton = UIButton()
        headerView.addSubview(clearButton)
        clearButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        clearButton.backgroundColor = UIColor.grayColor1C()
        clearButton.clipsToBounds = true
        clearButton.layer.cornerRadius = 15
        clearButton.setTitle("Clear All", for: UIControlState())
        clearButton.addTarget(self, action: #selector(PlayerViewController.clearAllButtonPressed(_:)), for: .touchUpInside)
        clearButton.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 100, height: 30))
            make.centerY.equalTo(headerView.snp.centerY)
            make.rightMargin.equalTo(-10)
        }
        
        let separatorView = UIView()
        headerView.addSubview(separatorView)
        separatorView.backgroundColor = UIColor.grayColor97()
        separatorView.snp.makeConstraints { (make) in
            make.height.equalTo(1.0/Device.screenScale())
            make.left.equalTo(headerView.snp.left)
            make.right.equalTo(headerView.snp.right)
            make.bottom.equalTo(headerView.snp.bottom)
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 42
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        MusicManager.shared.currentIndex = (indexPath as NSIndexPath).row
        MusicManager.shared.play()
        
        showPlaylistTableView(false)
    }
    
    func downloadAllButtonPressed(_ button: UIButton) {
        if MusicManager.shared.playlist.count > 0 {
//            CoreDB.addSongsToDownloadingList(MusicManager.shared.playlist)
            showPlaylistTableView(false)
        }
    }
    func clearAllButtonPressed(_ button: UIButton) {
        if MusicManager.shared.playlist.count > 0 {
            MusicManager.shared.clearList()
            playlistTableView.reloadData()
            showPlaylistTableView(false)
        }
    }
    
    func emptyButtonPressed(_ button: UIButton) {
        showPlaylistTableView(false)
    }
    
}

extension PlayerViewController: SongListTableViewCellDelegate {
    func openToolPanelOfSong(_ song: Song) {

        let row = MusicManager.shared.indexOfPlaylist(song: song)
        
        let alertController = UIAlertController()

        let action1 = UIAlertAction(title: "收藏歌曲", style: .default, handler: { (action) in
            debugPrint("add to collecte")
        })
        let action2 = UIAlertAction(title: "下载歌曲", style: .default, handler: { (action) in
            CoreDB.addSongToDownloadingList(song)
            HudManager.showText("已经加入下载列表")
        })
        let action3 = UIAlertAction(title: "从列表中移除", style: .default, handler: { (action) in
            MusicManager.shared.removeSongFromPlaylist(song)
            self.playlistTableView.deleteRows(at: [IndexPath(row: row!, section: 0)], with: .bottom)
        })
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        
        alertController.addAction(action1)
        alertController.addAction(action2)
        alertController.addAction(action3)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
}

extension PlayerViewController: STKAudioPlayerDelegate {
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didStartPlayingQueueItemId queueItemId: NSObject) {
        debugPrint("didStartPlayingQueueItemId: \(queueItemId)")
        
        coverImageView.layer.removeAllAnimations()
        coverRotateAnimation = nil
        prepareAnimation()
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didFinishBufferingSourceWithQueueItemId queueItemId: NSObject) {
        debugPrint("didFinishBufferingSourceWithQueueItemId")
        
        
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, didFinishPlayingQueueItemId queueItemId: NSObject, with stopReason: STKAudioPlayerStopReason, andProgress progress: Double, andDuration duration: Double) {
        debugPrint("didFinishPlayingQueueItemId")
        
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, stateChanged state: STKAudioPlayerState, previousState: STKAudioPlayerState) {
        
        if state == .playing {
            playButton.setImage(UIImage(named: "player_paused"), for: UIControlState())
            playButton.setImage(UIImage(named: "player_paused_pressed"), for: .highlighted)
            
            NotificationManager.shared.postPlayMusicProgressStartedNotification()
            
            prepareAnimation()
        }
        else if state == .paused {
            playButton.setImage(UIImage(named: "player_play"), for: UIControlState())
            playButton.setImage(UIImage(named: "player_play_pressed"), for: .highlighted)
            
            NotificationManager.shared.postPlayMusicProgressPausedNotification()
        }
        else if state == .stopped {
            MusicManager.shared.playNextWhenFinished()
        }
        
    }
    
    func audioPlayer(_ audioPlayer: STKAudioPlayer, unexpectedError errorCode: STKAudioPlayerErrorCode) {
        debugPrint("unexpectedError")
    }
}
