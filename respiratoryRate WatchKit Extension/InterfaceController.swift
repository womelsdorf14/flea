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

