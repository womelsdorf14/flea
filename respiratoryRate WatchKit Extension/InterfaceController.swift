//
//  InterfaceController.swift
//  respiratoryRate WatchKit Extension
//
//  Created by Leah Womelsdorf on 8/6/18.
//  Copyright © 2018 Leah Womelsdorf. All rights reserved.
//

import WatchKit
import Foundation
import WatchConnectivity
import CoreMotion


class InterfaceController: WKInterfaceController, WCSessionDelegate {
    
    // TODO: Change these parameters to meet your needs
    // Collection frequency
    let frameSize = 100.0
    // Seconds of data per sample
    let sampleSize = 20
    
    
    var startTime = 0.0
    var session : WCSession!
    var motionManager = CMMotionManager()
    var countA = 0.0
    var countB = 0.0
    var arrA: [[Double]] = [[], [], [], []]
    var arrB: [[Double]] = [[], [], [], []]
    var framesSent = 0
    var useA = 1
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        session = WCSession.default
        session.delegate = self
        session.activate()
        
        
        /*
        
        
        
        
        // Record [frameSize] values per second
        motionManager.gyroUpdateInterval = 1.0/self.frameSize
        
        if (motionManager.isDeviceMotionAvailable) {
            if (self.framesSent <= self.sampleSize) {
                self.motionManager.deviceMotionUpdateInterval = 1.0/self.frameSize
                self.motionManager.showsDeviceMovementDisplay = true
                self.motionManager.startDeviceMotionUpdates(to: OperationQueue.current!) {(data, error) in
                    self.startTime = CFAbsoluteTimeGetCurrent()
                    if let myData = data {
                        if (self.useA == 1) {
                            // Fill arrA, send arrB
                            
                            if self.countA<self.frameSize {
                                // 2D Array of [[Time], [gyX], [gyY], [gyZ]]
                                self.arrA[0].append(CFAbsoluteTimeGetCurrent()-self.startTime)
                                self.arrA[1].append(myData.rotationRate.x)
                                self.arrA[2].append(myData.rotationRate.y)
                                self.arrA[3].append(myData.rotationRate.z)
                                self.countA = self.countA + 1
                            } else {
                                // arrA is full
                                self.useA = 0
                                
                                // start fill arrB
                                self.arrB[0].append(CFAbsoluteTimeGetCurrent()-self.startTime)
                                self.arrB[1].append(myData.rotationRate.x)
                                self.arrB[2].append(myData.rotationRate.y)
                                self.arrB[3].append(myData.rotationRate.z)
                                self.countB = self.countB + 1
                                
                                // send arrA
                                if (WCSession.default.isReachable) {
                                    WCSession.default.sendMessage(["data" : self.arrA], replyHandler: nil, errorHandler: {(_ error: Error) -> Void in
                                        print("Error= \(error.localizedDescription)")})
                                    
                                }
                                self.arrA = [[], [], [], []]
                                self.countA = 0.0
                                self.framesSent = self.framesSent + 1
                                
                            }
                        } else {
                            // Fill arrB, send arrA
                            if self.countB<self.frameSize {
                                self.arrB[0].append(CFAbsoluteTimeGetCurrent()-self.startTime)
                                self.arrB[1].append(myData.rotationRate.x)
                                self.arrB[2].append(myData.rotationRate.y)
                                self.arrB[3].append(myData.rotationRate.z)
                                self.countB = self.countB + 1
                            } else {
                                // arrB is full
                                self.useA = 1
                                
                                // start fill arrA
                                self.arrA[0].append(CFAbsoluteTimeGetCurrent()-self.startTime)
                                self.arrA[1].append(myData.rotationRate.x)
                                self.arrA[2].append(myData.rotationRate.y)
                                self.arrA[3].append(myData.rotationRate.z)
                                self.countA = self.countA + 1
                                
                                // send arrB
                                if (WCSession.default.isReachable) {
                                    WCSession.default.sendMessage(["data" : self.arrB], replyHandler: nil, errorHandler: {(_ error: Error) -> Void in
                                        print("Error= \(error.localizedDescription)")})
                                }
                                self.arrB = [[], [], [], []]
                                self.countB = 0.0
                                self.framesSent = self.framesSent + 1
                            }
                            
                        }
                    }
                }
            } else {
                // Already filled full sample
                
            }
        }
 */
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

