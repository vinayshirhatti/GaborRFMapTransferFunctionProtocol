//
//  GRFReactState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "GRFReactState.h"
#import "UtilityFunctions.h"

#define kAlpha		2.5
#define kBeta		2.0

@implementation GRFReactState

- (void)stateAction;
{

	[[task dataDoc] putEvent:@"react"];
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:GRFRespTimeMSKey] -
                    [[task defaults] integerForKey:GRFTooFastMSKey]];
}

- (NSString *)name {

    return @"GRFReact";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {							// switched to idle
		eotCode = kMyEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	if (![[task defaults] boolForKey:GRFFixateKey]) {
		eotCode = kMyEOTCorrect;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	else {
		if (![fixWindow inWindowDeg:[task currentEyeDeg]]) {   // started a saccade
//			[[task dataDoc] putEvent:@"saccadeLaunched"]; 
			return [[task stateSystem] stateNamed:@"GRFSaccade"];
		}
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		eotCode = kMyEOTMissed;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
    return nil;
}

@end
