//
//  MazeView.swift
//  Maze
//
//  Created by Roy Geagea on 7/14/20.
//  Copyright © 2020 Roy Geagea. All rights reserved.
//

import UIKit
import AVFoundation

protocol MazeViewDelegate: class {
    func didFail()
    func didWin()
}

class MazeView: UIView {
    
    enum NodePlace {
        case up
        case down
        case left
        case right
    }
    
    private let wallColor = UIColor(red: 0.87, green: 0.88, blue: 0.96, alpha: 1.00)
    private let roadColor = UIColor(red: 0.00, green: 0.13, blue: 0.38, alpha: 1.00)
    
    @IBOutlet private var contentView: UIView!
    private var luckyImgView: UIImageView!
    private var boneImgView: UIImageView!
    
    var panGesture: UIPanGestureRecognizer!
    
    private var generator: MazeGenerator!
    private var emptyRoadRects = [CGRect]()
    private var roadNodes = [Node]()
    
    private var roadLine = CAShapeLayer()
    private var roadPath = UIBezierPath()
    
    private var roadPathAnimation = UIBezierPath()

    private var didUserWin = false
    
    var player: AVAudioPlayer?
    
    weak var delegate: MazeViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        self.setupUI()
    }
    
    private func setupUI() {
        Bundle.main.loadNibNamed("MazeView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        contentView.backgroundColor = .clear
        self.backgroundColor = .clear
        
        self.panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePan(_:)))
        self.isUserInteractionEnabled = true
        self.addGestureRecognizer(self.panGesture)
    }
    
    func buildMaze(generator: MazeGenerator) {
        self.player?.pause()
        self.player = nil
        emptyRoadRects.removeAll()
        roadNodes.removeAll()
        self.roadLine = CAShapeLayer()
        self.roadPath = UIBezierPath()
        self.roadPathAnimation = UIBezierPath()
        self.didUserWin = false
        for view in self.subviews {
            view.removeFromSuperview()
        }
        
        for layer in self.layer.sublayers ?? [CALayer]() {
            layer.removeFromSuperlayer()
        }
        
        self.generator = generator
        
        let imageWidth = (self.bounds.width/CGFloat(generator.mazeWidth))*4 - 16
        
        self.boneImgView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageWidth, height: imageWidth))
        self.boneImgView.center = CGPoint(x: self.bounds.width/CGFloat(generator.mazeWidth)*2, y: self.bounds.height/CGFloat(generator.mazeHeight) * CGFloat(generator.mazeHeight-2))
        self.boneImgView.image = UIImage(named: "bone")
        self.addSubview(self.boneImgView)
        
        self.luckyImgView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageWidth, height: imageWidth))
        self.luckyImgView.center = CGPoint(x: self.bounds.width/CGFloat(generator.mazeWidth) * CGFloat(generator.mazeWidth-2), y: self.bounds.height/CGFloat(generator.mazeHeight)*2)
        self.luckyImgView.image = UIImage(named: "lucky")
        self.addSubview(self.luckyImgView)
        
        let nodeWidth = self.bounds.width/CGFloat(generator.mazeWidth)
        let nodeHeight = self.bounds.height/CGFloat(generator.mazeHeight)
        for i in 0...generator.data.count - 1 {
            let currentRow = generator.data[i]
            for j in 0...currentRow.count - 1 {
                let currentNode = currentRow[j]
                if currentNode.cellType == .wall {
                    let nodeRect = CGRect(x: CGFloat(i)*nodeWidth, y: CGFloat(j)*nodeHeight + nodeHeight/2, width: nodeWidth, height: nodeHeight)
                    drawMaze(rect: nodeRect, color: wallColor)
                }
                else {
                    let nodeRect = CGRect(x: CGFloat(i)*nodeWidth, y: CGFloat(j)*nodeHeight, width: nodeWidth, height: nodeHeight)
                    emptyRoadRects.append(nodeRect)
                }
            }
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let state = gesture.state
        let location =  gesture.location(in: self)
        
        switch state {
            case .began:
                if isPointValidToStart(point: location) {
                    let node = self.getNodeFromPoint(location)
                    self.drawRoadNode(node: node)
                    self.playSound(name: "dog_breathing", withLoop: true)
                }
                else {
                    gesture.isEnabled = false
                    gesture.isEnabled = true
                }
            case .changed:
                if isPointValidForRoad(point: location) {
                    let node = self.getNodeFromPoint(location)
                    if !self.roadNodes.contains(node) && isAbleToAddNode(node: node) {
                        self.drawRoadNode(node: node)
                    }
                    if self.roadNodes.count > 2 {
                        let beforeLatestNode = self.roadNodes[self.roadNodes.count-3]
                        if beforeLatestNode.x == node.x && beforeLatestNode.y == node.y {
                            gesture.isEnabled = false
                            gesture.isEnabled = true
                        }
                    }
                }
            case .ended, .cancelled, .failed:
                if !self.didUserWin {
                    self.roadNodes.removeAll()
                    roadLine.removeFromSuperlayer()
                    self.roadLine = CAShapeLayer()
                    self.roadPath = UIBezierPath()
                    self.player?.pause()
                    self.player = nil
                    self.playSound(name: "woof", withLoop: false)
                    self.delegate?.didFail()
                }
                else {
                    self.isUserInteractionEnabled = false
                    gesture.isEnabled = false
                    self.animateLucky()
                    self.player?.pause()
                    self.player = nil
                    self.playSound(name: "short_triumphal", withLoop: false)
                    self.delegate?.didWin()
                }
            default: break
        }
    }
    
    private func isPointValidToStart(point: CGPoint) -> Bool {
        let nodeSize = self.bounds.width/CGFloat(generator.mazeWidth)
        let startRect = CGRect(x: nodeSize * CGFloat((generator.mazeWidth-4)), y: 0, width: nodeSize*4, height: nodeSize*4)
        return startRect.contains(point)
    }
    
    private func isPointValidForRoad(point: CGPoint) -> Bool {
        let first = self.emptyRoadRects.first { (rect) -> Bool in
            return rect.contains(point)
        }
        return first != nil
    }
    
    private func isPointInExitRect(point: CGPoint) -> Bool {
        let nodeSize = self.bounds.width/CGFloat(generator.mazeWidth)
        let exitRect = CGRect(x: 0, y: CGFloat((self.generator.mazeHeight-4)) * nodeSize, width: nodeSize * 4, height: nodeSize * 4)
        return exitRect.contains(point)
    }
    
    private func isAbleToAddNode(node: Node) -> Bool {
        let latestNode = self.roadNodes.last!
        return ((latestNode.x == node.x + 1 || latestNode.x == node.x - 1) && latestNode.y == node.y) || ((latestNode.y == node.y + 1 || latestNode.y == node.y - 1) && latestNode.x == node.x)
    }
    
    private func getNodeFromPoint(_ point: CGPoint) -> Node {
        let nodeSize = self.bounds.width/CGFloat(self.generator.mazeWidth)
        let x = Int(point.x / nodeSize)
        let y = Int(point.y / nodeSize)
        return self.generator.data[y][x]
    }
    
    private func drawRoadNode(node: Node) {
        let nodeSize = self.bounds.width/CGFloat(generator.mazeWidth)
        let rect = CGRect(x: CGFloat(node.x)*nodeSize + 3, y: CGFloat(node.y)*nodeSize + nodeSize/2, width: nodeSize-6, height: nodeSize-6)
        if self.roadNodes.count == 0 {
            self.drawRoadPath(rect: rect, color: roadColor)
        }
        else {
            self.drawRoadPath(rect: self.getIntersectionRect(latestNode: self.roadNodes.last!, currentNode: node), color: roadColor)
            self.drawRoadPath(rect: rect, color: roadColor)
        }
        self.roadNodes.append(node)
        if node.x < 4 && node.y >= self.generator.mazeHeight-4 {
            self.didUserWin = true
            self.panGesture.isEnabled = false
            self.panGesture.isEnabled = true
        }
    }
    
    private func animateLucky() {
        let nodeSize = self.bounds.width/CGFloat(generator.mazeWidth)
        for i in 0...roadNodes.count - 1 {
            let currentNode = roadNodes[i]
            let nodeCenter = CGPoint(x: CGFloat(currentNode.x)*nodeSize + nodeSize/2, y: CGFloat(currentNode.y)*nodeSize + nodeSize/2)
            if i == 0 {
                roadPathAnimation.move(to: nodeCenter)
            }
            else {
                roadPathAnimation.addLine(to: nodeCenter)
            }
        }
        let animation = CAKeyframeAnimation(keyPath: "position")
        animation.path = roadPathAnimation.cgPath
        animation.duration = 0.15*Double(self.roadNodes.count)
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        self.luckyImgView.layer.add(animation, forKey: nil)
    }
    
    private func getIntersectionRect(latestNode: Node, currentNode: Node) -> CGRect {
        let nodeSize = self.bounds.width/CGFloat(generator.mazeWidth)
        if currentNode.y > latestNode.y {
            let rect = CGRect(x: CGFloat(currentNode.x)*nodeSize + 3, y: CGFloat(currentNode.y)*nodeSize, width: nodeSize-6, height: nodeSize-6)
            return rect
        }
        else if currentNode.y < latestNode.y {
            let rect = CGRect(x: CGFloat(currentNode.x)*nodeSize + 3, y: CGFloat(currentNode.y+1)*nodeSize, width: nodeSize-6, height: nodeSize-6)
            return rect
        }
        else if currentNode.x < latestNode.x {
            let rect = CGRect(x: CGFloat(currentNode.x+1)*nodeSize - nodeSize/2, y: CGFloat(currentNode.y)*nodeSize + nodeSize/2, width: nodeSize-6, height: nodeSize-6)
             return rect
        }
        else { // currentNode.x > latestNode.x
            let rect = CGRect(x: CGFloat(currentNode.x)*nodeSize - nodeSize/2, y: CGFloat(currentNode.y)*nodeSize + nodeSize/2, width: nodeSize-6, height: nodeSize-6)
             return rect
        }
    }
    
    @discardableResult private func drawMaze(rect: CGRect, color: UIColor) -> CAShapeLayer {
        let line = CAShapeLayer()
        let aPath = UIBezierPath()

        aPath.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y))
        aPath.addLine(to: CGPoint(x: rect.origin.x + rect.width, y: rect.origin.y))

        // Keep using the method addLine until you get to the one where about to close the path
        aPath.close()

        // If you want to stroke it with a red color
        color.set()
        aPath.lineWidth = rect.height
        aPath.stroke()
        
        line.path = aPath.cgPath
        line.strokeColor = color.cgColor
        line.lineWidth = aPath.lineWidth
        
        self.layer.insertSublayer(line, at: 0)
        return line
    }
    
    @discardableResult private func drawRoadPath(rect: CGRect, color: UIColor) -> CAShapeLayer {
        roadPath.move(to: CGPoint(x: rect.origin.x, y: rect.origin.y))
        roadPath.addLine(to: CGPoint(x: rect.origin.x + rect.width, y: rect.origin.y))
        
        roadPath.close()
        
        roadPath.lineWidth = rect.height
        roadPath.stroke()
        
        roadLine.path = roadPath.cgPath
        roadLine.strokeColor = color.cgColor
        roadLine.lineWidth = roadPath.lineWidth
        
        if roadLine.superlayer == nil {
            self.layer.insertSublayer(roadLine, at: 0)
        }
        return self.roadLine
    }
}

// MARK: - Sounds

extension MazeView {
    
    func playSound(name: String, withLoop: Bool) {
        DispatchQueue.global(qos: .background).async {
            guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }

            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)

                self.player = try AVAudioPlayer(contentsOf: url)
                if withLoop {
                    self.player?.numberOfLoops = -1
                }

                guard let player = self.player else { return }

                player.play()

            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
    
}
