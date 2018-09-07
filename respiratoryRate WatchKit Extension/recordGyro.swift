//
//  recordGyro.swift
//  respiratoryRate WatchKit Extension
//
//  Created by Leah Womelsdorf on 8/15/18.
//  Copyright © 2018 Leah Womelsdorf. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity
import CoreMotion


class recordGyro: WKInterfaceController, WCSessionDelegate {
    
// TODO: Change these parameters to meet your needs
    // Collection frequency
    let frameSize = 100.0
    
    
      // ADDING TODAY FOR FIXED LENGTH !!!
    // Length of data samples
    let sampleSize = 60
    
    var part3 = 0

    


    var startTime = 0.0
    var session : WCSession!
    var motionManager = CMMotionManager()
    var arr: [[Double]] = [[], [], [], []]

    var shouldRec = false
    @IBOutlet var togR: WKInterfaceButton!
    
    @IBAction func toggleRec() {
        if (self.shouldRec) {
            self.shouldRec = false
            self.togR.setTitle("Start")
     /*       if (self.arr.count>0) {
                if (WCSession.default.isReachable) {
                    WCSession.default.sendMessage(["data" : self.arr], replyHandler: nil, errorHandler: {(_ error: Error) -> Void in
                        print("Error= \(error.localizedDescription)")})
                }
                self.arr = [[], [], [], []]
             } */
        } else {
            self.startTime = CFAbsoluteTimeGetCurrent()
            self.shouldRec = true
            self.togR.setTitle("Stop")
        }
        
        
        /*
         if (self.shouldRec) {
         self.shouldRec = false
         self.togR.setTitle("Start")
         if (self.arr.count>0) {
         if (WCSession.default.isReachable) {
         WCSession.default.sendMessage(["data" : self.arr], replyHandler: nil, errorHandler: {(_ error: Error) -> Void in
         print("Error= \(error.localizedDescription)")})
         }
         self.arr = [[], [], [], []]
         }
         } else {
         self.startTime = CFAbsoluteTimeGetCurrent()
         self.shouldRec = true
         self.togR.setTitle("Stop")
         }
         */
    }
    
    
    
    
    
    
    
    func fill(data: CMDeviceMotion) {
        
        // 2D Array of [[Time], [gyX], [gyY], [gyZ]]
        self.arr[0].append(CFAbsoluteTimeGetCurrent()-self.startTime)
        self.arr[1].append(data.rotationRate.x)
        self.arr[2].append(data.rotationRate.y)
        self.arr[3].append(data.rotationRate.z)
 
    }
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        session = WCSession.default
        session.delegate = self
        session.activate()

        motionManager.gyroUpdateInterval = 1.0/self.frameSize
        
        if (motionManager.isDeviceMotionAvailable) {
            self.motionManager.deviceMotionUpdateInterval = 1.0/self.frameSize
            self.motionManager.showsDeviceMovementDisplay = true
            self.motionManager.startDeviceMotionUpdates(to: OperationQueue.current!) {(data, error) in
//                self.startTime = CFAbsoluteTimeGetCurrent()
                
                if (self.part3>2) {
                    // Already sent all 3 parts. Stop.
                    self.shouldRec = false
                    self.part3 = 0
                    self.togR.setTitle("Start")
                } else {
                    if (self.shouldRec) {
                        if let myData = data {
                            if self.arr[0].count<(Int(self.frameSize)*self.sampleSize/3) {
                                self.fill(data: myData)
                            } else {
                                if (WCSession.default.isReachable) {
                                    WCSession.default.sendMessage(["data" : self.arr], replyHandler: nil, errorHandler: {(_ error: Error) -> Void in
                                        print("Error= \(error.localizedDescription)")})
                                }
//                                WKInterfaceDevice.current().play(.directionUp)
                                self.arr = [[], [], [], []]
                                self.part3 = self.part3 + 1
                            }
                        }
                    }
                }
            }
        }
    }
    
        
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    // Receive message from iOS app
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        let received = (message["Count"] as? String)
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    
    
    
    
}
