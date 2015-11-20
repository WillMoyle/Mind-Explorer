//  MIND EXPLORER
//  MSC COMPUTING SCIENCE - INDIVIDUAL PROJECT - IMPERIAL COLLEGE LONDON
//  Author: WILLIAM MOYLE
//  Last updated: 22/07/15

//  SPHERE CLASS DECLARATION FILE

//  This class creates the isosphere model used for source of message propogation

import Foundation

class Sphere: Geometry {

    override init (scale: Float, col: [Float]) {
        super.init(scale: scale, col: col)
        
        let level:Int = 2
        let t:Float = (1.0 + sqrtf(5.0)) / 2.0
        let s:Float = sqrt(1 + powf(t,2)) / size
        
        var vertices:[[Float]] =
            [[-1, t, 0.0],
            [ 1, t, 0.0],
            [-1,-t, 0.0],
            [ 1,-t, 0.0],
            [ 0.0,-1, t],
            [ 0.0, 1, t],
            [ 0.0,-1,-t],
            [ 0.0, 1,-t],
            [ t, 0.0,-1],
            [ t, 0.0, 1],
            [-t, 0.0,-1],
            [-t, 0.0, 1]]
        
        for var i = 0; i < vertices.count; i++ {
            for var j = 0; j < vertices[i].count; j++ {
                vertices[i][j] = vertices[i][j] / s
            }
        }
        
        addVertices([vertices[0], vertices[5], vertices[11]])
        addVertices([vertices[0], vertices[1], vertices[5]])
        addVertices([vertices[0], vertices[7], vertices[1]])
        addVertices([vertices[0], vertices[10], vertices[7]])
        addVertices([vertices[0], vertices[11], vertices[10]])
        addVertices([vertices[1], vertices[9], vertices[5]])
        addVertices([vertices[5], vertices[4], vertices[11]])
        addVertices([vertices[11], vertices[2], vertices[10]])
        addVertices([vertices[10], vertices[6], vertices[7]])
        addVertices([vertices[7], vertices[8], vertices[1]])
        addVertices([vertices[3], vertices[4], vertices[9]])
        addVertices([vertices[3], vertices[2], vertices[4]])
        addVertices([vertices[3], vertices[6], vertices[2]])
        addVertices([vertices[3], vertices[8], vertices[6]])
        addVertices([vertices[3], vertices[9], vertices[8]])
        addVertices([vertices[4], vertices[5], vertices[9]])
        addVertices([vertices[2], vertices[11], vertices[4]])
        addVertices([vertices[6], vertices[10], vertices[2]])
        addVertices([vertices[8], vertices[7], vertices[6]])
        addVertices([vertices[9], vertices[1], vertices[8]])
        
        for var i = 0; i < level; i++ {
            
            var newVertexData:[Float] = []
            
            for var j = 0; j < vertexData.count; j += 21 {
                let v1:[Float] = [vertexData[j], vertexData[j+1], vertexData[j+2]]
                let v2:[Float] = [vertexData[j+7], vertexData[j+8], vertexData[j+9]]
                let v3:[Float] = [vertexData[j+14], vertexData[j+15], vertexData[j+16]]
                
                let a:[Float] = getMidPoint(v1, p2: v2)
                let b:[Float] = getMidPoint(v2, p2: v3)
                let c:[Float] = getMidPoint(v3, p2: v1)
                
                newVertexData += (v1 + colour)
                newVertexData += (a + colour)
                newVertexData += (c + colour)
                newVertexData += (v2 + colour)
                newVertexData += (b + colour)
                newVertexData += (a + colour)
                newVertexData += (v3 + colour)
                newVertexData += (c + colour)
                newVertexData += (b + colour)
                newVertexData += (a + colour)
                newVertexData += (b + colour)
                newVertexData += (c + colour)
            }
            
            vertexData = newVertexData
        }
        coreData += vertexData
    }
    
    
    func getMidPoint(p1:[Float], p2:[Float]) -> [Float] {
        var mid:[Float] = [(p1[0] + p2[0]) / 2, (p1[1] + p2[1]) / 2, (p1[2] + p2[2]) / 2]
        var scale:Float = size / sqrt(powf(mid[0], 2) + powf(mid[1],2) + powf(mid[2],2))
        if powf(mid[0], 2) + powf(mid[1],2) + powf(mid[2],2) == 0 {
            return [0,0,0]
        }
        return [mid[0] * scale, mid[1] * scale, mid[2] * scale]
    }
}