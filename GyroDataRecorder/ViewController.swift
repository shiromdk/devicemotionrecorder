//
//  ViewController.swift
//  GyroDataRecorder
//
//  Created by Alan Nguyen on 15/6/18.
//  Copyright © 2018 Alan Nguyen. All rights reserved.
//

import UIKit
import CoreMotion
import CoreML
import Firebase
import FirebaseDatabase
class ViewController: UIViewController {
    
    @IBOutlet weak var x: UILabel!
    @IBOutlet weak var y: UILabel!
    @IBOutlet weak var z: UILabel!
    @IBOutlet weak var stepper: UIStepper!
    
    @IBOutlet weak var recordSwitch: UISwitch!
    @IBOutlet weak var currentabel: UILabel!
    
    @IBOutlet weak var predictionLabel: UILabel!
    @IBOutlet weak var countLabel: UILabel!
    
    var motion:CMMotionManager!
    var timer:Timer!
    var currentLabel:Int = 0
    var count:Int = 0
    var ref: DatabaseReference!
    var data = [Any]()
    let model = test()
    override func viewDidLoad() {
        ref = Database.database().reference()
        super.viewDidLoad()
        currentLabel = Int(stepper.value)
        currentabel.text = "Current Label: "+String(currentLabel)
        motion = CMMotionManager()
        startDeviceMotion()
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func valueChanged(_ sender: Any) {
        currentLabel = Int(stepper.value)
            currentabel.text = "Current Label: "+String(currentLabel)
    }
    @IBAction func push(_ sender: Any) {
//        self.ref.child("recording").setValue(data)
         self.ref.child("recordings").removeValue()
    }
    func startDeviceMotion() {
        if motion.isDeviceMotionAvailable {
            self.motion.deviceMotionUpdateInterval = 1.0 / 10.0
            self.motion.showsDeviceMovementDisplay = true
            self.motion.startDeviceMotionUpdates(using: .xMagneticNorthZVertical)
            
            // Configure a timer to fetch the motion data.
            self.timer = Timer(fire: Date(), interval: (1.0/60.0), repeats: true,
                               block: { (timer) in
                                if let data = self.motion.deviceMotion {
                                   
                                    // Get the attitude relative to the magnetic north reference frame.
                                    let xx = data.attitude.pitch
                                    let yy = data.attitude.roll
                                    let zz = data.attitude.yaw
                                    
                                    self.x.text = "X: "+String(xx)
                                    self.y.text = "Y: "+String(yy)
                                    self.z.text = "Z: "+String(zz)
                                    var dict = [String:Any]()
                                    dict["x"] = xx
                                    dict["y"] = yy
                                    dict["z"] = zz
                                    dict["label"] = self.stepper.value
                            
                                    guard let input_data = try? MLMultiArray(shape:[3], dataType:MLMultiArrayDataType.double) else {
                                        fatalError("Unexpected runtime error. MLMultiArray")
                                    }
                                    input_data[0] = xx as NSNumber
                                    input_data[1] = yy as NSNumber
                                    input_data[2] = zz as NSNumber
                                    guard let i = try? self.model.prediction(input1: input_data) else{
                                         fatalError("Unexpected runtime error. MLMultiArray")
                                    }
                                    
                                    let result = String(describing: i.output1[0])
                                    print(i.output1[3],i.output1[6],i.output1[8],i.output1[9],i.output1[12])
                                    if i.output1[3] == 1{
                                         self.predictionLabel.text = "3"
                                    }
                                    if i.output1[6] == 1{
                                         self.predictionLabel.text = "6"
                                    }
                                    if i.output1[9] == 1{
                                         self.predictionLabel.text = "9"
                                    }
                                    if i.output1[12] == 1{
                                            self.predictionLabel.text = "12"
                                    }
                                
                                    if(self.recordSwitch.isOn){
//                                        self.ref.child("recording").child(String(self.count)).setValue(dict)
//                                        self.count+=1
                                        self.data.append(dict)
                                    }
                                  
                                    // Use the motion data in your app.
                                }
                                self.countLabel.text = String(self.data.count)
            })
            
            // Add the timer to the current run loop.
            RunLoop.current.add(self.timer!, forMode: .defaultRunLoopMode)
        }
    }


}

