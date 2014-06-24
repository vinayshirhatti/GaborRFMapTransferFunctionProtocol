//
//  GRFFixateState.m
//  GaborRFMap
//
//  GRFPreCueState.m
//	Created by John Maunsell on 2/25/06.
//	modified from GRFPreCueState.m by Incheol Kang on 12/8/06
//
//  Copyright 2006. All rights reserved.
//
//  [Vinay] - modified from GRFStimulate.m on 24 June 2014

#import "GRFEyesClosedState.h"
#import "GRFUtilities.h"

@implementation GRFEyesClosedState

- (void)stateAction;
{
	[stimuli startStimSequence];
}

- (NSString *)name {
    
    return @"GRFEyesClosed";
}

- (LLState *)nextState {
    
	if ([task mode] == kTaskIdle) {
		eotCode = kMyEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	if ([stimuli targetPresented]) {
        eotCode = kMyEOTCorrect;
        return [[task stateSystem] stateNamed:@"Endtrial"];
	}
    if (![stimuli stimulusOn]) {
		eotCode = kMyEOTCorrect;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
    return nil;
}


@end
