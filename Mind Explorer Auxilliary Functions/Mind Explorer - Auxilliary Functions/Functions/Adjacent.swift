//
//  Adjacent.swift
//  Neural Network Viewer - Auxilliary Functions
//
//  Created by William Moyle on 24/07/2015.
//  Copyright (c) 2015 Will Moyle. All rights reserved.
//

import Foundation

func maxDist(vertexData: [[Double]]) -> Double {
    var tempMaxLength:Double = 0
    var dist:Double
    var sqrX:Double
    var sqrY:Double
    var sqrZ:Double
    for var i = 0; i < vertexData.count; i += 2 {
        sqrX = pow(vertexData[i][0] - vertexData[i+1][0], 2)
        sqrY = pow(vertexData[i][1] - vertexData[i+1][1], 2)
        sqrZ = pow(vertexData[i][2] - vertexData[i+1][2], 2)
        dist = sqrt(sqrX + sqrY + sqrZ)
        tempMaxLength = maxElement([tempMaxLength, dist])
    }
    return tempMaxLength
}

func minDist(vertexData: [[Double]]) -> Double {
    var tempMinLength:Double = 2
    var dist:Double
    var sqrX:Double
    var sqrY:Double
    var sqrZ:Double
    for var i = 0; i < vertexData.count; i++ {
        sqrX = pow(vertexData[i][0] - vertexData[i][3], 2)
        sqrY = pow(vertexData[i][1] - vertexData[i][4], 2)
        sqrZ = pow(vertexData[i][2] - vertexData[i][5], 2)
        dist = sqrt(sqrX + sqrY + sqrZ)
        tempMinLength = minElement([tempMinLength, dist])
    }
    return tempMinLength
}

func maxXGap(vertexData: [[Double]], maxLength: Double) -> Int {
    var xMaxEl:Int = 0
    var cont:Bool = true
    
    for var i = 0; i < vertexData.count; i++ {
        for var j = i; cont && j < vertexData.count; j++ {
            if vertexData[j][0] - vertexData[i][0] > maxLength {
                xMaxEl = maxElement([xMaxEl, j - i])
                cont = false
            }
        }
        cont = true
    }
    return xMaxEl
}

func removeDuplicates(var adjVert: [[Int]]) -> [[Int]] {
    for var i = 0; i < adjVert.count; i++ {
        adjVert[i] = removeDuplicatesAux(adjVert[i])
        for var j = 0; j < adjVert[i].count; j++ {
            if adjVert[i][j] == i {
                adjVert[i].removeAtIndex(j)
                j--
            }
        }
    }
    return adjVert
}

func removeDuplicatesAux(array: [Int]) -> [Int] {
    var encountered = Set<Int>()
    var result: [Int] = []
    for value in array {
        if !encountered.contains(value) {
            encountered.insert(value)
            result.append(value)
        }
    }
    return result
}

func convertToOneArray(adjVert:[[Int]]) -> [Int] {
    var adjVertSimple:[Int] = []
    adjVertSimple += adjVert[0]
    for var i = 1; i < adjVert.count; i++ {
        adjVertSimple += [-1]
        adjVertSimple += adjVert[i]
    }
    return adjVertSimple
}

func withinDist(i: [Double], j: [Double]) -> Bool {
    var xDist = pow(i[0] - j[0],2)
    var yDist = pow(i[1] - j[1],2)
    var zDist = pow(i[2] - j[2],2)
    return sqrt(xDist+yDist+zDist) < 0.003
}

func calculateAdjacentVertices(oldVertexData: [Double], path:String) {
    
    
    var vertexData:[[Double]] = []
    for var i = 0; i < oldVertexData.count; i+=3 {
        vertexData += [[oldVertexData[i], oldVertexData[i+1], oldVertexData[i+2]]]
    }
    
    var start:Int
    var end:Int
    var numVert:Int = vertexData.count
    var adjVert = [[Int]](count: numVert, repeatedValue: [])
    var firstInd:Int
    var lastInd:Int
    var maxLength:Double = maxDist(vertexData)
    println("Maximum length per line: \(maxLength)")
    var maxGap:Int = maxXGap(vertexData, maxLength)
    println("Maximum X gap: \(maxGap)")
    
    
    var iterations:Int = numVert / 5000
    
    for var k = 0; k < iterations; k++ {
        firstInd = k * 5000
        lastInd = minElement([firstInd + 5000,numVert])
        
        for var i = firstInd; i < lastInd; i++ {
            start = maxElement([0, i-maxGap])
            end = minElement([numVert, i+maxGap])
            for var j = start; j < end; j++ {
                if withinDist(vertexData[i], vertexData[j]) {
                    adjVert[i] += [j]
                    if j % 2 == 0 {
                        adjVert[i] += [j + 1]
                    }
                    else {
                        adjVert[i] += [j - 1]
                    }
                }
            }
        }
        println(lastInd)
    }
    
    adjVert = removeDuplicates(adjVert)
    
    var adjVertSimple:[Int] = convertToOneArray(adjVert)
    
    archiveArray(adjVertSimple, path)
    
    println(adjVert)
    println(adjVertSimple)
}
