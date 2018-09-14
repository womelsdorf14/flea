//
//  BreathRateAlg.swift
//  BreathRateAlg
//
//  Created by Lynn on 2018/9/10.
//  Copyright © 2018 Lynne. All rights reserved.
//

/*
 input: type: [[Double]], shape: 3 x 2000 = 3 axis x 20 seconds x 100 sample_rate
 output: [Double], breathe per minute
 usage: check the test.swift below
 */

/* test.swift
 
 import Foundation
 
 //generate a sine wave for testing
 let n = 2000 // Should be power of two for the FFT, but it's 2000 in biowatch paper
 let frequency1 = 0.6 //0.13-0.66
 let phase1 = 0.0
 let amplitude1 = 8.0
 let seconds = 20.0
 let fps = Double(n)/seconds //100
 var sineWave = (0..<n).map {
 amplitude1 * sin(2.0 * .pi / fps * Double($0) * frequency1 + phase1)
 }
 
 let gyroData3SineWave = [sineWave,sineWave,sineWave]
 let breathRateAlg = BreathRateAlg(sampleRate: 100)
 var breathRate = breathRateAlg.getBreathRate(oneFrameArr: gyroData3SineWave)
 print(breathRate)//ground truth: sinWave = 24;
 */



import Foundation
import Accelerate

class BreathRateAlg {
    var sampleRate: Int
    var frameSize: Int
    var samples = [Double]()
    var AVE_FILTER_WINDOW_SIZE: Int
    var setup: FFTSetupD
    let BREATHING_FREQ_BAND: [Double] = [0.13, 0.66]
    
    init(sampleRate: Int) {
        self.sampleRate = sampleRate
        frameSize = sampleRate * 20 //seconds
        samples = [Double](repeating: 0, count: frameSize)
        AVE_FILTER_WINDOW_SIZE = Int(sampleRate/40)//assume 40 breath per minute, paper
        setup = vDSP_create_fftsetupD( 11, 0 )! /* supports up to 2048 (2**11) points  */
    }
    func getBreathRate(oneFrameArr: [[Double]]) -> Double {
        var br, br_cur, maxMagnitude, magnitude_cur: Double
        maxMagnitude = 0
        br = 0
        for oneAxis in oneFrameArr {//get max-magnitude breath rate from 3 axis
            (br_cur, magnitude_cur) = getBreathRateOneAxis(oneFrameArr: oneAxis)
            if magnitude_cur > maxMagnitude {
                br = br_cur
            }
        }
        return br
    }
    
    func getBreathRateOneAxis(oneFrameArr: [Double]) -> (Double, Double) {
        if oneFrameArr.count != frameSize {
            NSLog("frame size should be \(frameSize), but \(oneFrameArr.count) received")
            return (0.0, 0.0)
        }else {
            samples = oneFrameArr;
        }
        
        zscore()//normalization
        averagingFilter()//size changed
        
        //print("len \(samples.count), \(AVE_FILTER_WINDOW_SIZE)")
        let (br, magnitude) = fft()
        return (br, magnitude)
    }
    
    func zscore() {
        var mean = 0.0
        var std = 0.0
        vDSP_normalizeD(samples, 1, nil, 1,  &mean, &std, vDSP_Length(frameSize))
        std *= sqrt(Double(frameSize)/Double(frameSize - 1))
        if std != 0 {
            samples = samples.map { ($0 - mean) / std }
        }else {
            samples = samples.map { $0 - mean }//avoid dividing zero
        }
    }
    func averagingFilter() {
        if AVE_FILTER_WINDOW_SIZE == 0 {
            NSLog("no avg filter applied, because window size = \(frameSize)/40 = 0")
            return
        }else {
            samples = (0..<frameSize).compactMap { index -> (Double)? in
                if (0..<AVE_FILTER_WINDOW_SIZE).contains(index) { return nil }
                let range = index - AVE_FILTER_WINDOW_SIZE..<index
                let sum = samples[range].reduce(0, +)
                let result = Double(sum) / Double(AVE_FILTER_WINDOW_SIZE)
                return result
            }
        }
    }
    
    func fft () -> (Double, Double) {
        let cnt = samples.count
        var fftMagnitudes = [Double](repeating:0.0, count:cnt)
        var zeroArray = [Double](repeating:0.0, count:cnt)
        var splitComplexInput = DSPDoubleSplitComplex(realp: &samples, imagp: &zeroArray)
        
        vDSP_fft_zripD(self.setup, &splitComplexInput, 1, 11, FFTDirection(FFT_FORWARD));
        vDSP_zvmagsD(&splitComplexInput, 1, &fftMagnitudes, 1, vDSP_Length(cnt));
        
        // vDSP_zvmagsD returns squares of the FFT magnitudes, so take the root here
        var roots = [Double](repeating:0.0, count:fftMagnitudes.count)
        vvsqrt(&roots,fftMagnitudes , [Int32(fftMagnitudes.count)])
        
        //var normalizedValues = [Double](repeating:0.0, count:cnt)
        //vDSP_vsmulD(roots, vDSP_Stride(1), [2.0 / Double(cnt)], &normalizedValues, vDSP_Stride(1), vDSP_Length(cnt))
        
        //bandpass filter
        let bandwidth: Double =  Double(self.sampleRate) * 2
        let freqStep: Double = bandwidth / Double(fftMagnitudes.count)
        let freqBandIdx: [Int] = [Int(ceil(BREATHING_FREQ_BAND[0] / freqStep)), Int(ceil(BREATHING_FREQ_BAND[1] / freqStep))]
        let filteredArr = fftMagnitudes[freqBandIdx[0]..<freqBandIdx[1]]
        
        //print(freqStep, fftMagnitudes.count, cnt, freqBandIdx[0] , freqBandIdx[1] )
        //print("max freq no filter",fftMagnitudes.max()!, Double(fftMagnitudes.index(of: fftMagnitudes.max()!)!), Double(fftMagnitudes.index(of: fftMagnitudes.max()!)!) * freqStep)
        //print("max freq",filteredArr.max()!, filteredArr.index(of: filteredArr.max()!)!, Double(filteredArr.index(of: filteredArr.max()!)!) * freqStep)
        return (Double(filteredArr.index(of: filteredArr.max()!)!) * freqStep * 60.0, filteredArr.max()!)
    }
    
}


