//
//  GameScene.swift
//  Project26
//
//  Created by Vladimir Kratinov on 2022/6/29.
//

import CoreMotion
import SpriteKit

enum CollisionTypes: UInt32 {
    case player = 1
    case wall = 2
    case star = 4
    case vortex = 8
    case finish = 16
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var player: SKSpriteNode!
    var lastTouchPosition: CGPoint?
    
    var motionManager: CMMotionManager?
    var levelNodes = [SKNode]()
    var levelList = [String]()
    
    var isGameOver = false
    var level = 1
    var totalLevel = 2
    
    var scoreLabel: SKLabelNode!
    var nextLvlLabel: SKLabelNode!
    
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    override func didMove(to view: SKView) {
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: 512, y: 384)
        background.blendMode = .replace
        background.zPosition = -1
        addChild(background)
        
        nextLvlLabel = SKLabelNode(fontNamed: "DamascusSemiBold")
        nextLvlLabel.text = "Next Level!"
        nextLvlLabel.horizontalAlignmentMode = .center
        nextLvlLabel.position = CGPoint(x: 512, y: 384)
        nextLvlLabel.fontSize = 60
        nextLvlLabel.fontColor = .green
        nextLvlLabel.zPosition = 2
        nextLvlLabel.alpha = 0
        addChild(nextLvlLabel)
        
        scoreLabel = SKLabelNode(fontNamed: "DamascusSemiBold")
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 16, y: 16)
        scoreLabel.zPosition = 2
        addChild(scoreLabel)
        
        loadLevel()
        createPlayer()
        
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        
        motionManager = CMMotionManager()
        motionManager?.startAccelerometerUpdates()
    }
    
    func loadLevel() {
        
        guard let levelURL = Bundle.main.url(forResource: "level\(level)", withExtension: "txt") else {
            fatalError("Could not find level\(level).txt in the app bundle.")
        }
        guard let levelString = try? String(contentsOf: levelURL) else {
            fatalError("Could not load level\(level).txt from the app bundle.")
        }
        
        
        let lines = levelString.components(separatedBy: "\n")
        
        for (row, line) in lines.reversed().enumerated() {
            for (column, letter) in line.enumerated() {
                let position = CGPoint(x: (64 * column) + 32, y: (64 * row) - 32)
                
                if letter == "x" {
                    //load wall
                    let node = SKSpriteNode(imageNamed: "block1")
                    node.position = position
                    node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
                    node.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue
                    node.physicsBody?.isDynamic = false
                    
                    levelNodes.append(node)
                    addChild(node)
                } else if letter == "v" {
                    //load vortex
                    let node = SKSpriteNode(imageNamed: "vortex")
                    node.name = "vortex"
                    node.position = position
                    node.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi, duration: 1)))
                    node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                    node.physicsBody?.isDynamic = false
                    node.physicsBody?.categoryBitMask = CollisionTypes.vortex.rawValue
                    node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                    node.physicsBody?.collisionBitMask = 0
                    
                    levelNodes.append(node)
                    addChild(node)
                } else if letter == "s" {
                    //load star
                    let node = SKSpriteNode(imageNamed: "star1")
                    node.name = "star"
                    node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                    node.physicsBody?.isDynamic = false
                    node.physicsBody?.categoryBitMask = CollisionTypes.star.rawValue
                    node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                    node.physicsBody?.collisionBitMask = 0
                    node.position = position
                    
                    //animation:
                    let scaleIn = SKAction.scale(by: 1.1, duration: 0.8)
                    let scaleOut = SKAction.scale(by: 0.9, duration: 0.8)
                    let scaleSeq = SKAction.sequence([scaleIn, scaleOut])
                    let repeatScaleSeq = SKAction.repeatForever(scaleSeq)
                    
                    let rotateClockWise = SKAction.rotate(byAngle: .pi / 4, duration: 3)
                    let rotateCounterClockWise = SKAction.rotate(byAngle: .pi / 2, duration: 3)
                    let wait = SKAction.wait(forDuration: 3)
                    
                    let rotateSeq = SKAction.sequence([rotateClockWise, wait, rotateCounterClockWise])
                    let repeatRotateSeq = SKAction.repeatForever(rotateSeq)
                    node.run(repeatScaleSeq)
                    node.run(repeatRotateSeq)
                    
                    levelNodes.append(node)
                    addChild(node)
                } else if letter == "f" {
                    //load finish point
                    let node = SKSpriteNode(imageNamed: "finish1")
                    node.name = "finish"
                    node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                    node.physicsBody?.isDynamic = false
                    node.physicsBody?.categoryBitMask = CollisionTypes.finish.rawValue
                    node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                    node.physicsBody?.collisionBitMask = 0
                    node.position = position
                    
                    levelNodes.append(node)
                    addChild(node)
                } else if letter == " " {
                    //this is an empty space - do nothing!
                } else {
                    fatalError("Unknown level letter: \(letter)")
                }
            }
        }
    }
    
    func createPlayer() {
        player = SKSpriteNode(imageNamed: "player")
        player.position = CGPoint(x: 96, y: 672)
        player.zPosition = 1
        
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.linearDamping = 0.5
        
        player.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
        player.physicsBody?.contactTestBitMask = CollisionTypes.star.rawValue | CollisionTypes.vortex.rawValue | CollisionTypes.finish.rawValue
        player.physicsBody?.collisionBitMask = CollisionTypes.wall.rawValue
        addChild(player)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchPosition = location
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        lastTouchPosition = location
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPosition = nil
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard isGameOver == false else { return }
        
        #if targetEnvironment(simulator)
        if let lastTouchPosition = lastTouchPosition {
            let diff = CGPoint(x: lastTouchPosition.x - player.position.x, y: lastTouchPosition.y - player.position.y)
            physicsWorld.gravity = CGVector(dx: diff.x / 100, dy: diff.y / 100)
        }
        #else
        if let accelerometerData = motionManager?.accelerometerData {
            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.y * -50, dy: accelerometerData.acceleration.x * 50)
        }
        #endif
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node else { return }
        guard let nodeB = contact.bodyB.node else { return }
        
        if nodeA == player {
            playerCollided(with: nodeB)
        } else if nodeB == player {
            playerCollided(with: nodeA)
        }
    }
    
    func playerCollided(with node: SKNode) {
        if node.name == "vortex" {
            player.physicsBody?.isDynamic = false
            isGameOver = true
            if score > 0 {
                score -= 1
            }
            
            let move = SKAction.move(to: node.position, duration: 0.25)
            let scale = SKAction.scale(to: 0.0001, duration: 0.25)
            let remove = SKAction.removeFromParent()
            let sequence = SKAction.sequence([move, scale, remove])
            
            player.run(sequence) { [weak self] in
                self?.createPlayer()
                self?.isGameOver = false
            }
        } else if node.name == "star" {
            let scale = SKAction.scale(to: 1.5, duration: 0.3)
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            let remove = SKAction.removeFromParent()
            let sequenceForFinish = SKAction.sequence([scale, fadeOut, remove])
            node.run(sequenceForFinish)
            
//            node.removeFromParent()
            score += 1
        } else if node.name == "finish" {
            //next level
            let scale = SKAction.scale(to: 1.3, duration: 0.3)
            let fadeOut = SKAction.fadeOut(withDuration: 0.7)
            let fadeIn = SKAction.fadeIn(withDuration: 0.7)
            let remove = SKAction.removeFromParent()
            
            let sequenceForFinish = SKAction.sequence([scale, fadeOut, remove])
            let sequenceForLabel = SKAction.sequence([fadeIn, scale, fadeOut])
            
            //player animation
            player.run(SKAction.scale(to: 0.0001, duration: 0.25))
            
            //delete Player:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.player.removeFromParent()
            }
            //delete Finish Point:
            node.run(sequenceForFinish)
            
            //next level:
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.nextLvlLabel.run(sequenceForLabel) { [weak self] in
                    self?.removeChildren(in: self!.levelNodes)
                    self?.score += 3
                    self?.level += 1
                    self?.loadLevel()
                    self?.createPlayer()
                }
                
                
            }
        }
    }
}
