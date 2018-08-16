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

    func fillA(data: CMDeviceMotion) {
        // 2D Array of [[Time], [gyX], [gyY], [gyZ]]
        self.arrA[0].append(CFAbsoluteTimeGetCurrent()-self.startTime)
        self.arrA[1].append(data.rotationRate.x)
        self.arrA[2].append(data.rotationRate.y)
        self.arrA[3].append(data.rotationRate.z)
        self.countA = self.countA + 1
    }
    
    func fillB(data: CMDeviceMotion) {
        // 2D Array of [[Time], [gyX], [gyY], [gyZ]]
        self.arrB[0].append(CFAbsoluteTimeGetCurrent()-self.startTime)
        self.arrB[1].append(data.rotationRate.x)
        self.arrB[2].append(data.rotationRate.y)
        self.arrB[3].append(data.rotationRate.z)
        self.countB = self.countB + 1
    }
    
    func resetA() {
        self.arrA = [[], [], [], []]
        self.countA = 0.0
        self.framesSent = self.framesSent + 1
        print("\(self.framesSent)")
    }
    
    func resetB() {
        self.arrB = [[], [], [], []]
        self.countB = 0.0
        self.framesSent = self.framesSent + 1
        print("\(self.framesSent)")
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
                self.startTime = CFAbsoluteTimeGetCurrent()
                if (self.framesSent < self.sampleSize) {
                    print("\(self.framesSent) out of \(self.sampleSize)")
                    if let myData = data {
                        if (self.useA == 1) {
                            if self.countA<self.frameSize {
                                self.fillA(data: myData)
                            } else {
                                self.useA = 0
                                self.fillB(data: myData)
                                if (WCSession.default.isReachable) {
                                    WCSession.default.sendMessage(["data" : self.arrA], replyHandler: nil, errorHandler: {(_ error: Error) -> Void in
                                        print("Error= \(error.localizedDescription)")})
                                }
                                self.resetA()
                            }
                        } else {
                            if self.countB<self.frameSize {
                                self.fillB(data: myData)
                            } else {
                                self.useA = 1
                                self.fillA(data: myData)
                                if (WCSession.default.isReachable) {
                                    WCSession.default.sendMessage(["data" : self.arrB], replyHandler: nil, errorHandler: {(_ error: Error) -> Void in
                                        print("Error= \(error.localizedDescription)")})
                                }
                                self.resetB()
                            }
                        }
                    }
                
                }
        }
            // print("\(self.framesSent) out of \(self.sampleSize)")
        }
        
  /*      // Record [frameSize] values per second
        motionManager.gyroUpdateInterval = 1.0/self.frameSize
        if (self.framesSent < self.sampleSize + 1) {
            if (motionManager.isDeviceMotionAvailable) {
                    self.motionManager.deviceMotionUpdateInterval = 1.0/self.frameSize
                    self.motionManager.showsDeviceMovementDisplay = true
                    self.motionManager.startDeviceMotionUpdates(to: OperationQueue.current!) {(data, error) in
                        self.startTime = CFAbsoluteTimeGetCurrent()
                        if let myData = data {
                            if (self.useA == 1) {
                                if self.countA<self.frameSize {
                                    self.fillA(data: myData)
                                } else {
                                    // arrA is full
                                    self.useA = 0
                                    self.fillB(data: myData)
                                    
                                    // send arrA
                                    if (WCSession.default.isReachable) {
                                        WCSession.default.sendMessage(["data" : self.arrA], replyHandler: nil, errorHandler: {(_ error: Error) -> Void in
                                            print("Error= \(error.localizedDescription)")})
                                    }
                                    self.resetA()
                                    
                                }
                            } else {
                                if self.countB<self.frameSize {
                                    self.fillB(data: myData)
                                } else {
                                    // arrB is full
                                    self.useA = 1
                                    self.fillA(data: myData)
                                    
                                    // send arrB
                                    if (WCSession.default.isReachable) {
                                        WCSession.default.sendMessage(["data" : self.arrB], replyHandler: nil, errorHandler: {(_ error: Error) -> Void in
                                            print("Error= \(error.localizedDescription)")})
                                    }
                                    self.resetB()
                                }
                            }
                        }
                    }
                print("\(self.framesSent) out of \(self.sampleSize)")
                }
            } else {
                print("WE DONE")
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
