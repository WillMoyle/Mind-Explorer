//  MIND EXPLORER
//  MSC COMPUTING SCIENCE - INDIVIDUAL PROJECT - IMPERIAL COLLEGE LONDON
//  Author: WILLIAM MOYLE
//  Last updated: 22/07/15

//  NEOCORTEX CLASS DECLARATION FILE

//  This class creates and stores the high level neocortex model from the saved file

import Foundation

class Neocortex: Geometry {
    
    //-------------------------------------------------------------------------
    //-------------------- ATTRIBUTES -----------------------------------------
    //-------------------------------------------------------------------------
    var adjVert:[[Int]] = [[]]
    var unarchivedVertexData:[Float] = []
    
    //-------------------------------------------------------------------------
    //-------------------- METHODS --------------------------------------------
    //-------------------------------------------------------------------------
    init (col: [Float], filename: String) {
        super.init(scale: 0, col: col)
        
        // Retrieve neocortex vertex data from file
        let path = NSBundle.mainBundle().pathForResource(filename, ofType: "")
        self.unarchivedVertexData = NSKeyedUnarchiver.unarchiveObjectWithFile(path!) as! [Float]
        var count:Int = unarchivedVertexData.count
        for var i = 0; i < count; i += 3 {
            vertexData += [unarchivedVertexData[i], unarchivedVertexData[i+1], unarchivedVertexData[i+2]]
            vertexData += colour
        }

        // Retrieve adjacent vertex data from file
        let adj_path = NSBundle.mainBundle().pathForResource(filename + "_adj", ofType: "")
        adjVert = NSKeyedUnarchiver.unarchiveObjectWithFile(adj_path!) as! [[Int]]
    }
}
