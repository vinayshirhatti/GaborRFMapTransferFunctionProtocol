//
//  GRFIntertrialState.h
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "GRFStateSystem.h"

@interface GRFIntertrialState : LLState {

	NSTimeInterval	expireTime;
}

- (BOOL)selectTrial;

@end
