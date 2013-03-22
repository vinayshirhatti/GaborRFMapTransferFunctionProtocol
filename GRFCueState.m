//
//  GRFCueState.m
//  OrientationChange
//
//  Created by John Maunsell on 2/25/06.
//  Copyright 2006. All rights reserved.
//

#import "GRFCueState.h"

@implementation GRFCueState

- (void)stateAction;
{
	cueMS = [[task defaults] integerForKey:GRFCueMSKey];
	if (cueMS > 0) {
		[stimuli setCueSpot:YES location:trial.attendLoc];
		expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:GRFCueMSKey]];
		if ([[task defaults] boolForKey:GRFDoSoundsKey]) {
			[[NSSound soundNamed:kFixOnSound] play];
		}
		[[task dataDoc] putEvent:@"cueOn"];
	}
}

- (NSString *)name {

    return @"GRFCue";
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
	if (cueMS <= 0 || [LLSystemUtil timeIsPast:expireTime]) {
		return stateSystem->prestim;
	}
	else {
		return nil;
    }
}

@end
