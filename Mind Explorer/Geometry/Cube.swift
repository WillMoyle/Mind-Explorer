//  MIND EXPLORER
//  MSC COMPUTING SCIENCE - INDIVIDUAL PROJECT - IMPERIAL COLLEGE LONDON
//  Author: WILLIAM MOYLE
//  Last updated: 22/07/15

//  CUBE CLASS DECLARATION FILE

//  This class creates the cube model used for performing range queries

import Foundation

class Cube: Geometry {

    
    //-------------------------------------------------------------------------
    //-------------------- METHODS --------------------------------------------
    //-------------------------------------------------------------------------
    override init (scale: Float, col: [Float]) {
        super.init(scale: scale, col: col)

        let A = [-1*size,    size,    size]
        let B = [-1*size, -1*size,    size]
        let C = [   size, -1*size,    size]
        let D = [   size,    size,    size]
        
        let Q = [-1*size,    size, -1*size]
        let R = [-1*size, -1*size, -1*size]
        let S = [   size, -1*size, -1*size]
        let T = [   size,    size, -1*size]

        // Add vertices for solid cube
        /*
        addVertices([A,B,C,A,C,D]) // Front
        addVertices([R,T,S,Q,T,R]) // Back
        addVertices([Q,R,B,Q,B,A]) // Left
        addVertices([D,C,T,T,C,S]) // Right
        addVertices([Q,A,D,Q,D,T]) // Top
        addVertices([C,R,S,B,R,C]) // Bottom
        */
        
        // Add vertices for cube frame
        addVertices([A,B,B,C,C,D,D,A]) // Front
        addVertices([Q,R,R,S,S,T,T,Q]) // Back
        addVertices([A,Q,B,R,C,S,D,T]) // Joins
        addVertices([A,C,B,D,Q,S,R,T])
        addVertices([A,R,Q,B,T,C,D,S])
        addVertices([Q,D,T,A,R,C,B,S])
        
        coreData += vertexData
    }
    
    // START OF FUNCTION: queryData
    // Returns the coordinates of diagonally opposite corners for running queries
    func queryData() -> [Float] {
        let queryData:[Float] = [vertexData[63], vertexData[64], vertexData[65],
            vertexData[35], vertexData[36], vertexData[37]]
        return queryData
    }
    // END OF FUNCTION
}