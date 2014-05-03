//
//  GRFTooFastState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "GRFTooFastState.h"
#import "UtilityFunctions.h"
#import "GRFUtilities.h"

#define alpha		2.5
#define kBeta		2.0

@implementation GRFTooFastState

- (void)stateAction;
{
	float prob100;
	int tooFastMS;
	LLGabor *gabor;
	
	[[task dataDoc] putEvent:@"tooFast"];
	tooFastMS =  [[task defaults] integerForKey:GRFTooFastMSKey];
	expireTime = [LLSystemUtil timeFromNow:tooFastMS];
					
// Here we instruct the fake monkey to respond, using appropriate psychophysics.

	prob100 = 100.0 - 50.0 * exp(-exp(log(trial.orientationChangeDeg / alpha) * kBeta));
	if ((rand() % 100) < prob100) {
		gabor = [stimuli taskGabor];
		[[task synthDataDevice] setEyeTargetOn:NSMakePoint([gabor azimuthDeg], [gabor elevationDeg])];
	}
}

- (NSString *)name {

    return @"GRFTooFast";
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
		if (![GRFUtilities inWindow:fixWindow]) {   // too fast reaction
			eotCode = kMyEOTBroke;
			return [[task stateSystem] stateNamed:@"GRFSaccade"];;
		}
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		return [[task stateSystem] stateNamed:@"GRFReact"];
	}
    return nil;
}

@end
