//
//  ViewController.swift
//  respiratoryRate
//
//  Created by Leah Womelsdorf on 8/6/18.
//  Copyright © 2018 Leah Womelsdorf. All rights reserved.
//
import UIKit
import WatchConnectivity
import Charts
import SwiftyDropbox
import Foundation


class ViewController: UIViewController, WCSessionDelegate{

    
    // TODO: Change to your OAuth2 token to send to your Dropbox
    var client = DropboxClient(accessToken: "O0rjYSZUS9AAAAAAAAACTlsFwgxufsT5OkM5oa7wImJIbkAIQr6f7r3xf6AzQQ3g")
    
    // # segments of data received from watch to make full sample
    var goal_received = 4
    
    // Initializations
    var received = 0; var count = 0; var arrGy: [[Double]] = [[], [], [], []]
    var session : WCSession!

    @IBOutlet weak var rate: UILabel!
    @IBAction func calculate_Breath(_ sender: Any) {
        let gyroData3 = [arrGy[1], arrGy[2], arrGy[3]]
        let breathRateAlg = BreathRateAlg(sampleRate: 100, log2N: Int(round(log2(Double(arrGy[1].count)))))
        var breathRate = breathRateAlg.getBreathRate(oneFrameArr: gyroData3)
        rate.text = "\(round(breathRate))"
        print("\(breathRate)")
        self.arrGy = [[], [], [], []]
        self.received = 0
    }
    
    @IBOutlet weak var numFR: UILabel!
    @IBOutlet weak var cS: UILabel!
    @IBOutlet var chtChart: LineChartView!
    @IBOutlet weak var bpm_value: UILabel!
    
    func send_data() {
        self.cS.text = "SENT \(self.received)"
        let timestamp = "\(CFAbsoluteTimeGetCurrent())"
        var csvText = "Time,gyX,gyY,gyZ\n"
        let count = arrGy[0].count
        for i in 0..<count {
            let newLine = "\(arrGy[0][i]),\(arrGy[1][i]),\(arrGy[2][i]),\(arrGy[3][i])\n"
            csvText.append(newLine)
        }
        let fileData = csvText.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        client.files.upload(path: "/respiratoryRate/dataGy/\(timestamp).csv", input: fileData)
            .response { response, error in
                if let response = response {
                    print(response)
                } else if let error = error {
                    print(error)
                }
            }
            .progress { progressData in
                print(progressData)
        }
        
        // Calculated breathRate
        let axis = [arrGy[1],arrGy[2],arrGy[3]]
        let breath_alg = BreathRateAlg(sampleRate: 100, log2N: Int(round(log2(Double(arrGy[1].count)))))
        let breathRate = breath_alg.getBreathRate(oneFrameArr: axis)
        print("\(breathRate)")
        bpm_value.text = "\(breathRate)"
        
        // Testing to see for the button press
//        self.arrGy = [[], [], [], []]
//        self.received = 0
    }
    
    
    func updateGraph() {
        var lineChartEntryA = [ChartDataEntry]()
        var lineChartEntryB = [ChartDataEntry]()
        var lineChartEntryC = [ChartDataEntry]()
        var top = min(arrGy[0].count, 20000)
        for i in 0..<top {
            let valueA = ChartDataEntry(x: Double(i), y:arrGy[1][i])
            let valueB = ChartDataEntry(x: Double(i), y:arrGy[2][i])
            let valueC = ChartDataEntry(x: Double(i), y:arrGy[3][i])
            
            lineChartEntryA.append(valueA)
            lineChartEntryB.append(valueB)
            lineChartEntryC.append(valueC)
        }
        
        let line1 = LineChartDataSet(values: lineChartEntryA, label: "Number")
        line1.colors = [NSUIColor.green]
        let line2 = LineChartDataSet(values: lineChartEntryB, label: "Number")
        line2.colors = [NSUIColor.blue]
        let line3 = LineChartDataSet(values: lineChartEntryC, label: "Number")
        line3.colors = [NSUIColor.red]
        
        
        let data = LineChartData()
        data.addDataSet(line1)
        data.addDataSet(line2)
        data.addDataSet(line3)
        
        chtChart.data = data
        chtChart.chartDescription?.text = "My awesome chart"
    }
    

    
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async() {
            // Instantaneous update
            let array = message["data"] as! NSArray
            self.count = array.count
            for entry in array[0] as! NSArray {self.arrGy[0].append(entry as! Double)}
            for entry in array[1] as! NSArray {self.arrGy[1].append(entry as! Double)}
            for entry in array[2] as! NSArray {self.arrGy[2].append(entry as! Double)}
            for entry in array[3] as! NSArray {self.arrGy[3].append(entry as! Double)}
            self.updateGraph()
            self.received = self.received + 1
            self.numFR.text = "\(self.arrGy[0].count)"
            if (self.received==self.goal_received) {
                self.send_data()
                print("sent")
            }
        }
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if WCSession.isSupported() {
            session = WCSession.default
            session?.delegate = self
            session?.activate()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {}
    
    func sessionDidBecomeInactive(_ session: WCSession) {}
    
    func sessionDidDeactivate(_ session: WCSession) {}
    
}

