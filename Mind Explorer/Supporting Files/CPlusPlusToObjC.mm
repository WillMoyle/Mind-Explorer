//
//  CPlusPlusToObjC.m
//  MIND EXPLORER
//
//  Created by William Moyle on 31/07/2015.
//  Copyright (c) 2015 Will Moyle. All rights reserved.
//

#ifdef __OBJC__

//#import <Foundation/Foundation.h>
#import "CPlusPlusToObjC.h"

@implementation FLATObjC
/*- (int) returnInt:(NSString*) input
{
    const char *cpath = [input fileSystemRepresentation];
    //std::string output(cpath);
    
    size_t len = strlen(cpath) + 1;
    char cpy [len];
    memcpy(cpy, cpath, len);
    
    //FLATTest testFLATTest(&output);
    FLATTest testFLATTest(cpy, len);
    
    return testFLATTest.numCoords;
}*/
- (id)init:(NSString*) input
{
    self = [super init];
    if (self) {
        _filename = input;
        //const char *cpath = [input fileSystemRepresentation];
        //int len = strlen(cpath) + 1;
        //char cpy [len];
        //memcpy(cpy, cpath, len);
                
        //_FLAT = FLATTest(cpy, len);

        _numCoords = 0;
        _results = [[NSMutableArray alloc] initWithCapacity: 0];
    }
    return self;
}

- (void) performQuery: (float)para0 p1:(float)para1 p2:(float)para2 p3:(float)para3 p4:(float)para4 p5:(float)para5
{
    const char *cpath = [_filename fileSystemRepresentation];
    int len = int(strlen(cpath)) + int(1);
    char cpy [len];
    memcpy(cpy, cpath, len);
    
    FLATTest* FLAT = new FLATTest(cpy, len);
    
    FLAT->performTest(para0, para1, para2, para3, para4, para5);
    _numCoords = FLAT->numCoords;
    _results = [[NSMutableArray alloc] initWithCapacity: _numCoords];
    for (int i = 0; i < _numCoords; i++) {
        [_results addObject: [NSNumber numberWithFloat:(FLAT->results[i])]];
    }
    delete FLAT;
}


@end

#endif