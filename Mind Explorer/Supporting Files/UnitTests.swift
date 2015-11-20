//  NEURAL NETWORK VIEWER
//  MSC COMPUTING SCIENCE - INDIVIDUAL PROJECT - IMPERIAL COLLEGE LONDON
//  Author: WILLIAM MOYLE
//  Last updated: 22/07/15

//  UNITTESTS CLASS DECLARATION FILE

//  This class is used to perform unit tests on the Mind Explorer program.
//  Tests are activated by changing the boolean "unitTests" in 
//  "ViewController.swift" to true.

import Foundation
import QuartzCore

class UnitTests {

    var numTests:Int = 0
    var numSuccess:Int = 0
    
    init() {}
    
    func beginTest(view:ViewController) {
        println("START OF MIND EXPLORER UNIT TESTS:")
        
        // TEST 1
        performTest(view.neocortex.neocortex.numVert() == 500000,
            description: "neocortex data load")
        
        // TEST 2
        performTest(view.neocortex.vertexData.count == ((view.neocortex.neocortex.numVert() + 1050) * 7),
            description: "model vertex data load")
        
        // TEST 3
        performTest(view.neocortex.neocortex.adjVert.count == 500000,
            description: "adjacent vertices list load")
        
        // TEST 4
        performTest(view.neocortex.activeVert.count == 0,
            description: "instantiate active vertices")
        
        // TEST 5
        view.neocortex.sphere.size *= 10
        view.neocortex.messageInitialSearch()
        performTest(view.neocortex.activeVert.count == 32,
            description: "initial message search")
        
        // TEST 6
        view.neocortex.messageIterate()
        performTest(view.neocortex.activeVert.count == 40,
            description: "first message iteration")
        
        // TEST 7
        view.neocortex.messageIterate()
        performTest(view.neocortex.activeVert.count == 56,
            description: "second message iteration")
        
        // TEST 8
        performTest(!view.neocortex.withinSphere(0),
            description: "'withinSphere' function for vertex out of sphere")
        
        // TEST 9
        performTest(view.neocortex.withinSphere(116056),
            description: "'withinSphere' function for vertex within sphere")
        
        // TEST 10
        performTest(!view.neocortex.withinCube(0, center: [0,0,0], halfEdge: 0.1),
            description: "'withinCube' function for vertex out of cube")
        
        // TEST 11
        performTest(view.neocortex.withinCube(111564, center: [0,0,0], halfEdge: 1),
            description: "'withinCube' function for vertex within cube")

        // TEST 12
        view.neocortex.restoreNeocortexColour()
        performTest(view.neocortex.vertexData[111564 * 7 + 3] == 0.7,
            description: "restoring neocortex colour")
        
        // TEST 13
        performTest(view.neocortex.cube.queryData() == [-0.06, -0.06, -0.06, 0.06, 0.06, 0.06],
            description: "restoring neocortex colour")
        
        // TEST 14
        performTest(view.neocortex.sphere.getMidPoint([1,1,1], p2: [-1,-1,-1])[0] == 0,
            description: "sphere midpoints, zero return values")
        
        // TEST 15
        performTest(view.neocortex.sphere.getMidPoint([1,1,1], p2: [1,1,-1])[2] == 0,
            description: "sphere midpoints, non-zero return values")
        
        // TEST 16
        view.query = [0,0,0,0,0,0]
        view.translateQuery()
        performTest(view.query[0] == 194.385,
            description: "query scaling")
    }
    
    func continueTests(view:ViewController) {
        // TEST 17
        performTest(view.FLATData!.results.count * 7 / 3 == view.mesh?.vertexData.count,
            description: "mesh instantiation")
        
        // TEST 18
        let count:Int = view.mesh!.vertexData.count
        var min:Float = 5000
        var max:Float = -5000
        for var i = 0; i < count; i += 7 {
            min = minElement([min, view.mesh!.vertexData[i], view.mesh!.vertexData[i+1], view.mesh!.vertexData[i+2]])
            max = maxElement([max, view.mesh!.vertexData[i], view.mesh!.vertexData[i+1], view.mesh!.vertexData[i+2]])
        }
        println("Min: \(min)")
        println("Max: \(max)")
        let test18:Bool = (min > -4.5 && max < 4.5)
        performTest(test18, description: "mesh rescaling")
        
        //TEST 19
        performTest(view.mesh!.vertexData[3] == view.mesh!.meshColour[0],
            description: "mesh colouring")
        
        println("UNIT TESTS COMPLETE")
        println("NUMBER OF SUCCESSFUL TESTS: \(numSuccess) / \(numTests) - \(Float(numSuccess) * Float(100)/Float(numTests))")
    }
    
    

    func performTest(result: Bool, description: String) {
        numTests++
        if result {
            println("\tTEST \(numTests): SUCCESS - " + description)
            numSuccess++
        }
        else {
            println("\tTEST \(numTests): FAILED - " + description)
        }
    }
}