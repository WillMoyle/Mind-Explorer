//
//  Archiver.swift
//  Neural Network Viewer - Auxilliary Functions
//
//  Created by William Moyle on 24/07/2015.
//  Copyright (c) 2015 Will Moyle. All rights reserved.
//

import Foundation

func retrieveVertexDataFromNSArray(path: String) -> [[Double]]{
    var vertexNSArray:NSArray = NSArray(contentsOfFile: path)!
    var vertexData:[[Double]] = []
    for var i = 0; i < vertexNSArray.count; i += 6 {
        vertexData += [[vertexNSArray.objectAtIndex(i).doubleValue,
            vertexNSArray.objectAtIndex(i+1).doubleValue,
            vertexNSArray.objectAtIndex(i+2).doubleValue,
            vertexNSArray.objectAtIndex(i+3).doubleValue,
            vertexNSArray.objectAtIndex(i+4).doubleValue,
            vertexNSArray.objectAtIndex(i+5).doubleValue]]
    }
    return vertexData
}

func archiveVertexData(path: String, vertexData: [[Double]]) {
    var simpleVertexData:[Double] = []
    for var i = 0; i < vertexData.count; i++ {
        simpleVertexData += vertexData[i]
    }
    
    var success:Bool = NSKeyedArchiver.archiveRootObject(simpleVertexData, toFile: path)
    if success {
        println("Archived")
    }
}

func archiveVertexData(path: String, vertexData: [Double]) {
    var success:Bool = NSKeyedArchiver.archiveRootObject(vertexData, toFile: path)
    if success {
        println("Archived")
    }
}

func unarchiveVertexData(path: String) -> [[Double]]{
    var newVertexDataNS = NSKeyedUnarchiver.unarchiveObjectWithFile(path) as! NSArray
    
    var vertexData:[[Double]] = []
    
    for var i = 0; i < newVertexDataNS.count; i+=3 {
        vertexData += [[newVertexDataNS.objectAtIndex(i).doubleValue,
            newVertexDataNS.objectAtIndex(i+1).doubleValue,
            newVertexDataNS.objectAtIndex(i+2).doubleValue]]
    }
    
    return vertexData
}

func unarchiveVertexData(path: String) -> [Double]{
    var newVertexDataNS = NSKeyedUnarchiver.unarchiveObjectWithFile(path) as! NSArray
    
    var vertexData:[Double] = []
    
    for var i = 0; i < newVertexDataNS.count; i++ {
        vertexData += [newVertexDataNS.objectAtIndex(i).doubleValue]
    }
    
    return vertexData
}

func archiveArray(adjVertSimple: [Int], path: String) {
    var success:Bool = NSKeyedArchiver.archiveRootObject(adjVertSimple, toFile: path)
    if success {
        println("Archived")
    }
    
}