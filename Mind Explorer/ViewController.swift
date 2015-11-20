//  MIND EXPLORER
//  MSC COMPUTING SCIENCE - INDIVIDUAL PROJECT - IMPERIAL COLLEGE LONDON
//  Author: WILLIAM MOYLE
//  Last updated: 22/07/15

//  VIEWCONTROLLER CLASS DECLARATION FILE

import UIKit
import Metal
import QuartzCore

class ViewController: UIViewController, UIGestureRecognizerDelegate {
    
    //-------------------------------------------------------------------------
    //-------------------- ATTRIBUTES -----------------------------------------
    //-------------------------------------------------------------------------
    
    // Data file names (to be changed if alternative models added)
    let neocortexModelName:String = "neocortex_s"
    let FLATFilePrefix:String = "FLAT168"
    
    // Unit testing attributes
    var unitTests:Bool = false
    var continueTests:Bool = false
    let tests = UnitTests()


    
    // Metal graphics API objects
    var device: MTLDevice! = nil
    var metalLayer: CAMetalLayer! = nil
    var pipelineState: MTLRenderPipelineState! = nil
    var depthStencilState: MTLDepthStencilState!
    var commandQueue: MTLCommandQueue! = nil
    var timer: CADisplayLink! = nil
    var projectionMatrix: Matrix4!
    
    // Models to be rendered
    var neocortex: Model!
    var mesh: Mesh?
    
    // Boolean attributes for controlling modes
    var renderAxis:Bool = false
    var gestureLock:Bool = false
    var messageMode:Bool = false
    var queryMode:Bool = false
    var executeQuery:Bool = false
    var viewQuery:Bool = false
    var isCube:Bool = false
    var tutorial:Bool = false
    var showOptions:Bool = false
    
    // GeometryData objects for storing/adjusting model view
    var meshStore = GeometryData()
    var meshInfo = GeometryData()
    var queryInfo = GeometryData()
    
    // Attributes for handling FLAT queries
    var FLATData: FLATObjC?
    var FLATPath:NSURL!
    var query:[Float] = []
    
    // UI objects for mode control
    @IBOutlet var optionsButton: UIButton!
    @IBOutlet var queryModeLabel: UILabel!
    @IBOutlet var queryModeSwitch: UISwitch!
    @IBOutlet var axisModeLabel: UILabel!
    @IBOutlet var axisModeSwitch: UISwitch!
    @IBOutlet var messageModeLabel: UILabel!
    @IBOutlet var messageModeSwitch: UISwitch!
    
    // UI objects for controlling querying object
    @IBOutlet var cubeBackground: UILabel!
    @IBOutlet var xLabel: UILabel!
    @IBOutlet var yLabel: UILabel!
    @IBOutlet var zLabel: UILabel!
    @IBOutlet var sizeLabel: UILabel!
    @IBOutlet var xSlider: UISlider!
    @IBOutlet var ySlider: UISlider!
    @IBOutlet var zSlider: UISlider!
    @IBOutlet var sizeSlider: UISlider!
    @IBOutlet var xText: UITextField!
    @IBOutlet var yText: UITextField!
    @IBOutlet var zText: UITextField!
    @IBOutlet var sizeText: UITextField!
    @IBOutlet var queryButton: UIButton!
    @IBOutlet var cubeButton: UIButton!
    @IBOutlet var sphereButton: UIButton!
    @IBOutlet var cubeSwitch: UISwitch!
    
    // UI objects for tutorial screen
    @IBOutlet var tutorialImage: UIImageView!
    @IBOutlet var infoButton: UIButton!
    
    
    
    //-------------------------------------------------------------------------
    //----------------------- METHODS -----------------------------------------
    //-------------------------------------------------------------------------
    
    
    
    //*************************************************************************
    //*********************** INITIAL SET UP **********************************
    //*************************************************************************
    
    
    
    // START OF FUNCTION: viewDidLoad
    // Called upon application load - initialises graphics
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Metal device
        device = MTLCreateSystemDefaultDevice()
        
        // Metal layer
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .BGRA8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = view.layer.frame
        view.layer.addSublayer(metalLayer)
        
        // Metal buffer with Neocortex model
        neocortex = Model(device: device, filename: neocortexModelName)
        
        // Render pipeline
        let defaultLibrary = device.newDefaultLibrary()
        let fragmentProgram = defaultLibrary!.newFunctionWithName("basic_fragment")
        let vertexProgram = defaultLibrary!.newFunctionWithName("basic_vertex")
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
        var pipelineError : NSError?
        pipelineState =
            device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor,
                error: &pipelineError)
        depthStencilState = compiledDepthState()
        if pipelineState == nil {
            println("Failed creating pipeline state, \(pipelineError)")
        }
        
        // Command queue
        commandQueue = device.newCommandQueue()
        
        // Display link
        timer = CADisplayLink(target: self,
            selector: Selector("gameloop"))
        timer.addToRunLoop(NSRunLoop.mainRunLoop(),
            forMode: NSDefaultRunLoopMode)
        
        // Final objects
        FLATPath = createFLATFiles()
        projectionMatrix =
            Matrix4.makePerspectiveViewAngle(Matrix4.degreesToRad(85.0),
            aspectRatio: Float(self.view.bounds.size.width / self.view.bounds.size.height),
            nearZ: 0.01, farZ: 100.0)
        view.addSubview(optionsButton)
    }
    // END OF FUNCTION
    
    
    
    // START OF FUNCTION: createFLATFiles
    // Copies required files into Documents folder where they can be read/written
    func createFLATFiles() -> NSURL {
        
        // Get path to documents folder
        var manager = NSFileManager.defaultManager()
        var documentsURL = manager.URLForDirectory(.DocumentDirectory,
            inDomain: .UserDomainMask, appropriateForURL: nil,
            create: true, error: nil)!
        var suffix:String =
            documentsURL.absoluteString!.componentsSeparatedByString("///")[1]
        let FLATDataURL =
            NSURL(fileURLWithPath: "/private/" + suffix + "FLATData/")!
        
        // Find all sub folders in Documents folder
        var subpaths:NSArray =
            manager.contentsOfDirectoryAtURL(documentsURL,
            includingPropertiesForKeys: nil,
            options: NSDirectoryEnumerationOptions.SkipsSubdirectoryDescendants,
            error: nil)!
        
        // Check if FLAT subfolder exists in documents folder
        var inDocuments = false
        for var i = 0; i < subpaths.count && !inDocuments; i++ {
            if subpaths.objectAtIndex(i).absoluteString!
                == FLATDataURL.absoluteString! {
                inDocuments = true}
        }
        
        let indexDatString:String = FLATFilePrefix + "_index.dat"
        let indexIdxString:String = FLATFilePrefix + "_index.idx"
        let payloadDatString:String = FLATFilePrefix + "_payload.dat"
        
        let indexDatURL = FLATDataURL.URLByAppendingPathComponent(indexDatString)
        let indexIdxURL = FLATDataURL.URLByAppendingPathComponent(indexIdxString)
        let payloadDatURL = FLATDataURL.URLByAppendingPathComponent(payloadDatString)
        
        // If no FLAT documents subfolder exists:
        if !inDocuments {
            // Create subfolder
            manager.createDirectoryAtURL(FLATDataURL,
                withIntermediateDirectories: false,
                attributes: nil, error: nil)
            
            // Find FLAT files in main bundle
            let iDatBun = NSBundle.mainBundle().URLForResource(FLATFilePrefix + "_index",
                withExtension: "dat")
            let iIdxBun = NSBundle.mainBundle().URLForResource(FLATFilePrefix + "_index",
                withExtension: "idx")
            let pDatBun = NSBundle.mainBundle().URLForResource(FLATFilePrefix + "_payload",
                withExtension: "dat")
            
            // Move index.dat file
            let success1:Bool = manager.copyItemAtURL(iDatBun!,
                toURL: indexDatURL, error: nil)
            // Move index.idx file
            let success2:Bool = manager.copyItemAtURL(iIdxBun!,
                toURL: indexIdxURL, error: nil)
            // Move payload.dat file
            let success3:Bool = manager.copyItemAtURL(pDatBun!,
                toURL: payloadDatURL, error: nil)
        }
            
        // If FLAT documents subfolder exists
        else {
            var FLATSubpaths:NSArray = manager.contentsOfDirectoryAtURL(FLATDataURL,
                includingPropertiesForKeys: nil,
                options: NSDirectoryEnumerationOptions.SkipsSubdirectoryDescendants,
                error: nil)!
            
            var alreadyCopied1 = false
            var alreadyCopied2 = false
            var alreadyCopied3 = false
            
            for var i = 0; i < FLATSubpaths.count; i++ {
                if FLATSubpaths.objectAtIndex(i).absoluteString! == indexDatURL.absoluteString! {
                    alreadyCopied1 = true}
                if FLATSubpaths.objectAtIndex(i).absoluteString! == indexIdxURL.absoluteString! {
                    alreadyCopied2 = true}
                if FLATSubpaths.objectAtIndex(i).absoluteString! == payloadDatURL.absoluteString! {
                    alreadyCopied3 = true}
            }
            
            // Copy index.dat file, if required
            if !alreadyCopied1 {
                let indexDatBundleURL = NSBundle.mainBundle().URLForResource(FLATFilePrefix + "_index",
                    withExtension: "dat")
                let success1:Bool = manager.copyItemAtURL(indexDatBundleURL!,
                    toURL: indexDatURL, error: nil)
            }
            
            // Copy index.idx file, if required
            if !alreadyCopied2 {
                let indexIdxBundleURL = NSBundle.mainBundle().URLForResource(FLATFilePrefix + "_index",
                    withExtension: "idx")
                let success2:Bool = manager.copyItemAtURL(indexIdxBundleURL!,
                    toURL: indexIdxURL, error: nil)
            }
            
            // Copy payload.dat file, if required
            if !alreadyCopied3 {
                let payloadDatBundleURL = NSBundle.mainBundle().URLForResource(FLATFilePrefix + "_payload",
                    withExtension: "dat")
                let success3:Bool = manager.copyItemAtURL(payloadDatBundleURL!,
                    toURL: payloadDatURL, error: nil)
            }
        }
        return FLATDataURL
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    //*************************************************************************
    //*********************** RENDER LOOP *************************************
    //*************************************************************************
    
    
    
    // START OF FUNCTION: render
    // Called each frame - handles switching between views and world view matrix
    func render() {
        if !tutorial {
            var drawable = metalLayer.nextDrawable()
            if drawable != nil {
                
                // Set up world view matrix based upon input from gesture controls
                var worldModelMatrix = Matrix4()
                worldModelMatrix.translate(meshInfo.x/50.0,
                    y: -meshInfo.y/50.0,
                    z: -7.0)
                worldModelMatrix.rotateAroundX(meshInfo.pitch/100,
                    y: meshInfo.yaw/100,
                    z: -meshInfo.roll)
                
                worldModelMatrix.scale(meshInfo.scale,
                    y: meshInfo.scale, z: meshInfo.scale)
                
                // Handle range query
                if executeQuery {
                    
                    // Perform query
                    FLATData = FLATObjC(FLATPath.absoluteString!)
                    query = neocortex.cube.queryData()
                    let numMesh:Int = performQuery()
                    
                    // Check if query returns nothing
                    if numMesh == 0 {
                        let alertView = UIAlertController(title: "Error",
                            message: "This query does not return any elements",
                            preferredStyle: .Alert)
                        alertView.addAction(UIAlertAction(title: "Cancel",
                            style: .Default,
                            handler: nil))
                        presentViewController(alertView,
                            animated: true,
                            completion: nil)
                    }
                    // Else, create new mesh
                    else {
                        mesh = Mesh(device: device, numMesh: numMesh,
                            query:query, results: FLATData!.results,
                            isCube: isCube)
                        viewQuery = true
                        optionsButton.setTitle("Return", forState: .Normal)
                        removeQuerySubviews()
                        removeSettingsSubviews()
                        meshInfo = GeometryData()
                    }
                    executeQuery = false
                }
                
                // Render mesh
                if viewQuery {
                    mesh!.render(commandQueue, pipelineState: pipelineState,
                        drawable: drawable, parentModelViewMatrix: worldModelMatrix,
                        projectionMatrix: projectionMatrix,
                        depthStencilState: depthStencilState)
                    if continueTests && mesh!.complete {
                        tests.continueTests(self)
                        continueTests = false
                    }
                }
                    
                // Render neocortex model
                else {
                    neocortex.render(commandQueue,
                        pipelineState: pipelineState, drawable: drawable,
                        parentModelViewMatrix: worldModelMatrix,
                        projectionMatrix: projectionMatrix, queryMode: queryMode,
                        messageMode: messageMode, drawAxis: renderAxis,
                        depthStencilState: depthStencilState, isCube: isCube)
                    if unitTests {
                        tests.beginTest(self)
                        unitTests = false
                        continueTests = true
                    }
                }
            }
        }
    }
    // END OF FUNCTION
    
    
    
    // START OF FUNCTION: gameloop
    // Calls render function each frame within auto release pool
    func gameloop() {
        autoreleasepool {
            self.render()
        }
    }
    // END OF FUNCTION
    
    
    
    // START OF FUNCTION: compiledDepthState
    // Creates depth state to calculate what elements sit behind others
    func compiledDepthState() -> MTLDepthStencilState {
        let depthStencilDesc = MTLDepthStencilDescriptor()
        depthStencilDesc.depthCompareFunction = MTLCompareFunction.Less
        depthStencilDesc.depthWriteEnabled = true
        return device.newDepthStencilStateWithDescriptor(depthStencilDesc)
    }
    // END OF FUNCTION
    
    
    
    //*************************************************************************
    //*********************** HANDLING RANGE QUERIES **************************
    //*************************************************************************
    
    
    
    // START OF FUNCTION: translateQuery
    // Converts the query box into the scale used by FLAT data
    func translateQuery() {
        let shift:[Float] = [194.385, 911.41955, 276.339]
        let scale:Float = 0.0042076896685808
        
        query[0] = (query[0] / scale) + shift[0]
        query[1] = (query[1] / scale) + shift[1]
        query[2] = (query[2] / scale) + shift[2]
        query[3] = (query[3] / scale) + shift[0]
        query[4] = (query[4] / scale) + shift[1]
        query[5] = (query[5] / scale) + shift[2]
    }
    // END OF FUNCTION
    
    
    
    // START OF FUNCTION: performQuery
    // Uses FLAT algorithm to locate the mesh within the given grid
    func performQuery() -> Int {
        
        //TRANSLATE QUERY
        translateQuery()
        
        let start = NSDate()
        
        //Execute FLAT query
        FLATData!.performQuery(query[0], p1: query[1],
            p2: query[2], p3: query[3],
            p4: query[4], p5: query[5])
        let numCoords = Int(FLATData!.numCoords)
        
        let end = NSDate()
        let interval:Double = end.timeIntervalSinceDate(start)
        println("Time to perform query: \(interval)")
        
        println("Number of meshes: \(numCoords / 9)")
        
        return numCoords / 9
    }
    // END OF FUNCTION
    
    

    //*************************************************************************
    //*********************** GESTURE CONTROLS ********************************
    //*************************************************************************
    
    
    
    // START OF FUNCTION: gestureRecognizer
    // Allows for handling of multiple simultaneous gestures
    func gestureRecognizer(UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWithGestureRecognizer:UIGestureRecognizer)
        -> Bool {return true}
    // END OF FUNCTION
    
    
    
    // START OF FUNCTION: handleLongPress
    // Returns view to original state (resetting translation, rotation and zoom)
    @IBAction func handleLongPress(sender: UILongPressGestureRecognizer) {
        if (!messageMode && !queryMode)
            || !withinImage(sender, image: cubeBackground) {
            if sender.state == UIGestureRecognizerState.Ended {
                meshInfo = GeometryData()
            }
        }
    }
    // END OF FUNCTION
    
    
    
    // START OF FUNCTION: handlePan
    // Allows for translation and rotation from one or two finger pan gestures
    @IBAction func handlePan(recognizer: UIPanGestureRecognizer) {
        if (!messageMode && !queryMode)
            || !withinImage(recognizer, image: cubeBackground) {
                let translation = recognizer.translationInView(self.view)
                
                // ONE FINGER - TRANSLATION
                if recognizer.numberOfTouches() == 1  {
                    if recognizer.state == UIGestureRecognizerState.Began {
                        gestureLock = true
                        meshStore.x = Float(translation.x)
                        meshStore.y = Float(translation.y)
                    }
                    else if recognizer.state == UIGestureRecognizerState.Changed
                        && gestureLock == true {
                            meshInfo.x += Float(translation.x) - meshStore.x
                            meshInfo.y += Float(translation.y) - meshStore.y
                            meshStore.x = Float(translation.x)
                            meshStore.y = Float(translation.y)
                    }
                }
                    
                // TWO FINGERS - ROTATION
                else if recognizer.numberOfTouches() == 2  {
                    if recognizer.state == UIGestureRecognizerState.Began {
                        gestureLock = false
                        meshStore.yaw = Float(translation.x)
                        meshStore.pitch = Float(translation.y)
                    }
                    else if recognizer.state == UIGestureRecognizerState.Changed
                        && gestureLock == false {
                            meshInfo.yaw += Float(translation.x) - meshStore.yaw
                            meshInfo.pitch += Float(translation.y) - meshStore.pitch
                            meshStore.yaw = Float(translation.x)
                            meshStore.pitch = Float(translation.y)
                    }
                }
        }
    }
    // END OF FUNCTION
    
    
    
    // START OF FUNCTION: handleRotate
    // Rotates object about Z axis following two finger rotation
    @IBAction func handleRotate(recognizer: UIRotationGestureRecognizer) {
        if (!messageMode && !queryMode)
            || !withinImage(recognizer, image: cubeBackground) {
            if recognizer.state == UIGestureRecognizerState.Began {
                meshStore.roll = Float(recognizer.rotation)
            }
            else if recognizer.state == UIGestureRecognizerState.Changed {
                meshInfo.roll += Float(recognizer.rotation) - meshStore.roll
                meshStore.roll = Float(recognizer.rotation)
            }
        }
    }
    // END OF FUNCTION
    
    
    
    // START OF FUNCTION: handlePinch
    // Zooms into and out from object following pinch gesture
    @IBAction func handlePinch(recognizer: UIPinchGestureRecognizer) {
        if (!messageMode && !queryMode)
            || !withinImage(recognizer, image: cubeBackground) {
            if recognizer.state == UIGestureRecognizerState.Began {
                meshStore.scale = Float(recognizer.scale)
            }
            else if recognizer.state == UIGestureRecognizerState.Changed {
                meshInfo.scale += Float(recognizer.scale) - meshStore.scale
                meshInfo.scale = max(meshInfo.scale, 0.1)
                meshStore.scale = Float(recognizer.scale)
            }
        }
    }
    // END OF FUNCTION
    
    
    
    //*************************************************************************
    //*********************** HANDLE SWITCHES *********************************
    //*************************************************************************
    
    
    
    // START OF FUNCTION: handleMessageSwitch
    // Activates or disactivates message propagation mode
    @IBAction func handleMessageSwitch(sender: UISwitch) {
        messageMode = !messageMode
        if messageMode {
            if !queryMode {addQuerySubviews()}
            else {
                queryMode = false
                queryModeSwitch.setOn(false, animated: true)
            }
            xText.text = String(format: "%.2f", xSlider.value)
            yText.text = String(format: "%.2f", ySlider.value)
            zText.text = String(format: "%.2f", zSlider.value)
            sizeText.text = String(format: "%.2f", sizeSlider.value)
        }
        else {removeQuerySubviews()}
    }
    // END OF FUNCTION
    
    
    
    // START OF FUNCTION: handleQuerySwitch
    // Activates or disactivates range query mode
    @IBAction func handleQuerySwitch(sender: UISwitch) {
        queryMode = !queryMode
        if queryMode {
            if !messageMode {addQuerySubviews()}
            else {
                messageMode = false
                messageModeSwitch.setOn(false, animated: true)
            }
            xText.text = String(format: "%.2f", xSlider.value)
            yText.text = String(format: "%.2f", ySlider.value)
            zText.text = String(format: "%.2f", zSlider.value)
            sizeText.text = String(format: "%.2f", sizeSlider.value)
        }
        else {removeQuerySubviews()}
    }
    // END OF FUNCTION
    
    
    
    // START OF FUNCTION: handleCubeSwitch
    // Swaps querying object between cube and sphere
    @IBAction func handleCubeSwitch(sender: UISwitch) {
        isCube = !sender.on
    }
    // END OF FUNCTION
    
    
    
    // START OF FUNCTION: handleAxisSwitch
    // Switch view of axes on and off
    @IBAction func handleAxisSwitch(sender: UISwitch) {
        renderAxis = !renderAxis
    }
    // END OF FUNCTION
    
    
    
    //*************************************************************************
    //*********************** HANDLE BUTTONS **********************************
    //*************************************************************************
    
    
    
    // START OF FUNCTION: cubeButtonPressed
    // Makes querying object into cube
    @IBAction func cubeButtonPressed(sender: UIButton) {
        isCube = true
        cubeSwitch.setOn(false, animated: true)
    }
    // END OF FUNCTION
    
    
    
    // START OF FUNCTION: sphereButtonPressed
    // Makes querying object into sphere
    @IBAction func sphereButtonPressed(sender: UIButton) {
        isCube = false
        cubeSwitch.setOn(true, animated: true)
    }
    // END OF FUNCTION
    
    
    
    // START OF FUNCTION: queryButtonPressed
    // Begins message propagation or executes range query
    @IBAction func queryButtonPressed(sender: UIButton) {
        if messageMode {neocortex.startMessage = true}
        if queryMode {executeQuery = true}
    }
    // END OF FUNCTION
    
    
    
    // START OF FUNCTION: optionsButtonPressed
    // Adds/removes menu options or returns to neocortex view
    @IBAction func optionsButtonPressed(sender: UIButton) {
        // If viewing query, returns to normal mode
        if viewQuery {
            viewQuery = false
            sender.setTitle("Hide", forState: .Normal)
            meshInfo = GeometryData()
            addSettingsSubviews()
            addQuerySubviews()
        }
        // If menu options are hidden, makes visible
        else if !showOptions {
            addSettingsSubviews()
            sender.setTitle("Hide", forState: .Normal)
            if queryMode || messageMode {addQuerySubviews()}
            showOptions = !showOptions
        }
        // If menu options visible, makes hidden
        else {
            removeSettingsSubviews()
            sender.setTitle("Menu", forState: .Normal)
            if queryMode || messageMode {removeQuerySubviews()}
            showOptions = !showOptions
        }
    }
    // END OF FUNCTION
    
    
    
    // START OF FUNCTION: infoButtonPressed
    // Shows/hides tutorial screen
    @IBAction func infoButtonPressed(sender: AnyObject) {
        if tutorial {
            tutorialImage.removeFromSuperview()
            sender.setTitle("Info", forState: .Normal)
        }
        else {
            infoButton.removeFromSuperview()
            view.addSubview(tutorialImage)
            view.addSubview(infoButton)
            sender.setTitle("Close", forState: .Normal)
        }
        tutorial = !tutorial
    }
    // END OF FUNCTION
    
    
    
    //*************************************************************************
    //*********************** QUERY OBJECT CONTROLS ***************************
    //*************************************************************************
    
    
    @IBAction func xSliderChanged(sender: UISlider) {
        queryInfo.x = sender.value
        neocortex.cube.update(queryInfo)
        neocortex.sphere.update(queryInfo)
        xText.text = String(format: "%.2f", sender.value)
    }
    
    @IBAction func ySliderChanged(sender: UISlider) {
        queryInfo.y = sender.value
        neocortex.cube.update(queryInfo)
        neocortex.sphere.update(queryInfo)
        yText.text = String(format: "%.2f", sender.value)
    }
    
    @IBAction func zSliderChanged(sender: UISlider) {
        queryInfo.z = sender.value
        neocortex.cube.update(queryInfo)
        neocortex.sphere.update(queryInfo)
        zText.text = String(format: "%.2f", sender.value)
    }
    
    @IBAction func sizeSliderChanged(sender: UISlider) {
        queryInfo.scale = sender.value
        neocortex.cube.update(queryInfo)
        neocortex.sphere.update(queryInfo)
        sizeText.text = String(format: "%.2f", sender.value)
    }
    
    
    @IBAction func xTextChangeBegin(sender: UITextField) {
        xText.text = ""
        xSlider.setValue(0, animated: true)
    }
    
    @IBAction func xTextChanged(sender: UITextField) {
        let num: Float = (sender.text as NSString).floatValue
        if num >= -5 && num <= 5 {
            xText.text = String(format: "%.2f", num)
            xSlider.setValue(num, animated: true)
        }
        else if num < -5 {
            xText.text = "-5.00"
            xSlider.setValue(-5, animated: true)
        }
        else {
            xText.text = "5.00"
            xSlider.setValue(5, animated: true)
        }
        queryInfo.x = xSlider.value
        neocortex.cube.update(queryInfo)
        neocortex.sphere.update(queryInfo)
    }
    
    @IBAction func yTextChangeBegin(sender: UITextField) {
        yText.text = ""
        ySlider.setValue(0, animated: true)
    }
    
    @IBAction func yTextChanged(sender: UITextField) {
        let num: Float = (sender.text as NSString).floatValue
        if num >= -5 && num <= 5 {
            yText.text = String(format: "%.2f", num)
            ySlider.setValue(num, animated: true)
        }
        else if num < -5 {
            yText.text = "-5.00"
            ySlider.setValue(-5, animated: true)
        }
        else {
            yText.text = "5.00"
            ySlider.setValue(5, animated: true)
        }
        queryInfo.y = ySlider.value
        neocortex.cube.update(queryInfo)
        neocortex.sphere.update(queryInfo)
    }
    
    @IBAction func zTextChangeBegin(sender: UITextField) {
        zText.text = ""
        zSlider.setValue(0, animated: true)
    }
    
    @IBAction func zTextChanged(sender: UITextField) {
        let num: Float = (sender.text as NSString).floatValue
        if num >= -5 && num <= 5 {
            zText.text = String(format: "%.2f", num)
            zSlider.setValue(num, animated: true)
        }
        else if num < -5 {
            zText.text = "-5.00"
            zSlider.setValue(-5, animated: true)
        }
        else {
            zText.text = "5.00"
            zSlider.setValue(5, animated: true)
        }
        queryInfo.z = zSlider.value
        neocortex.cube.update(queryInfo)
        neocortex.sphere.update(queryInfo)
    }
    
    @IBAction func sizeTextChangeBegin(sender: UITextField) {
        sizeText.text = ""
        sizeSlider.setValue(1, animated: true)
    }
    
    @IBAction func sizeTextChanged(sender: UITextField) {
        let num: Float = (sender.text as NSString).floatValue
        if num >= 0 && num <= 2 {
            sizeText.text = String(format: "%.2f", num)
            sizeSlider.setValue(num, animated: true)
        }
        else if num < 0 {
            sizeText.text = "0.00"
            sizeSlider.setValue(0, animated: true)
        }
        else {
            sizeText.text = "2.00"
            sizeSlider.setValue(2, animated: true)
        }
        queryInfo.scale = sizeSlider.value
        neocortex.cube.update(queryInfo)
        neocortex.sphere.update(queryInfo)
    }
    
    
    //*************************************************************************
    //*********************** AUXILLIARY FUNCTIONS ****************************
    //*************************************************************************
    
    
    func addQuerySubviews() {
        view.addSubview(cubeBackground)
        view.addSubview(xLabel)
        view.addSubview(yLabel)
        view.addSubview(zLabel)
        view.addSubview(sizeLabel)
        view.addSubview(xSlider)
        view.addSubview(ySlider)
        view.addSubview(zSlider)
        view.addSubview(sizeSlider)
        view.addSubview(xText)
        view.addSubview(yText)
        view.addSubview(zText)
        view.addSubview(sizeText)
        view.addSubview(queryButton)
        view.addSubview(cubeButton)
        view.addSubview(sphereButton)
        view.addSubview(cubeSwitch)
    }
    
    func removeQuerySubviews() {
        xLabel.removeFromSuperview()
        yLabel.removeFromSuperview()
        zLabel.removeFromSuperview()
        sizeLabel.removeFromSuperview()
        xSlider.removeFromSuperview()
        ySlider.removeFromSuperview()
        zSlider.removeFromSuperview()
        sizeSlider.removeFromSuperview()
        xText.removeFromSuperview()
        yText.removeFromSuperview()
        zText.removeFromSuperview()
        sizeText.removeFromSuperview()
        cubeBackground.removeFromSuperview()
        queryButton.removeFromSuperview()
        cubeButton.removeFromSuperview()
        sphereButton.removeFromSuperview()
        cubeSwitch.removeFromSuperview()
    }
    
    func addSettingsSubviews() {
        view.addSubview(queryModeLabel)
        view.addSubview(queryModeSwitch)
        view.addSubview(axisModeLabel)
        view.addSubview(axisModeSwitch)
        view.addSubview(messageModeLabel)
        view.addSubview(messageModeSwitch)
        view.addSubview(infoButton)
    }
    
    func removeSettingsSubviews() {
        queryModeLabel.removeFromSuperview()
        queryModeSwitch.removeFromSuperview()
        axisModeLabel.removeFromSuperview()
        axisModeSwitch.removeFromSuperview()
        messageModeLabel.removeFromSuperview()
        messageModeSwitch.removeFromSuperview()
        infoButton.removeFromSuperview()
    }
    
    func withinImage(sender: UIGestureRecognizer, image: UIView) -> Bool {
        let imageX:CGFloat = image.frame.width
        let imageY:CGFloat = image.frame.height
        let posX:CGFloat = sender.locationInView(image).x
        let posY:CGFloat = sender.locationInView(image).y
        if posX < 0 || posY < 0 || posX > imageX || posY > imageY {
            return false
        }
        return true
    }
}


