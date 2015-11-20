//
//  MeshData.cpp
//  FLAT Query Generator
//
//  Created by William Moyle on 04/08/2015.
//  Copyright (c) 2015 Will Moyle. All rights reserved.
//

#include "MeshData.hpp"

MeshData::MeshData(FLAT::Mesh _m) {
    vertexData[0] = _m.vertex1[0];
    vertexData[1] = _m.vertex1[1];
    vertexData[2] = _m.vertex1[2];
    vertexData[3] = _m.vertex2[0];
    vertexData[4] = _m.vertex2[1];
    vertexData[5] = _m.vertex2[2];
    vertexData[6] = _m.vertex3[0];
    vertexData[7] = _m.vertex3[1];
    vertexData[8] = _m.vertex3[2];
}