//
//  ViewController.swift
//  ARDice
//
//  Created by Alex on 02/11/2022.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    private var diceArray = [SCNNode]()
    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 15, *) {
            let appearance = UINavigationBarAppearance()
            appearance.titleTextAttributes = [
                .foregroundColor : UIColor.label]
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        }
        // Set the view's delegate
        sceneView.delegate = self
        sceneView.autoenablesDefaultLighting = true
        sceneView.debugOptions = SCNDebugOptions.showFeaturePoints
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        configuration.planeDetection = .horizontal
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let location = touches.first?.location(in: sceneView) {
            let results = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
            let resultsForDeletion = sceneView.hitTest(location, options: [SCNHitTestOption.searchMode : 1])
            for res in resultsForDeletion.filter({
                $0.node.name == "dice"
            }) {
                res.node.removeFromParentNode()
                diceArray.remove(at: diceArray.firstIndex(of: res.node)!)
                return
            }
            if let result = results.first {
                let diceScene = SCNScene(named: "art.scnassets/diceCollada.scn")
                if let diceNode = diceScene?.rootNode.childNode(withName: "Dice", recursively: true) {
                    diceNode.position = SCNVector3(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
                    sceneView.scene.rootNode.addChildNode(diceNode)
                    diceNode.name = "dice"
                    diceArray.append(diceNode)
                    roll(diceNode)
                }
            }
        }
    }
    
    private func rollAll() {
        for dice in diceArray {
            roll(dice)
        }
    }
    
    private func roll(_ dice: SCNNode) {
        let randomX = Float(arc4random_uniform(4) + 1) * Float.pi / 2
        let randomZ = Float(arc4random_uniform(4) + 1) * Float.pi / 2
        dice.runAction(SCNAction.rotateBy(x: CGFloat(randomX * 5), y: 0, z: CGFloat(randomZ * 5), duration: 1))
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        rollAll()
    }
    
    @IBAction func rerollAll(_ sender: UIBarButtonItem) {
        rollAll()
    }
    
    @IBAction func removeAll(_ sender: UIBarButtonItem) {
        for dice in diceArray {
            dice.removeFromParentNode()
        }
        diceArray.removeAll()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if let planeAnchor = anchor as? ARPlaneAnchor {
            let plane = SCNPlane(width: CGFloat(planeAnchor.planeExtent.width), height: CGFloat(planeAnchor.planeExtent.height))
            let material = SCNMaterial()
            material.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
            plane.materials = [material]
            let planeNode = SCNNode(geometry: plane)
            planeNode.position = SCNVector3(planeAnchor.center.x, 0, planeAnchor.center.z)
            planeNode.transform = SCNMatrix4MakeRotation(-.pi / 2, 1, 0, 0)
            
            node.addChildNode(planeNode)
        }
    }
}
