//
//  MeshData.h
//  FLAT Query Generator
//
//  Created by William Moyle on 04/08/2015.
//  Copyright (c) 2015 Will Moyle. All rights reserved.
//

#ifndef __FLAT_Query_Generator__MeshData__
#define __FLAT_Query_Generator__MeshData__

#include "Mesh.hpp"

#ifdef __cplusplus

class MeshData {
public:
    FLAT::spaceUnit vertexData[9];
    
    MeshData(FLAT::Mesh _m);
};


#endif
#endif
