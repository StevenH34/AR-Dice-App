//
//  ViewController.swift
//  AR Dice
//
//  Created by Steven Hedges on 5/29/18.
//  Copyright © 2018 Steven Hedges. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    // Dice array that holds scene node obj - init as empty array
    var diceArray = [SCNNode]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Enable the debug option - shows the ap looking for planes
        // self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Show statistics such as fps and timing information
        // sceneView.showsStatistics = true
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Add light to scene
        sceneView.autoenablesDefaultLighting = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // S    etting the planeDetection to horizontal with the .horizontal enum
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // Convert users touch to a real world location
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let touchLocation = touch.location(in: sceneView)
            // convert 2D touch location into 3D
            let touchResult = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
            
            // Check for results
            if let hitResult = touchResult.first {
                createNewDiceScene(atLocation: hitResult)
            }
        }
    }
    
    func createNewDiceScene(atLocation location: ARHitTestResult) {
        // Creating new scene for the dice
        let diceScene = SCNScene(named: "art.scnassets/diceCollada.scn")!
        
        // Creating the child node - if diceNode is not nil...
        if let diceNode = diceScene.rootNode.childNode(withName: "Dice", recursively: true) {
            
            // Set node position
            diceNode.position = SCNVector3(
                x: location.worldTransform.columns.3.x,
                y: location.worldTransform.columns.3.y + diceNode.boundingSphere.radius,
                z: location.worldTransform.columns.3.z )
            
            // Add new dice node to the array
            diceArray.append(diceNode)
            
            // Add child dice node to the scene view
            sceneView.scene.rootNode.addChildNode(diceNode)
            
            rollDice(dice: diceNode)
        }
    }
    
    // Rolls all the dice at once
    func rollAllDice() {
        if !diceArray.isEmpty {
            for dice in diceArray {
                // loop through each dice - takes on SCN param
                rollDice(dice: dice)
            }
        }
    }
    
    func rollDice(dice: SCNNode) {
        // Creates a random number between 1 and 4 * PI/2
        let randomX = Float(arc4random_uniform(4) + 1) * (Float.pi/2)
        let randomZ = Float(arc4random_uniform(4) + 1) * (Float.pi/2)
        dice.runAction(
            SCNAction.rotateBy(
                x: CGFloat(randomX * 5),
                y: 0,
                z: CGFloat(randomZ * 5),
                duration: 0.5 ) )
    }
    
    @IBAction func rollButton(_ sender: UIBarButtonItem) {
        rollAllDice()
    }
    
    // motion roll
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        rollAllDice()
    }
    
    @IBAction func deleteAllDice(_ sender: UIBarButtonItem) {
        if !diceArray.isEmpty {
            for dice in diceArray {
                dice.removeFromParentNode()
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        
        let planeNode =  createPlane(withPlaneAnchor: planeAnchor)
        
        // add child node to root node
        node.addChildNode(planeNode)
        
    }
    
    func createPlane(withPlaneAnchor planeAnchor: ARPlaneAnchor) -> SCNNode {
        // Set width and height with the ARAnchor that was detected
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        let planeNode = SCNNode()
        planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
        // Need the plane to the horizontal
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        
        // Adding material to see the plane
        let gridMaterial = SCNMaterial()
        gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
        // Assinging to the plane material
        plane.materials = [gridMaterial]
        // Set geometry of plane node to the plane
        planeNode.geometry = plane
        
        return planeNode
    }
    
    
}
