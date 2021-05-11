//
//  ViewController.swift
//  demo
//
//  Created by Phil on 2020/9/30.
//  Copyright © 2020 Phil. All rights reserved.
//

import UIKit
import IRMusicPlayer_swift

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell.init()
        switch (indexPath.row) {
            case 0:
                cell.textLabel?.text = "Music Player"
                break;
        default:
            break
        }
        
        return cell;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch (indexPath.row) {
            case 0:
                do {
                    let xibBundle: Bundle = Bundle.init(for: MusicPlayerViewController.self)
                    let vc: MusicPlayerViewController = MusicPlayerViewController.init(nibName: "MusicPlayerViewController", bundle: xibBundle)
                    
                    vc.musicListArray.add(NSDictionary.init(object: Bundle.main.path(forResource: "1", ofType: "mp3")!, forKey: "musicAddress" as NSCopying))
                    
                    vc.musicListArray.add(NSDictionary.init(object: Bundle.main.path(forResource: "2", ofType: "mp3")!, forKey: "musicAddress" as NSCopying))
                    
                    vc.musicListArray.add(NSDictionary.init(object: Bundle.main.path(forResource: "3", ofType: "mp3")!, forKey: "musicAddress" as NSCopying))
                    
                    vc.modalPresentationStyle = .fullScreen
                    self.present(vc, animated: true, completion: nil)
                break;
            }
            default:
                break;
        }
    }
}

