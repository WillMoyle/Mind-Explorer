//  MIND EXPLORER
//  MSC COMPUTING SCIENCE - INDIVIDUAL PROJECT - IMPERIAL COLLEGE LONDON
//  Author: WILLIAM MOYLE
//  Last updated: 22/07/15

//  MODEL CLASS DECLARATION FILE

//  This class creates the Neocortex model for rendering, along with
//  the cubes for rendering queries and the axes

import Foundation
import Metal
import QuartzCore

class Model {
    //-------------------------------------------------------------------------
    //-------------------- ATTRIBUTES -----------------------------------------
    //-------------------------------------------------------------------------
    
    // All vertex data for rendering, including RGBA
    var vertexData:[Float] = []
    
    // Neocortex model data
    var neocortex:Neocortex
    let neocortexColour:[Float] = [0.7, 0.0, 0.0, 0.1]
    let backgroundColour = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1.0)
    var neocortexCurrentVertex:Int = 0
    
    // Elements for Metal rendering: buffers and device
    var vertexBuffer: MTLBuffer?
    var uniformBuffer: MTLBuffer?
    var device: MTLDevice
    var dataSize:Int = 0
    
    // Axis data
    let axisSize:Float = 4
    let axisColour:[Float] = [1.0, 1.0, 1.0, 1.0]
    var axis:Axis
    
    // Query cube data
    var cubeSize:Float = 0.06
    var cube:Cube
    
    // Message sphere data
    var sphereSize:Float = 0.1
    var sphere:Sphere
    
    // Sphere/cube colours
    var queryColour:[Float] = [0.0, 0.0, 1.0, 1.0]
    var isCube:Bool = true
    
    // Variables for modelling message propagation
    var adjacentVertices:[[Int]] = [[]]
    let steps:Int = 10
    var vertSteps:[Int] = []
    var startMessage:Bool = false
    var continueMessage:Bool = false
    var activeVert:[Int] = []
    
    
    //-------------------------------------------------------------------------
    //----------------------- METHODS -----------------------------------------
    //-------------------------------------------------------------------------
    
    
    // START OF FUNCTION: init
    // Generates all vertex data from file "filename" and creates buffers
    init(device: MTLDevice, filename: String) {
        let start = NSDate()
        self.device = device
        
        // Create NEOCORTEX
        self.neocortex = Neocortex(col: neocortexColour, filename: filename)
        
        // Create CUBE
        self.cube = Cube(scale: cubeSize, col: queryColour)
        
        // Create SPHERE
        self.sphere = Sphere(scale: sphereSize, col: queryColour)
        
        // Create AXES
        self.axis = Axis(scale: axisSize, col: axisColour)
        
        // Combine vertex data
        vertexData += neocortex.vertexData
        vertexData += cube.vertexData
        vertexData += sphere.vertexData
        vertexData += axis.vertexData
        
        // Create buffer with required vertex data
        dataSize = vertexData.count * sizeofValue(vertexData[0])
        vertexBuffer = device.newBufferWithBytes(vertexData,
            length: dataSize, options: nil)
        
        let end = NSDate()
        let interval:Double = end.timeIntervalSinceDate(start)
        println("Neocortex model creation time: \(interval)")
    }
    // END OF FUNCTION
    
    
    
    // START OF FUNCTION: render
    // Called by ViewController - renders the appropriate view given parameters
    func render(commandQueue: MTLCommandQueue, pipelineState: MTLRenderPipelineState,
        drawable: CAMetalDrawable, parentModelViewMatrix: Matrix4,
        projectionMatrix: Matrix4, queryMode: Bool, messageMode: Bool, drawAxis: Bool,
        depthStencilState: MTLDepthStencilState, isCube: Bool){
            
            let renderPassDescriptor = MTLRenderPassDescriptor()
            renderPassDescriptor.colorAttachments[0].texture = drawable.texture
            renderPassDescriptor.colorAttachments[0].loadAction = .Clear
            renderPassDescriptor.colorAttachments[0].clearColor = backgroundColour
            renderPassDescriptor.colorAttachments[0].storeAction = .Store
            
            let commandBuffer = commandQueue.commandBuffer()
            
            let renderEncoderOpt =
            commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
            if let renderEncoder = renderEncoderOpt {
                self.isCube = isCube

                // Iterate message propagation, if required
                if continueMessage {
                    messageIterate()
                }
                
                // Start message propagation, if required
                if startMessage {
                    messageInitialSearch()
                    startMessage = false
                    continueMessage = true
                }
                
                // Update position of cube
                for var i = 0; i < cube.vertexData.count; i += 7 {
                    for var j = 0; j < 3; j++ {
                        vertexData[neocortex.vertexData.count + i + j]
                            = cube.vertexData[i + j]
                    }
                }
                
                // Update position of sphere
                for var i = 0; i < sphere.vertexData.count; i += 7 {
                    for var j = 0; j < 3; j++ {
                        vertexData[neocortex.vertexData.count + cube.vertexData.count + i + j]
                            = sphere.vertexData[i + j]
                    }
                }
                
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
                
                // If required, draw axes
                if drawAxis {
                    renderEncoder.drawPrimitives(.Line,
                        vertexStart: neocortex.numVert() + cube.numVert() + sphere.numVert(),
                        vertexCount: axis.numLineVert)
                    renderEncoder.drawPrimitives(.Triangle,
                        vertexStart: neocortex.numVert() + cube.numVert() + sphere.numVert() + axis.numLineVert,
                        vertexCount: axis.numTriVert)
                }
                
                // If required, draw querying cube
                if isCube && (queryMode || messageMode) {
                    renderEncoder.drawPrimitives(.Line,
                        vertexStart: neocortex.numVert(),
                        vertexCount: cube.numVert())
                }
                
                // If required, draw message sphere
                if !isCube && (queryMode || messageMode) {
                    renderEncoder.drawPrimitives(.Line,
                        vertexStart: neocortex.numVert() + cube.numVert(),
                        vertexCount: sphere.numVert())
                }
                
                // Draw mesh
                renderEncoder.drawPrimitives(.Line,
                    vertexStart: 0,
                    vertexCount: neocortex.numVert())
                
                renderEncoder.endEncoding()
            }
            commandBuffer.presentDrawable(drawable)
            commandBuffer.commit()
    }
    // END OF FUNCTION
    
    
    
    // START OF FUNCTION: withinSphere
    // Returns true if the vertex at the given index is within the query sphere
    func withinSphere(i: Int) -> Bool {
        let dist:Float = sqrt(powf(sphere.center[0] - vertexData[i * 7],2) +
            powf(sphere.center[1] - vertexData[i*7+1],2) +
            powf(sphere.center[2] - vertexData[i*7+2],2))
        return (dist < (sphereSize * sphere.size))
    }
    // END OF FUNCTION
    
    
    
    // START OF FUNCTION: withinSphere
    // Returns true if the vertex at the given index is within the query cube
    func withinCube(i: Int, center: [Float], halfEdge: Float) -> Bool {
        let coords:[Float] = [vertexData[i * 7],
            vertexData[i * 7 + 1],
            vertexData[i * 7 + 2]]
        if vertexData[i*7] < center[0] - halfEdge ||
            vertexData[i*7] > center[0] + halfEdge ||
            vertexData[i*7 + 1] < center[1] - halfEdge ||
            vertexData[i*7 + 1] > center[1] + halfEdge ||
            vertexData[i*7 + 2] < center[2] - halfEdge ||
            vertexData[i*7 + 2] > center[2] + halfEdge {
                return false
        }
        return true
    }
    // END OF FUNCTION
    
    
    
    // START OF FUNCTION: messageInitialSearch
    // Marks all vertices within search sphere
    func messageInitialSearch() {
        
        // If previous message is not complete, this resets the neocortex colour
        if continueMessage {
            restoreNeocortexColour()
        }
        let numVert:Int = neocortex.numVert()
        
        // Number of steps remaining for each vertex - initially set to -2
        vertSteps = [Int](count: numVert + 1, repeatedValue: -2)
        activeVert = []
        
        // Search through all vertices
        if !isCube {
            for var i = 0; i < numVert; i++ {
                // Check if within sphere
                if withinSphere(i) {
                    // Set remaining steps for that vertex to 'steps'
                    vertSteps[i] = steps
                    // Add vertex to list of active vertices
                    activeVert += [i]
                }
            }
        }
        else {
            for var i = 0; i < numVert; i++ {
                let queryData:[Float] = cube.queryData()
                let center:[Float] = [(queryData[3] + queryData[0])/2,
                    (queryData[4] + queryData[1])/2,
                    (queryData[5] + queryData[2])/2]
                let halfEdge:Float = (queryData[3] - queryData[0]) / 2
                // Check if within sphere
                if withinCube(i, center: center, halfEdge: halfEdge) {
                    // Set remaining steps for that vertex to 'steps'
                    vertSteps[i] = steps
                    // Add vertex to list of active vertices
                    activeVert += [i]
                }
            }
        }
    }
    // END OF FUNCTION
    
    
    
    // START OF FUNCTION: messageIterate
    // Performs the next iteration of message propagation
    func messageIterate() {
        var newActiveVert:[Int] = []
        
        // Run through every active vertex
        for var i = 0; i < activeVert.count; i++ {
            let k = activeVert[i]
            let m = vertSteps[k]
            
            // If vertex is only just activated:
            if m == steps {
                let numNeighbours:Int = neocortex.adjVert[k].count
                // Run through vertices adjacent to active vertex
                for var j = 0; j < numNeighbours ; j++ {
                    // If neighbour is inactive, activate it
                    if vertSteps[neocortex.adjVert[k][j]] == -2 {
                        vertSteps[neocortex.adjVert[k][j]] = steps
                        newActiveVert += [neocortex.adjVert[k][j]]
                    }
                }
            }
            
            // Adjust colour to blue
            if m <= steps && m > steps/2 {
                vertexData[k * 7 + 3] -= 1.4 / Float(steps)
                vertexData[k * 7 + 5] += 3.0 / Float(steps)
                vertSteps[k]--
            }
                
                // Shift colour back to red
            else if m <= steps/2 && m > 0 {
                vertexData[k * 7 + 3] += 1.4 / Float(steps)
                vertexData[k * 7 + 5] -= 3.0 / Float(steps)
                vertSteps[k]--
            }
                
                // If all steps complete, remove vertex from active vertex
            else if m == 0 {
                // Set vertSteps to -1 to indicate message passed through
                vertSteps[k]--
                activeVert.removeAtIndex(i)
                i--
            }
        }
        
        // Add new vertices to active vertex list
        activeVert += newActiveVert
        
        // If no active vertices remain, end message propagation
        if activeVert.count == 0 {
            continueMessage = false
        }
    }
    // END OF FUNCTION
    
    
    
    // START OF FUNCTION: restoreNeocortexColour
    // Resets colour of neocortex
    func restoreNeocortexColour() {
        for var i = 0; i < neocortex.vertexData.count; i += 7 {
            for var j = 0; j < 3; j++ {
                vertexData[i + 3 + j] = neocortex.vertexData[i + j + 3]
            }
        }
    }
    // END OF FUNCTION
}