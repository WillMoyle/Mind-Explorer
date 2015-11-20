//
//  Sorting.swift
//  Neural Network Viewer - Auxilliary Functions
//
//  Created by William Moyle on 24/07/2015.
//  Copyright (c) 2015 Will Moyle. All rights reserved.
//

import Foundation

func comp0(a1: [Double], a2: [Double]) -> Bool {
    return a1[0] < a2[0]
}

func comp1(a1: [Double], a2: [Double]) -> Bool {
    return a1[1] < a2[1]
}

func comp2(a1: [Double], a2: [Double]) -> Bool {
    return a1[2] < a2[2]
}

func comp3(a1: [Double], a2: [Double]) -> Bool {
    return a1[3] < a2[3]
}

func comp4(a1: [Double], a2: [Double]) -> Bool {
    return a1[4] < a2[4]
}

func comp5(a1: [Double], a2: [Double]) -> Bool {
    return a1[5] < a2[5]
}

func orderVertices(input:[[Double]]) -> [[Double]] {
    var temp5 = sorted(input, comp5)
    println("Sorted 1")
    var temp4 = sorted(temp5, comp4)
    println("Sorted 2")
    var temp3 = sorted(temp4, comp3)
    println("Sorted 3")
    var temp2 = sorted(temp3, comp2)
    println("Sorted 4")
    var temp1 = sorted(temp2, comp1)
    println("Sorted 5")
    return sorted(temp1, comp0)
}