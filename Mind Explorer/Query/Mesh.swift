//  MIND EXPLORER
//  MSC COMPUTING SCIENCE - INDIVIDUAL PROJECT - IMPERIAL COLLEGE LONDON
//  Author: WILLIAM MOYLE
//  Last updated: 22/07/15

//  MESH CLASS DECLARATION FILE

//  This class creates the Neocortex model for rendering, along with
//  the cubes for rendering queries and the axes

import Foundation
import Metal
import QuartzCore

class Mesh {
    //-------------------------------------------------------------------------
    //-------------------- ATTRIBUTES -----------------------------------------
    //-------------------------------------------------------------------------
    
    // All vertex data for rendering, including RGBA
    var vertexData:[Float] = []
    
    // Mesh data
    let meshColour:[Float] = [0.0, 0.0, 1.0, 0.1]
    let backgroundColour = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    
    // Elements for Metal rendering: buffers and device
    var vertexBuffer: MTLBuffer?
    var uniformBuffer: MTLBuffer?
    var device: MTLDevice
    var dataSize:Int = 0
    var results:NSMutableArray
    var isCube:Bool
    var dist:Float
    var center:[Float]
    var scale:Float
    var add:Bool = true
    var iteration:Int = 0
    var query:[Float]
    var complete:Bool = false
    
    var totalNumMesh:Int
    var currentNumMesh:Int
    var numVert:Int
    
    var start:NSDate = NSDate()
    var end:NSDate = NSDate()

    //-------------------------------------------------------------------------
    //----------------------- METHODS -----------------------------------------
    //-------------------------------------------------------------------------
    
    // START OF FUNCTION: init
    // Generates all vertex data from file "filename" and creates buffers
    init(device: MTLDevice, numMesh: Int, query:[Float],
        results: NSMutableArray, isCube: Bool) {
            
        start = NSDate()
        self.device = device
        self.totalNumMesh = numMesh
        self.currentNumMesh = 0
        self.query = query
        self.results = results
        self.isCube = isCube
        self.dist = query[3]-query[0]
        self.center = [ (query[3] + query[0]) / 2.0,
            (query[4]+query[1]) / 2.0,
            (query[5]+query[2]) / 2.0]
        self.scale = 6.0 / dist
        
        self.vertexData = [Float](count: totalNumMesh * 3 * 7,
            repeatedValue: 0.0)
        self.numVert = vertexData.count / 7
        
        dataSize = vertexData.count * sizeofValue(vertexData[0])
        
        vertexBuffer = device.newBufferWithBytes(vertexData,
            length: dataSize, options: nil)
    }
    // END OF FUNCTION
    
    
    
    // START OF FUNCTION: render
    // Called by ViewController - renders the appropriate view given parameters
    func render(commandQueue: MTLCommandQueue, pipelineState: MTLRenderPipelineState,
        drawable: CAMetalDrawable, parentModelViewMatrix: Matrix4,
        projectionMatrix: Matrix4, depthStencilState: MTLDepthStencilState){
            if currentNumMesh < totalNumMesh {
                iteration++
                for var i = 0; i < 6000 && currentNumMesh < totalNumMesh; i++ {
                    var newData:[Float] = []
                    add = true
                    for var j = 0; j < 3 && add; j++ {
                        newData += [(results[currentNumMesh * 9 + j * 3].floatValue - center[0]) * scale,
                            (results[currentNumMesh * 9 + j * 3 + 1].floatValue - center[1]) * scale,
                            (results[currentNumMesh * 9 + j * 3 + 2].floatValue - center[2]) * scale]
                        newData += [0.0, 0.0, meshColour[2], 1.0]
                        if !isCube {
                            let vertDist:Float = sqrtf(powf(newData[j * 7], 2)
                                + powf(newData[j * 7 + 1], 2)
                                + powf(newData[j * 7 + 2], 2))
                            if vertDist > 3.5 {
                                add = false
                            }
                        }
                    }
                    if add {
                        for var j = 0; j < 21; j++ {
                            vertexData[currentNumMesh * 21 + j] = newData[j]
                        }
                    }
                    currentNumMesh++
                }
            }
            if !complete && currentNumMesh == totalNumMesh {
                let end = NSDate()
                let interval:Double = end.timeIntervalSinceDate(start)
                println("Time to render results: \(interval)")
                complete = true
            }
            
            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.colorAttachments[0].loadAction = .Clear
            renderPassDescriptor.colorAttachments[0].clearColor = backgroundColour
            renderPassDescriptor.colorAttachments[0].storeAction = .Store
            
            let commandBuffer = commandQueue.commandBuffer()
            
            let renderEncoderOpt =
            commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
            if let renderEncoder = renderEncoderOpt {
                vertexBuffer = device.newBufferWithBytes(vertexData,
                    length: dataSize, options: nil)
                renderEncoder.setTriangleFillMode(.Fill)
                renderEncoder.setCullMode(MTLCullMode.Front)
                renderEncoder.setRenderPipelineState(pipelineState)
                renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 0)
                renderEncoder.setDepthStencilState(depthStencilState)
                
                // Creates a buffer with shared GPU/CPU memory
                uniformBuffer = device.newBufferWithLength(
                    sizeof(Float) * Matrix4.numberOfElements() * 2, options: nil)
                var bufferPointer = uniformBuffer?.contents()
                
                // Copy matrix data into buffer
                memcpy(bufferPointer!, parentModelViewMatrix.raw(),
                    sizeof(Float)*Matrix4.numberOfElements())
                memcpy(bufferPointer! + sizeof(Float)*Matrix4.numberOfElements(),
                    projectionMatrix.raw(), sizeof(Float)*Matrix4.numberOfElements())
                
                // Pass buffer to vertex shader
                renderEncoder.setVertexBuffer(self.uniformBuffer, offset: 0, atIndex: 1)
                
                // Draw mesh
                renderEncoder.drawPrimitives(.Triangle,
                    vertexStart: 0,
                    vertexCount: numVert)
                
                renderEncoder.endEncoding()
            }
            commandBuffer.presentDrawable(drawable)
            commandBuffer.commit()
    }
    // END OF FUNCTION
}