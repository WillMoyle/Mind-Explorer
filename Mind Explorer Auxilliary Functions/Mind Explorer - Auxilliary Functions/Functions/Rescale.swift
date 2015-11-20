//
//  Rescale.swift
//  Neural Network Viewer - Auxilliary Functions
//
//  Created by William Moyle on 24/07/2015.
//  Copyright (c) 2015 Will Moyle. All rights reserved.
//

import Foundation

func drawVertices(path: String) -> [Double] {
    
    println("\t1...")
    
    var coords:[Double] = [0.0, 0.0, 0.0]
    var min:[Double] = [ 50000.0,  50000.0,  50000.0]
    var max:[Double] = [-50000.0, -50000.0, -50000.0]
    var dist:[Double] = [0.0, 0.0, 0.0]
    var center:[Double] = [0.0, 0.0, 0.0]
    var vertexData:[Double] = []
    
    let content = String(contentsOfFile: path, encoding: NSUTF8StringEncoding, error: nil)!
    
    println("\t2...")
    
    var dataStrArray = content.componentsSeparatedByString(" ")
    println("Count: \(dataStrArray.count)")
    
    println("\t3...")
    
    for var i = 0; i < dataStrArray.count - 1; i+=3 {
        
        coords = [(dataStrArray[i] as NSString).doubleValue,
            (dataStrArray[i+1] as NSString).doubleValue,
            (dataStrArray[i+2] as NSString).doubleValue]
        
        vertexData += coords
        
        min = [minElement([min[0], coords[0]]),
            minElement([min[1], coords[1]]),
            minElement([min[2], coords[2]])]
        max = [maxElement([max[0], coords[0]]),
            maxElement([max[1], coords[1]]),
            maxElement([max[2], coords[2]])]
    }
    
    println("\t4...")
    
    //println(min)
    //println(max)
    
    dist = [max[0]-min[0], max[1]-min[1], max[2]-min[2]]
    center = [(min[0]+max[0])/2.0, (min[1]+max[1])/2.0, (min[2]+max[2])/2.0]
    
    //println(dist)
    
    vertexData = rescale(maxElement(dist), center, vertexData)
    
    println("\t5...")
    
    return vertexData
}

func rescale(dist: Double, cent: [Double], var vertexData: [Double]) -> [Double] {
    
    let scale:Double = 8.0 / dist
    
    for var i = 0; i < vertexData.count; i+=3 {
        vertexData[i] = (vertexData[i] - cent[0]) * scale
        vertexData[i+1] = (vertexData[i+1] - cent[1]) * scale
        vertexData[i+2] = (vertexData[i+2] - cent[2]) * scale
    }
    
    //println("Center: \(cent)")
    //println("Scale: \(scale)")
    
    return vertexData
}