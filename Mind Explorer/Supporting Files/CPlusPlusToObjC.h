//
//  CPlusPlusToObjC.h
//  MIND EXPLORER
//
//  Created by William Moyle on 31/07/2015.
//  Copyright (c) 2015 Will Moyle. All rights reserved.
//

#ifndef CPlusPlusToObjC_h
#define CPlusPlusToObjC_h

#ifdef __OBJC__

#import <Foundation/Foundation.h>
#import "FLATTest.hpp"

@interface FLATObjC : NSObject
//- (int) returnInt:(NSString*) input;
@property int numCoords;
@property NSMutableArray* results;
@property NSString* filename;
//@property FLATTest FLAT;
- (id) init:(NSString*) input;
- (void) performQuery: (float) parm0 p1:(float) parm1 p2:(float) parm2 p3:(float) parm3 p4:(float) parm4 p5:(float) parm5;
@end

#endif
#endif