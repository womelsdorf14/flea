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
    // Collection frequency (Hz)
    let frequency = 100.0
    
    // Seconds of data in sample
    let sample_size = 20
    
    // # segments of data sent to iOS to make sample (Remember: floating point arithmetic)
    var segments = 4
    
    // Initializations
    var sent = 0; var startTime = 0.0; var recording = false
    var arr: [[Double]] = [[], [], [], []]
    var session : WCSession!
    var motion_manager = CMMotionManager()

    @IBOutlet var breathtimer: WKInterfaceTimer!
    
    @IBOutlet var togR: WKInterfaceButton!
    
    @IBAction func toggle_record() {
        if (self.recording) {
            self.recording = false
            self.togR.setTitle("Start Session")
        } else {
            self.startTime = CFAbsoluteTimeGetCurrent()
            self.recording = true
            self.breathtimer.start()
            self.togR.setTitle("Stop")
        }
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

        // Collection frequency
//        motion_manager.gyroUpdateInterval = 1.0/self.frequency
        
        if (motion_manager.isDeviceMotionAvailable) {
            self.motion_manager.deviceMotionUpdateInterval = 1.0/self.frequency
            self.motion_manager.showsDeviceMovementDisplay = true
            self.motion_manager.startDeviceMotionUpdates(to: OperationQueue.current!) {(data, error) in
                if (self.sent>(self.segments-1)) {
                    // Already sent all segments. Stop.
                    self.recording = false
                    self.sent = 0
                    self.togR.setTitle("Start")
                } else {
                    if (self.recording) {
                        if let myData = data {
                            if self.arr[0].count<(Int(self.frequency)*self.sample_size/self.segments) {
                                self.fill(data: myData)
                            } else {
                                if (WCSession.default.isReachable) {
                                    WCSession.default.sendMessage(["data" : self.arr], replyHandler: nil, errorHandler: {(_ error: Error) -> Void in
                                        print("Error= \(error.localizedDescription)")})
                                }
                                self.arr = [[], [], [], []]
                                self.sent = self.sent + 1
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
