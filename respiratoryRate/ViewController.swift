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
    
    // # segments of data received from watch to make first full frame
    var fullFrame = 4
    
    // # FFT calculations completed in session
    var trial_num = 0
    
    // Segments received toward first full frame
    var segmentsReceived = 0
    
    // First full frame sent, begin FFT & sliding window
    var fullSent = false
    
    // # points in data array received
    var count = 0
    
    // # data points received
    var dataReceived = 0
    
    // Initializations
    var received = 0
    var arrGy: [[Double]] = [[Double](repeating: 0, count: 2048), [Double](repeating: 0, count: 2048), [Double](repeating: 0, count: 2048), [Double](repeating: 0, count: 2048)]
    var session : WCSession!
    
    var log = ""

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
    }
    
    func getBR(gyData: [[Double]], size: Int) -> Double {
        let breath_alg = BreathRateAlg(sampleRate: 100, log2N: Int(round(log2(Double(gyData[1].count)))), size: size)
        let br = breath_alg.getBreathRate(oneFrameArr: gyData)
        breath_alg.destroy()
        return br
    }
        
    func runFFT(size: Int) {
        let trial = [self.arrGy[1], self.arrGy[2], self.arrGy[3]]
        let br = self.getBR(gyData: trial, size: (size/2048))
        self.trial_num = self.trial_num + 1
        self.log = "\n TRIAL \(self.trial_num): \(br) \(size)" + self.log
        self.bpm_value.text = self.log
        
    }
    
    func update_arrGy(calculate: Bool, size: Int, makeSpace: Int, array: [[Double]]) {
        // Slide old data left, append new data
        let newGy0 = Array(self.arrGy[0][makeSpace..<size])
        let newGy1 = Array(self.arrGy[1][makeSpace..<size])
        let newGy2 = Array(self.arrGy[2][makeSpace..<size])
        let newGy3 = Array(self.arrGy[3][makeSpace..<size])
        self.arrGy = [newGy0,newGy1,newGy2,newGy3]
        for entry in array[0] as NSArray {self.arrGy[0].append(entry as! Double)}
        for entry in array[1] as NSArray {self.arrGy[1].append(entry as! Double)}
        for entry in array[2] as NSArray {self.arrGy[2].append(entry as! Double)}
        for entry in array[3] as NSArray {self.arrGy[3].append(entry as! Double)}
        
        if (calculate) {self.runFFT(size: size)}
    }
    
    func resize_arrGy(size: Int) {
        // Prepend existing data with zeroes to resize
        let oldGy0 = Array(self.arrGy[0])
        let oldGy1 = Array(self.arrGy[1])
        let oldGy2 = Array(self.arrGy[2])
        let oldGy3 = Array(self.arrGy[3])
        let zeroes = size/2
        self.arrGy = [[Double](repeating: 0, count: zeroes), [Double](repeating: 0, count: zeroes), [Double](repeating: 0, count: zeroes), [Double](repeating: 0, count: zeroes)]
        for entry in oldGy0 as NSArray {self.arrGy[0].append(entry as! Double)}
        for entry in oldGy1 as NSArray {self.arrGy[1].append(entry as! Double)}
        for entry in oldGy2 as NSArray {self.arrGy[2].append(entry as! Double)}
        for entry in oldGy3 as NSArray {self.arrGy[3].append(entry as! Double)}
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async() {
            // Instantaneous update
            let array = message["data"] as! NSArray
            self.count = (array[1] as! NSArray).count
            let makeSpace = (array[1] as! NSArray).count
            self.dataReceived = self.dataReceived + makeSpace
            
            if self.dataReceived > (Int(0.52*8192)) {
                if (self.arrGy[1].count < 8192) {
                    // Switch from 4096 to 8192
                    self.resize_arrGy(size: 8192)
                }
                // Start using the 8192 FFT. +/- 0.75 bpm accuracy.
                self.update_arrGy(calculate: true, size: 8192, makeSpace: makeSpace, array: array as! [[Double]])
            }
            else if self.dataReceived > (Int(0.52*4096)) {
                if (self.arrGy[1].count < 4096) {
                    // Switch from 2048 to 4096
                    self.resize_arrGy(size: 4096)
                }
                // Start using the 4096 FFT. +/- 1.5 bpm accuracy.
                self.update_arrGy(calculate: true, size: 4096, makeSpace: makeSpace, array: array as! [[Double]])
            }
            else if self.dataReceived > (Int(0.52*2048)) {
                // Start using the 2048 FFT. +/- 3.0 bpm accuracy.
                self.update_arrGy(calculate: true, size: 2048, makeSpace: makeSpace, array: array as! [[Double]])
            }
            else {
                // Start filling the 2048 FFT. Don't calculate yet.
                self.update_arrGy(calculate: false, size: 2048, makeSpace: makeSpace, array: array as! [[Double]])
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
    
    
    
    
    // Not sure if I will use this
    
    func updateGraph() {
        var lineChartEntryA = [ChartDataEntry]()
        //        var lineChartEntryB = [ChartDataEntry]()
        //        var lineChartEntryC = [ChartDataEntry]()
        let top = min(arrGy[0].count, 20000)
        for i in 0..<top {
            let valueA = ChartDataEntry(x: Double(i), y:arrGy[1][i])
            //            let valueB = ChartDataEntry(x: Double(i), y:arrGy[2][i])
            //            let valueC = ChartDataEntry(x: Double(i), y:arrGy[3][i])
            lineChartEntryA.append(valueA)
            //            lineChartEntryB.append(valueB)
            //            lineChartEntryC.append(valueC)
        }
        let line1 = LineChartDataSet(values: lineChartEntryA, label: "Number")
        line1.colors = [NSUIColor.green]
        //        let line2 = LineChartDataSet(values: lineChartEntryB, label: "Number")
        //        line2.colors = [NSUIColor.blue]
        //        let line3 = LineChartDataSet(values: lineChartEntryC, label: "Number")
        //        line3.colors = [NSUIColor.red]
        let data = LineChartData()
        data.addDataSet(line1)
        //        data.addDataSet(line2)
        //        data.addDataSet(line3)
        chtChart.data = data
        chtChart.chartDescription?.text = "My awesome chart"
    }

    
}

