//
//  GRFBlockedState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "GRFBlockedState.h"
#import "GRFUtilities.h"

@implementation GRFBlockedState

- (void)stateAction {

	[[task dataDoc] putEvent:@"blocked"];
//	schedule(&bNode, (PSCHED)&blockedTones, PRISYS - 1, 400, -1, NULL);
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:GRFAcquireMSKey]];
}

- (NSString *)name {

    return @"GRFBlocked";
}

- (LLState *)nextState {

	if (![[task defaults] boolForKey:GRFFixateKey] || ![GRFUtilities inWindow:fixWindow]) {
		return [[task stateSystem] stateNamed:@"GRFFixon"];
    }
	if ([task mode] == kTaskIdle) {
		eotCode = kMyEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		eotCode = kMyEOTIgnored;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
    return nil; 
}

@end
