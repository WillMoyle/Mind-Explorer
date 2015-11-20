//  MIND EXPLORER
//  MSC COMPUTING SCIENCE - INDIVIDUAL PROJECT - IMPERIAL COLLEGE LONDON
//  Author: WILLIAM MOYLE
//  Last updated: 22/07/15

//  GEOMETRYDATA CLASS DECLARATION FILE

//  This class holds location, orientation and size data for
//  neocortex models or cubes

import Foundation

struct GeometryData {
    //-------------------------------------------------------------------------
    //-------------------- ATTRIBUTES -----------------------------------------
    //-------------------------------------------------------------------------
    var x:Float
    var y:Float
    var z:Float
    var pitch:Float
    var roll:Float
    var yaw:Float
    var scale:Float
    
    //-------------------------------------------------------------------------
    //---------------------- METHODS ------------------------------------------
    //-------------------------------------------------------------------------
    init() {
        x = 0.0
        y = 0.0
        z = 0.0
        pitch = 0.0
        roll = 0.0
        yaw = 0.0
        scale = 1.0
    }
}