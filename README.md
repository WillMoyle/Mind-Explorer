## Mind Explorer
Welcome to Mind Explorer, the app that allows you to explore a three-dimensional model of the neural network of the neocortex, the part of the brain associated with higher functions such as conscious thought and spatial reasoning.

This app allows the user to simulate brain signals propagating throughout the neural network as well as render portions of the model in higher detail by making use of the FLAT spatial indexing and range query algorithm.

Upon starting up Mind Explorer, the user views a 3D model of a rat's neocortex. This model can be manipulated using the following gesture controls:

- **One-finger drag** - Moves the model in a 2D plane in front of the user
- **Two-finger drag** - Rotates the model about its central point
- **Pinch** - Zoom in and out of the object
- **Long press** - Resets the model to its original view

Pressing the *Menu* button in the lower right corner of the screen brings up the following options:

- **Info** - Press this button in the top right of the screen to show the tutorial screen. This can be removed by pressing the *Close* button which appears in the top right.
- **Message** - This switch adds the querying object (initially a sphere but can be changed to a cube) onto the neocortex model, centered at coordinates (0,0,0). This also loads up the querying object controls. Upon pressing the *Execute* button, a simulated brain message is initialised within the querying object and propagates throughout the network.
- **Query** - This switch loads the same objects onto the screen as the *Message* switch. However, the *Execute* button performs a spatial range query on the neocortex model, using the FLAT algorithm, and the results are displayed on the screen. The 3D results mesh can be manipulated using the same gesture controls and the user can return to the overall neocortex model by pressing the *Return* button.
- **Axes** - This switch adds X, Y and Z axes onto the neocortex model.

**Project structure**
The XCode project consists of the following files:
- **/AppDelegate.swift** - This file contains core iOS functions used for handling events such as the application entering the background or foreground. Currently this file has not been edited from the iOS standard template, however it could be used at a later date for saving and reloading elements from Core Data.
- **/ViewController.swift** - The *ViewController* class handles the main running of the application. It handles the following functionality:
    - Initial loading of the app.
    - Performing each render loop.
    - Handling gesture controls.
    - Adding and removing screen elements such as labels and buttons.
- **/Geometry/Model.swift** - The main model class for rendering the neocortex model See Appendix E.2 for a diagram showing how this class relates to other classes in the Geometry folder.
- **/Geometry/Neocortex.swift** - Used for loading up the neocortex model from the file.
- **/Geometry/Axis.swift** - Generates the axes that can be drawn onto the model.
- **/Geometry/Cube.swift** - Generates a cube for performing queries.
- **/Geometry/Sphere.swift** - Loads a sphere for performing queries
- **/Geometry/GeometryData.swift** - A data structure that is used for sending location and orientation data from the *ViewController* class to the *Model* class.
- **/Geometry/Geometry.swift** - The superclass for the *Neocortex*, *Axis*, *Cube* and *Sphere* classes.
- **/Query/Mesh.swift** - The *Mesh* class is used to render the results of the FLAT range queries.
- **/Graphics/Shaders.metal** - Handles the colouring of the vertices.
- **/Data/FLAT168** - These three large files contain the entire mesh data set.
- **/Data/neocortex\_s\_adj** - This is an *NSKeyedArchive* file containing an array of integer arrays that contain information of neighbouring vertices within the neocortex model. This is described in more depth in Section 4.4.
- **/Data/neocortex\_s** - This *NSKeyedArchive* file contains an array of Float values representing the coordinates of the lines that make up the neocortex model.
- **/Supporting Files/UnitTests.swift** - This file contains the customised unit testing suite developed for the project (as detailed in Section 6.1). The tests print their output to the console and are activated by setting the boolean parameter, *unitTests*, within the *ViewController* class to *true*.
- **/Supporting Files/Mind-Explorer-Bridging-Header.h** - This file is used to make the Objective-C files readable by the Swift files.
- **/Supporting Files/Matrix4.h** - Contains matrix functions used for rendering the 3D environments.
- **/Supporting Files/CPlusPlusToObjC.h** - This Objective-C++ file allows for the communication of range queries and results between the Swift and C++ files.
- **/Supporting Files/LaunchScreen.xib** - This storyboard file shows the elements that are initially loaded onto the screen.
- **/FLAT/...** - This folder contains the C++ header and source files for performing the FLAT algorithm.
- **/RTREE/...** - These C++ header and source files are used by the FLAT algorithm.
The project folder also contains an additional XCode project, *Mind Explorer Auxilliary Functions*, containing supporting functions which were used to preprocess the data. More detail on these functions can be found in below.





**Future expansion**
The bullet points below describe elements of the code base to facilitate future expansions of the project. 

- **Changing neocortex model** - In order to change the 3D model that is initially rendered onto the screen, it is necessary to add a new file into the XCode project. This file should be an NSKeyedArchive generated from a float array. This array should contain six float values for each line in the model. The model should already have been scaled to fit within the range: (-4,-4,-4) to (4,4,4). The *drawVertices* function within the *Auxilliary Functions* project can be used to generate the required array. The input parameter for this function is the string path to the neocortex model in a text file. This array should then be sorted using the *orderVertices* function and then can then be archived using the *archiveVertexData* function in the same project. Within the Mind Explorer project, in order to choose which file contains the neocortex model, it is necessary to change the *neocortexModelName* string parameter of the *ViewController* class, contained in the file *ViewController.swift*.
- **Creating message propagation data structures** - When a new neocortex model is added, it is also necessary to regenerate the list of adjacent vertices. This can be done using the *calculateAdjacentVertices* function in the *Auxilliary Functions* project. This creates an NSKeyedArchive file of the array of integer arrays which should then be added into the Mind Explorer project. The name of this file should be the same as the name of the neocortex model archive file, with *_adj* on the end.
- **Changing message size** - In order to change the length of the message pulses, adjust the *steps* attribute of the *Model* class in the file *Model.swift*.
- **Change sizes and colours** - These are all controlled by parameters of the *Model* and *Mesh* classes. The parameters are clearly named (for example, *sphereSize* and *queryColour*). Colour parameters consist of a standard Red Blue Green Alpha float array, each between 0 and 1. As well as being able to change the colours of the neocortex model and querying objects, developers can also adjust background colours and the the colour of the mesh query results. Lighting effects are handled by *Shaders.metal*.