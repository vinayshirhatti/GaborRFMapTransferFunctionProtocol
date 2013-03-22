//
//  GRFFixGraceState.m
//  GaborRFMap
//
//  Copyright 2006. All rights reserved.
//

#import "GRFFixGraceState.h"


@implementation GRFFixGraceState

- (void)stateAction;
{
	[[task dataDoc] putEvent:@"fixGrace"];
	expireTime = [LLSystemUtil timeFromNow:[[task defaults] integerForKey:GRFFixGraceMSKey]];
	if ([[task defaults] boolForKey:GRFDoSoundsKey]) {
		[[NSSound soundNamed:kFixOnSound] play];
	}
}

- (NSString *)name;
{
    return @"GRFFixGrace";
}

- (LLState *)nextState;
{
	if ([task mode] == kTaskIdle) {
		eotCode = kMyEOTQuit;
		return [[task stateSystem] stateNamed:@"Endtrial"];;
	}
	if ([LLSystemUtil timeIsPast:expireTime]) {
		if ([fixWindow inWindowDeg:[task currentEyeDeg]])  {
			return [[task stateSystem] stateNamed:@"GRFFixate"];
		}
		else {
			eotCode = kMyEOTIgnored;
			return [[task stateSystem] stateNamed:@"Endtrial"];;
		}
	}
	else {
		return nil;
    }
}

@end
