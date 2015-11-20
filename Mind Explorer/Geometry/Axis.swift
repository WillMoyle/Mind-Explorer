//  MIND EXPLORER
//  MSC COMPUTING SCIENCE - INDIVIDUAL PROJECT - IMPERIAL COLLEGE LONDON
//  Author: WILLIAM MOYLE
//  Last updated: 22/07/15

//  AXIS CLASS DECLARATION FILE

//  This class creates the axes which can be viewed alongside the neocortex

import Foundation

class Axis: Geometry {
    
    //-------------------------------------------------------------------------
    //-------------------- ATTRIBUTES -----------------------------------------
    //-------------------------------------------------------------------------
    var numLineVert: Int = 6
    var numTriVert: Int = 36
    
    //-------------------------------------------------------------------------
    //-------------------- METHODS --------------------------------------------
    //-------------------------------------------------------------------------
    override init (scale: Float, col: [Float]) {
        super.init(scale: scale, col: col)
        
        let xMax = [ scale, 0, 0]
        let xMin = [-scale, 0, 0]
        let yMax = [0,  scale, 0]
        let yMin = [0, -scale, 0]
        let zMax = [0, 0,  scale]
        let zMin = [0, 0, -scale]
        
        // Add axis lines
        addAxisVert([xMax, xMin, yMax, yMin, zMax, zMin])
        
        // Add axis triangles
        addAxisVert([xMax, [scale*0.96, scale*0.02, 0], [scale*0.96, -scale*0.02, 0]])
        addAxisVert([xMax, [scale*0.96, 0, scale*0.02], [scale*0.96, 0, -scale*0.02]])
        addAxisVert([xMax, [scale*0.96, -scale*0.02, 0], [scale*0.96, scale*0.02, 0]])
        addAxisVert([xMax, [scale*0.96, 0, -scale*0.02], [scale*0.96, 0, scale*0.02]])
        
        addAxisVert([yMax, [scale*0.02, scale*0.96, 0], [-scale*0.02, scale*0.96, 0]])
        addAxisVert([yMax, [0, scale*0.96, scale*0.02], [0, scale*0.96, -scale*0.02]])
        addAxisVert([yMax, [-scale*0.02, scale*0.96, 0], [scale*0.02, scale*0.96, 0]])
        addAxisVert([yMax, [0, scale*0.96, -scale*0.02], [0, scale*0.96, scale*0.02]])
        
        addAxisVert([zMax, [scale*0.02, 0, scale*0.96], [-scale*0.02, 0, scale*0.96]])
        addAxisVert([zMax, [0, scale*0.02, scale*0.96], [0, -scale*0.02, scale*0.96]])
        addAxisVert([zMax, [-scale*0.02, 0, scale*0.96], [scale*0.02, 0, scale*0.96]])
        addAxisVert([zMax, [0, -scale*0.02, scale*0.96], [0, scale*0.02, scale*0.96]])
    }
    
    // START OF FUNCTION: addAxisVert
    // Differs from superclass function as axis vertices are not recoloured
    func addAxisVert(vertices: [[Float]]) {
        for vertex in vertices {
            vertexData += vertex
            vertexData += colour
        }
    }
    // END OF FUNCTION
}