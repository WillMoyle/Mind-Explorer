//  MIND EXPLORER
//  MSC COMPUTING SCIENCE - INDIVIDUAL PROJECT - IMPERIAL COLLEGE LONDON
//  Author: WILLIAM MOYLE
//  Last updated: 22/07/15

//  GEOMETRY CLASS DECLARATION FILE

//  Superclass for axis and cube subclasses holding basic geometry data

import Foundation

class Geometry {
    
    //-------------------------------------------------------------------------
    //-------------------- ATTRIBUTES -----------------------------------------
    //-------------------------------------------------------------------------
    var vertexData:[Float]
    var colour: [Float]
    var originalSize: Float
    var size: Float
    var center: [Float]
    var coreData: [Float]
    
    //-------------------------------------------------------------------------
    //-------------------- METHODS --------------------------------------------
    //-------------------------------------------------------------------------
    
    // Superclass initialiser called by all subclasses
    init (scale: Float, col: [Float]) {
        self.size = scale
        self.originalSize = scale
        self.colour = col
        self.vertexData = []
        self.center = [0.0, 0.0, 0.0]
        self.coreData = []
    }
    
    
    // START OF FUNCTION: addVertices
    // Given and array of vertices arrays, adds to vertexData
    func addVertices(vertices: [[Float]]) {
        for vertex in vertices {
            vertexData += vertex
            vertexData += colour
        }
    }
    // END OF FUNCTION
    
    
    // START OF FUNCTION: numVert
    // Returns the number of vertices in object
    func numVert() -> Int {
        return vertexData.count / 7
    }
    // END OF FUNCTION
    
    
    // START OF FUNCTION: update
    // Updates the objects size and scale given GeometryData object
    func update(info: GeometryData) {
        size = info.scale
        center = [info.x, info.y, info.z]
        for var i = 0; i < vertexData.count; i += 7 {
            vertexData[i]   = (coreData[i]   * size) + center[0]
            vertexData[i+1] = (coreData[i+1] * size) + center[1]
            vertexData[i+2] = (coreData[i+2] * size) + center[2]
        }
    }
    // END OF FUNCTION
}