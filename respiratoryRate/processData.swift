//
//  processData.swift
//  respiratoryRate
//
//  Created by Leah Womelsdorf on 8/24/18.
//  Copyright © 2018 Leah Womelsdorf. All rights reserved.
//

import UIKit
import SwiftyDropbox

class processData: UIViewController {
    
    // TODO: Change to your OAuth2 token to send to your Dropbox
    var client = DropboxClient(accessToken: "O0rjYSZUS9AAAAAAAAACTlsFwgxufsT5OkM5oa7wImJIbkAIQr6f7r3xf6AzQQ3g")
    
    // Size of window for averaging filter
    // Size of 150 based on 1 breath for max breathing rate 40 bpm (1.5 s/breath, 100 fps)
    let windowSize = 150
    
    var zScores: [[Double]] = [[], [], [], []]
    var avgWin: [[Double]] = [[], [], [], []]
    
    func make_Z() {
        let count = arrGy[0].count
        var sumX = 0.0
        var sumY = 0.0
        var sumZ = 0.0
        for i in 0..<count {
            sumX = sumX + arrGy[1][i]
            sumY = sumY + arrGy[2][i]
            sumZ = sumZ + arrGy[3][i]
        }
        let meanX = sumX/Double(count)
        let meanY = sumY/Double(count)
        let meanZ = sumZ/Double(count)
        var stdX = 0.0
        var stdY = 0.0
        var stdZ = 0.0
        for i in 0..<count {
            let powX = pow((arrGy[1][i] - meanX), 2)
            let powY = pow((arrGy[2][i] - meanY), 2)
            let powZ = pow((arrGy[3][i] - meanZ), 2)
            stdX = stdX + powX
            stdY = stdY + powY
            stdZ = stdZ + powZ
        }
        stdX = pow((stdX / Double(count+1)), 0.5)
        stdY = pow((stdY / Double(count+1)), 0.5)
        stdZ = pow((stdZ / Double(count+1)), 0.5)
        for entry in arrGy[0] as NSArray {
            self.zScores[0].append(entry as! Double)
        }
        for entry in arrGy[1] as NSArray {
            let zX = ((entry as! Double) - meanX)/stdX
            self.zScores[1].append(zX)
        }
        for entry in arrGy[2] as NSArray {
            let zY = ((entry as! Double) - meanY)/stdY
            self.zScores[2].append(zY)
        }
        for entry in arrGy[3] as NSArray {
            let zZ = ((entry as! Double) - meanZ)/stdZ
            self.zScores[3].append(zZ)
        }
    }
    
    func make_A() {
        let count = arrGy[0].count
        
        for i in 0..<(count-self.windowSize) {
            var sumX = 0.0
            var sumY = 0.0
            var sumZ = 0.0
            for j in i..<(i+self.windowSize) {
                sumX = sumX + zScores[1][j]
                sumY = sumY + zScores[2][j]
                sumZ = sumZ + zScores[3][j]
            }
            let avX = sumX/Double(self.windowSize)
            let avY = sumY/Double(self.windowSize)
            let avZ = sumZ/Double(self.windowSize)
            avgWin[0].append(arrGy[0][i])
            avgWin[1].append(avX)
            avgWin[2].append(avY)
            avgWin[3].append(avZ)
        }
    }
    
    func send_G() {
        let time = "\(CFAbsoluteTimeGetCurrent())"
        var csvText = "Time,gyX,gyY,gyZ\n"
        let count = arrGy[0].count
        for i in 0..<count {
            let newLine = "\(arrGy[0][i]),\(arrGy[1][i]),\(arrGy[2][i]),\(arrGy[3][i])\n"
            csvText.append(newLine)
        }
        let fileData = csvText.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        client.files.upload(path: "/respiratoryRate/dataGy/\(time).csv", input: fileData)
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
    
    func send_Z() {
        let time = "\(CFAbsoluteTimeGetCurrent())"
        var csvText = "Time,zscoreX,zscoreY,zscoreZ\n"
        let count = zScores[0].count
        for i in 0..<count {
            let newLine = "\(zScores[0][i]),\(zScores[1][i]),\(zScores[2][i]),\(zScores[3][i])\n"
            csvText.append(newLine)
        }
        let fileData = csvText.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        client.files.upload(path: "/respiratoryRate/zScores/\(time).csv", input: fileData)
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
    
    func send_A() {
        let time = "\(CFAbsoluteTimeGetCurrent())"
        var csvText = "Time,zscoreX,zscoreY,zscoreZ\n"
        let count = avgWin[0].count
        for i in 0..<count {
            let newLine = "\(avgWin[0][i]),\(avgWin[1][i]),\(avgWin[2][i]),\(avgWin[3][i])\n"
            csvText.append(newLine)
        }
        let fileData = csvText.data(using: String.Encoding.utf8, allowLossyConversion: false)!
        client.files.upload(path: "/respiratoryRate/avGs/\(time).csv", input: fileData)
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
    
    
    
    
    
    var arrGy: [[Double]] = [[], [], [], []]
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

  
}
