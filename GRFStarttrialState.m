//
//  GRFStarttrialState.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "GRFStarttrialState.h"
#import "UtilityFunctions.h"
#import "GRFDigitalOut.h"
#import "GRF.h"
#import "GRFUtilities.h"

@implementation GRFStarttrialState

- (void)stateAction;
{
	long lValue;
	FixWindowData fixWindowData, respWindowData;
	
	eotCode = -1;
    trialCounter++;
	
// Prepare structures describing the fixation and response windows;
	
	fixWindowData.index = [[task eyeCalibrator] nextCalibrationPosition];
	[[task synthDataDevice] setOffsetDeg:[[task eyeCalibrator] calibrationOffsetPointDeg]];			// keep synth data on offset fixation

// fixWindow is not being updated

	fixWindowData.windowDeg = [fixWindow rectDeg];
    fixWindowData.windowUnits = [[task eyeCalibrator] unitRectFromDegRect:fixWindowData.windowDeg];
    [fixWindow setWidthAndHeightDeg:[[task defaults] floatForKey:GRFFixWindowWidthDegKey]];

	[respWindow setAzimuthDeg:[[stimuli taskGabor] azimuthDeg] elevationDeg:[[stimuli taskGabor] elevationDeg]];
	[respWindow setWidthAndHeightDeg:[[task defaults] floatForKey:GRFRespWindowWidthDegKey]];
	respWindowData.index = 0;
	respWindowData.windowDeg = [respWindow rectDeg];
	respWindowData.windowUnits = [[task eyeCalibrator] unitRectFromDegRect:respWindowData.windowDeg];

// Stop data collection before this block of events, and force all the data to be readcollectorTimer
    [[task dataController] setDataEnabled:[NSNumber numberWithBool:NO]];
	[[task dataController] readDataFromDevices];		// flush data buffers
	[[task collectorTimer] fire];
	[[task dataDoc] putEvent:@"trialStart" withData:&trialCounter];
//    [digitalOut outputEvent:kTrialStartDigitOutCode withData:trialCounter];
    [digitalOut outputEventName:@"trialStart" withData:trialCounter];
    [[task dataDoc] putEvent:@"trial" withData:&trial];
    [digitalOut outputEventName:@"instructTrial" withData:(long)trial.instructTrial];
	[digitalOut outputEventName:@"catchTrial" withData:(long)trial.catchTrial];
    [digitalOut outputEventName:@"eyesClosed" withData:(long)eyesClosed]; // [Vinay] - sending the eyes closed information, useful to get the task mode for the tfunc protocol
	lValue = 0;
	[[task dataDoc] putEvent:@"sampleZero" withData:&lValue];	// for now, it has no practical functions
	[[task dataDoc] putEvent:@"spikeZero" withData:&lValue];
	
// Restart data collection immediately after declaring the zerotimes

    [[task dataController] setDataEnabled:[NSNumber numberWithBool:YES]];
	//[[task dataDoc] putEvent:@"eyeCalibration" withData:[[task eyeCalibrator] calibrationData]];
    [[task dataDoc] putEvent:@"eyeLeftCalibration" withData:[[task eyeCalibrator] calibrationDataForEye:kLeftEye]];
	[[task dataDoc] putEvent:@"eyeRightCalibration" withData:[[task eyeCalibrator] calibrationDataForEye:kRightEye]];

	[[task dataDoc] putEvent:@"eyeWindow" withData:&fixWindowData];
	[[task dataDoc] putEvent:@"responseWindow" withData:&respWindowData];
}

- (NSString *)name {

    return @"GRFStarttrial";
}

- (LLState *)nextState {

	if ([task mode] == kTaskIdle) {
		eotCode = kMyEOTQuit;
		return  [[task stateSystem] stateNamed:@"Endtrial"];
	}
	if ([[task defaults] boolForKey:GRFFixateKey] && [GRFUtilities inWindow:fixWindow]) {
		return [[task stateSystem] stateNamed:@"GRFBlocked"];
	}
	else {
		return [[task stateSystem] stateNamed:@"GRFFixon"];
	} 
}

@end
