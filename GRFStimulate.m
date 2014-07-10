//
//  GRFStimulate.m
//  GaborRFMap
//
//  Copyright (c) 2006. All rights reserved.
//

#import "GRFStimulate.h" 
#import "GRFUtilities.h"

@implementation GRFStimulate

- (void)stateAction;
{
	[stimuli startStimSequence];
}

- (NSString *)name {

    return @"GRFStimulate";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kMyEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([stimuli targetPresented]) {
		if ([[task defaults] boolForKey: GRFFixateOnlyKey]) {
			eotCode = kMyEOTCorrect;
			return [[task stateSystem] stateNamed:@"Endtrial"];		
		}
		return [[task stateSystem] stateNamed:@"GRFTooFast"];
	}
	if ([[task defaults] boolForKey:GRFFixateKey] && ![GRFUtilities inWindow:fixWindow] && !eyesClosed) { // [Vinay] - added && !eyesClosed for the tfunc protocol
		eotCode = kMyEOTBroke;
		return [[task stateSystem] stateNamed:@"GRFSaccade"];
	}
	if (![stimuli stimulusOn]) {
		eotCode = kMyEOTCorrect;
		return [[task stateSystem] stateNamed:@"Endtrial"];
	}
    return nil;
}


@end
