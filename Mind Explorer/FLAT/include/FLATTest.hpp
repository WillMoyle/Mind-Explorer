//
//  FLAT.h
//  FLAT Tester
//
//  Created by William Moyle on 31/07/2015.
//  Copyright (c) 2015 Will Moyle. All rights reserved.
//

#ifndef __FLAT_Tester__FLAT__
#define __FLAT_Tester__FLAT__

#include "SpatialQuery.hpp"
#include "SeedBuilder.hpp"
#include "SpatialObjectFactory.hpp"
#include "Mesh.hpp"
#include "MeshData.hpp"

#ifdef __cplusplus

class FLATTest {
public:
    std::string inputStem;
    //std::string queryFile;
    //char *inputStem;
    //char *queryFile;
    FLAT::QueryStatistics stats;
    std::vector<FLAT::spaceUnit> results;
    int numCoords;

    FLATTest(char* filename, int len);
    ~FLATTest();
    
    void performTest(float p0, float p1, float p2, float p3, float p4, float p5);
    void printMeshCoords();
};

#endif
#endif
