//
//  ViewController.swift
//  Maze
//
//  Created by Roy Geagea on 7/14/20.
//  Copyright © 2020 Roy Geagea. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    private let gameTime = 35
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var mazeView: MazeView!
    
    @IBOutlet weak var failureLabel: UILabel!
    
    @IBOutlet weak var timerView: UIView!
    @IBOutlet weak var timerLabel: UILabel!
    @IBOutlet weak var retryButton: UIButton!
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    var timeLeft: Int = 0 {
        didSet {
            self.timerLabel.text = "\(timeLeft)"
        }
    }
    var timer: Timer?
    
    var numberOfFailures = 0 {
        didSet {
            self.failureLabel.text = "Failures: \(numberOfFailures)"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        self.containerView.backgroundColor = .clear
        self.view.backgroundColor = UIColor(red: 0.97, green: 0.98, blue: 0.98, alpha: 1.00)
        
        self.mazeView.delegate = self
        
        let mazeGenerator = MazeGenerator()
                
        self.view.layoutIfNeeded()
        mazeView.buildMaze(generator: mazeGenerator)
        
        self.timerView.backgroundColor = .clear
        self.timerView.layer.cornerRadius = self.timerView.bounds.height/2
        self.timerView.layer.masksToBounds = true
        self.timerView.layer.borderColor = UIColor.black.cgColor
        self.timerView.layer.borderWidth = 1.0
        
        self.retryButton.isHidden = true
        
        self.numberOfFailures = 0
        self.timeLeft = gameTime
                
        self.blurView.isHidden = true
        self.blurView.alpha = 0
        
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.changeTime), userInfo: nil, repeats: true)
    }
    
    @objc func changeTime() {
        self.timeLeft -= 1
        if timeLeft == 0 {
            self.gameFinished()
            self.gameOverUI()
        }
    }
    
    // MARK - Actions
    
    @IBAction func retryPressed(_ sender: UIButton) {
        self.restartUI()
        let mazeGenerator = MazeGenerator()                
        mazeView.buildMaze(generator: mazeGenerator)
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.changeTime), userInfo: nil, repeats: true)
    }
    
    func gameFinished() {
        self.timer?.invalidate()
        self.timer = nil
        self.mazeView.isUserInteractionEnabled = false
        self.mazeView.panGesture.isEnabled = false
        self.mazeView.panGesture.isEnabled = true
        self.retryButton.isHidden = false
        self.timerView.isHidden = true
    }
    
    func gameOverUI() {
        self.blurView.alpha = 0
        self.blurView.isHidden = false
        UIView.animate(withDuration: 0.4, animations: {
            self.blurView.alpha = 1
        }) { (s) in
            
        }
    }
    
    func restartUI() {
        self.numberOfFailures = 0
        self.mazeView.isUserInteractionEnabled = true
        self.timeLeft = gameTime
        self.retryButton.isHidden = true
        self.timerView.isHidden = false
        self.blurView.isHidden = true
        self.blurView.alpha = 0
    }
    
}

extension ViewController: MazeViewDelegate {
    func didFail() {
        numberOfFailures += 1
    }
    
    func didWin() {
        self.gameFinished()
    }
}
