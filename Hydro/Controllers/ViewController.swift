//
//  ViewController.swift
//  Hydro
//
//  Created by Michal Podroužek on 29/06/2020.
//  Copyright © 2020 Michal Podroužek. All rights reserved.
//

import UIKit
import ARKit
class ViewController: UIViewController, ARSCNViewDelegate {
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    var hydroAdded:Bool = false
    @IBOutlet weak var helpButt: UIButton!
    var start:(location:CGPoint, time:TimeInterval)?
    let minDistance:CGFloat = 25
    let minSpeed:CGFloat = 1000
    let maxSpeed:CGFloat = 6000
    var touchesArray = [0,0,0]
    

    @IBOutlet weak var label: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.configuration.planeDetection = .horizontal
        configuration.environmentTexturing = .automatic
        self.sceneView.session.run(configuration)
        self.sceneView.autoenablesDefaultLighting = true
        self.sceneView.delegate = self
        let tapGestureRecogniser = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.sceneView.addGestureRecognizer(tapGestureRecogniser)
        // Do any additional setup after loading the view.
    }

    @objc func handleTap(sender: UITapGestureRecognizer){
        if(!hydroAdded){
            guard let sceneView = sender.view as? ARSCNView else{return}
            let touchLocation = sender.location(in: sceneView)
            let hitTestResult = sceneView.hitTest(touchLocation, types:[.existingPlaneUsingExtent])
            if !hitTestResult.isEmpty{
                self.addHydro(hitTestResult:hitTestResult.first!)
            }
        }else{
            guard let sceneView = sender.view as? ARSCNView else{return}
            let touchLocation = sender.location(in: sceneView)
            let hitTestResult = sceneView.hitTest(touchLocation)
            if hitTestResult.isEmpty{
                print("didnt touch anything")
            }else{
                guard let node = hitTestResult.first?.node else{return}
                let nodeName = node.geometry?.name
                print()
                if(nodeName == "kohutik1" || nodeName == "kohutik2"){
                    frontValveHit(node: node)
                }
                else if(nodeName == "FirstBarelInside" || nodeName == "SecondBarelInside" || nodeName == "ThirdBarelInside" ){
                    barelHit(node: node)
                }
            }
        }
    }
    
    func frontValveHit(node: SCNNode){
        if(Int(round(node.rotation.y)) == 0){
            let action = SCNAction.rotateBy(x: 0, y: CGFloat(35.degreesToRadians), z: 0, duration: 1)
            node.runAction(action)
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.green
        }else{
            let action = SCNAction.rotateBy(x: 0, y: CGFloat(-35.degreesToRadians), z: 0, duration: 1)
            node.runAction(action)
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        }
    }
    
    func barelHit(node: SCNNode){
        let nodeName = node.geometry?.name
        node.geometry?.materials.removeAll()
        node.geometry?.firstMaterial = SCNMaterial()
        var i = 0
        if(nodeName == "FirstBarelInside" ){
            touchesArray[0] = (touchesArray[0] > 5 ? 0 : touchesArray[0] + 1)
            i = touchesArray[0]
        }else if(nodeName == "SecondBarelInside"){
            touchesArray[1] = (touchesArray[1] > 5 ? 0 : touchesArray[1] + 1)
            i = touchesArray[1]
        }else if(nodeName == "ThirdBarelInside"){
            touchesArray[2] = (touchesArray[2] > 5 ? 0 : touchesArray[2] + 1)
            i = touchesArray[2]
        }
        switch i {
        case 1:
            node.geometry?.firstMaterial?.diffuse.contents = hexStringToUIColor(hex: "#00FF00")
        case 2:
            node.geometry?.firstMaterial?.diffuse.contents = hexStringToUIColor(hex: "#9FFF00")
        case 3:
            node.geometry?.firstMaterial?.diffuse.contents = hexStringToUIColor(hex: "#FFFF00")
        case 4:
            node.geometry?.firstMaterial?.diffuse.contents = hexStringToUIColor(hex: "#FF9E00")
        case 5:
            node.geometry?.firstMaterial?.diffuse.contents = hexStringToUIColor(hex: "#FF0000")
        default:
            break;
        }
        node.filters?.removeAll()
        node.filters? = addBloom()!
    }
    
    
    func addHydro(hitTestResult: ARHitTestResult){
        if hydroAdded == false{
            let hydroScene = SCNScene(named: "Hydro.scnassets/hydro5.scn")
            let hydroNode = hydroScene?.rootNode.childNode(withName: "Hydro", recursively: false)
            let positionOfPlane = hitTestResult.worldTransform.columns.3
            let xPosition = positionOfPlane.x
            let yPosition = positionOfPlane.y
            let zPosition = positionOfPlane.z
            hydroNode?.position = SCNVector3(xPosition, yPosition, zPosition)
            hydroNode?.enumerateChildNodes{(node, _) in
                if (node.name == "FirstBarelInside" || node.name == "SecondBarelInside" || node.name == "ThirdBarelInside"){
                    node.geometry?.firstMaterial = createGlass()
                    node.filters = addBloom()
                }
                else if (node.name == "kohutik1" || node.name == "kohutik2" || node.name == "FirstPumpCube" || node.name == "SecondPumpCube" || node.name == "ThirdPumpCube"){
                    node.filters = addBloom()
                }
            }
            self.sceneView.scene.rootNode.addChildNode(hydroNode!)
            self.hydroAdded = true
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return}
        DispatchQueue.main.async {
            self.label.isHidden = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now()+3, execute: {
            self.label.isHidden = true
        })
    }
    
    @IBAction func helpButton(_ sender: UIButton) {
        self.performSegue(withIdentifier: "goToHelp", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToHelp" {
            let destinationVC = segue.destination as! HelpViewController
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            start = (touch.location(in: sceneView), touch.timestamp)
            print(touch.location(in: sceneView))
        }
        let touch = touches.first!
        if(touch.view == self.sceneView){
            let viewTouchLocation:CGPoint = touch.location(in: sceneView)
            guard let result = sceneView.hitTest(viewTouchLocation, options: nil).first else {
                return
            }
            print("touch working")
            let node = result.node
            let nodeName = node.geometry?.name
            
        }
    }
    
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        var swiped = false
//        if let touch = touches.first, let startTime = self.start?.time,
//                let startLocation = self.start?.location {
//            let location = touch.location(in:sceneView)
//            let dx = location.x - startLocation.x
//            let dy = location.y - startLocation.y
//            let distance = sqrt(dx*dx+dy*dy)
//
//            // Check if the user's finger moved a minimum distance
//            if distance > minDistance {
//
//                let deltaTime = CGFloat(touch.timestamp - startTime)
//                let speed = distance / deltaTime
//
//                // Check if the speed was consistent with a swipe
//                if speed >= minSpeed && speed <= maxSpeed {
//
//                    // Determine the direction of the swipe
//                    let x = abs(dx/distance) > 0.4 ? Int(sign(Float(dx))) : 0
//                    let y = abs(dy/distance) > 0.4 ? Int(sign(Float(dy))) : 0
//
//                    swiped = true
////                    switch (x,y) {
////                    case (0,1):
////                        print("swiped up")
////                    case (0,-1):
////                        print("swiped down")
////                    case (-1,0):
////                        print("swiped left")
////                    case (1,0):
////                        print("swiped right")
////                    case (1,1):
////                        print("swiped diag up-right")
////                    case (-1,-1):
////                        print("swiped diag down-left")
////                    case (-1,1):
////                        print("swiped diag up-left")
////                    case (1,-1):
////                        print("swiped diag down-right")
////                    default:
////                        swiped = false
////                        break
////                    }
//                }
//            }
//        }
//        start = nil
//        if !swiped {
//            // Process non-swipes (taps, etc.)
//            print("not a swipe")
//        }
        
        
    }
    
    // Helper functions
    func addBloom() -> [CIFilter]? {
        let bloomFilter = CIFilter(name:"CIBloom")!
        bloomFilter.setValue(10.0, forKey: "inputIntensity")
        bloomFilter.setValue(30.0, forKey: "inputRadius")

        return [bloomFilter]
    }
    
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        var rgbValue:UInt64 = 0
        Scanner(string: cString).scanHexInt64(&rgbValue)
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
    func createGlass()->SCNMaterial{
        let glass = SCNMaterial()
        glass.lightingModel = .physicallyBased
        glass.metalness.contents = UIColor(white: 1.0, alpha: 1.0)
        glass.diffuse.contents = UIColor(white: 0.2, alpha: 1.0)
        glass.roughness.contents = UIColor(white: CGFloat(0.03), alpha: 1.0)
        glass.transparencyMode = .dualLayer
        glass.isDoubleSided = true
        glass.transparency = 0.2
        return glass
    }
}

extension Int{
    var degreesToRadians: Double{ return Double(self) * .pi/180}
}
