//
//  GRFPrestimState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "GRFPrestimState.h"

@implementation GRFPrestimState

- (void)stateAction;
{
	[stimuli setCueSpot:NO location:trial.attendLoc];
	[[task dataDoc] putEvent:@"preStimuli"];
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:GRFInterstimMSKey]];
}

- (NSString *)name {

    return @"GRFPrestim";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kEOTQuit;
		return stateSystem->endtrial;
	}
	if ([[task defaults] boolForKey:GRFFixateKey] && ![fixWindow inWindowDeg:[task currentEyeDeg]]) {
		eotCode = kEOTBroke;
		return stateSystem->endtrial;
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		return stateSystem->stimulate;
	}
	return nil;
}

@end
