//
//  UtilityFunctions.m
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "GRF.h"
#import "GaborRFMap.h"
#import "UtilityFunctions.h"

//#define kC50Squared			0.0225
#define kC50Squared			0.09
#define kDrivenRate			100.0
#define kSpontRate			5.0


void announceEvents(void) {

    long lValue;
    MapSettings settings;
	char *idString = "GaborRFMap Version 1.0";
	
 	[[task dataDoc] putEvent:@"text" withData:idString lengthBytes:strlen(idString)];

	[[task dataDoc] putEvent:@"blockStatus" withData:&blockStatus];
	[[task dataDoc] putEvent:@"mappingBlockStatus" withData:&mappingBlockStatus];
	[[task dataDoc] putEvent:@"behaviorSetting" withData:(Ptr)getBehaviorSetting()];
	[[task dataDoc] putEvent:@"stimSetting" withData:(Ptr)getStimSetting()];
	[[task dataDoc] putEvent:@"taskGabor" withData:(Ptr)[[stimuli taskGabor] gaborData]];
	[[task dataDoc] putEvent:@"mappingGabor0" withData:(Ptr)[[stimuli mappingGabor0] gaborData]];
	[[task dataDoc] putEvent:@"mappingGabor1" withData:(Ptr)[[stimuli mappingGabor1] gaborData]];
    [[(GaborRFMap *)task mapStimTable0] updateBlockParameters];
    settings = [[(GaborRFMap *)task mapStimTable0] mapSettings];
    [[task dataDoc] putEvent:@"map0Settings" withData:&settings];
    [[(GaborRFMap *)task mapStimTable1] updateBlockParameters];
    settings = [[(GaborRFMap *)task mapStimTable1] mapSettings];
    [[task dataDoc] putEvent:@"map1Settings" withData:&settings];

    lValue = [[task defaults] integerForKey:GRFStimDurationMSKey];
	[[task dataDoc] putEvent:@"stimDurationMS" withData:&lValue];
    lValue = [[task defaults] integerForKey:GRFInterstimMSKey];
	[[task dataDoc] putEvent:@"interstimMS" withData:&lValue];
    lValue = [[task defaults] integerForKey:GRFMapStimDurationMSKey];
	[[task dataDoc] putEvent:@"mapStimDurationMS" withData:&lValue];
    lValue = [[task defaults] integerForKey:GRFMapInterstimDurationMSKey];
	[[task dataDoc] putEvent:@"mapInterstimDurationMS" withData:&lValue];
    lValue = [[task defaults] integerForKey:GRFRespTimeMSKey];
	[[task dataDoc] putEvent:@"responseTimeMS" withData:&lValue];
	lValue = [[task defaults] integerForKey:GRFMaxTargetMSKey];
	[[task dataDoc] putEvent:@"maxTargetTimeMS" withData:(void *)&lValue];
	lValue = [[task defaults] integerForKey:GRFMinTargetMSKey];
	[[task dataDoc] putEvent:@"minTargetTimeMS" withData:(void *)&lValue];
}

void requestReset(void) {

    if ([task mode] == kTaskIdle) {
        reset();
    }
    else {
        resetFlag = YES;
    }
}

void reset(void) {

    long resetType = 0;
    
	[[task dataDoc] putEvent:@"reset" withData:&resetType];
}

float spikeRateFromStimValue(float normalizedValue) {

	double vSquared;
	
	vSquared = normalizedValue * normalizedValue;
	return kDrivenRate *  vSquared / (vSquared + kC50Squared) + kSpontRate;
}

// Return the number of stimulus repetitions in a block (kLocations * repsPerBlock * contrasts)  

void updateCatchTrialPC(void) {

	float lambda, catchTrialMaxPC;
	float minTargetS, meanTargetS, maxTargetS, meanRateHz;
	long stimulusMS, interstimMS;

	stimulusMS = [[task defaults] integerForKey:GRFStimDurationMSKey]; 
	interstimMS = [[task defaults] integerForKey:GRFInterstimMSKey];
	meanRateHz = 1000.0 / (stimulusMS + interstimMS);
	minTargetS = [[task defaults] integerForKey:GRFMinTargetMSKey] / 1000.0;
	meanTargetS = [[task defaults] integerForKey:GRFMeanTargetMSKey] / 1000.0;

	lambda = log(2.0) / (meanTargetS - minTargetS + 0.5 / meanRateHz);
	maxTargetS = [[task defaults] integerForKey:GRFMaxTargetMSKey] / 1000.0 - minTargetS + 1.0 / meanRateHz;
	catchTrialMaxPC = exp(-lambda * maxTargetS) *100.0;
	
	[[task defaults] setFloat:catchTrialMaxPC forKey:GRFCatchTrialMaxPCKey];
	
	if ([[task defaults] floatForKey:GRFCatchTrialPCKey] > catchTrialMaxPC)
		[[task defaults] setFloat:catchTrialMaxPC forKey:GRFCatchTrialPCKey];
	
}

BehaviorSetting *getBehaviorSetting(void) {

	static BehaviorSetting behaviorSetting;
	
	behaviorSetting.blocks =  [[task defaults] integerForKey:GRFBlockLimitKey];
	behaviorSetting.intertrialMS =  [[task defaults] integerForKey:GRFIntertrialMSKey];
	behaviorSetting.acquireMS =  [[task defaults] integerForKey:GRFAcquireMSKey];
	behaviorSetting.fixGraceMS = [[task defaults] integerForKey:GRFFixGraceMSKey];
	behaviorSetting.fixateMS = [[task defaults] integerForKey:GRFFixateMSKey];
	behaviorSetting.fixateJitterPC = [[task defaults] integerForKey:GRFFixJitterPCKey];
	behaviorSetting.responseTimeMS = [[task defaults] integerForKey:GRFRespTimeMSKey];
	behaviorSetting.tooFastMS = [[task defaults] integerForKey:GRFTooFastMSKey];
	behaviorSetting.minSaccadeDurMS = [[task defaults] integerForKey:GRFSaccadeTimeMSKey];
	behaviorSetting.breakPunishMS = [[task defaults] integerForKey:GRFBreakPunishMSKey];
	behaviorSetting.rewardSchedule = [[task defaults] integerForKey:GRFRewardScheduleKey];
	behaviorSetting.rewardMS = [[task defaults] integerForKey:GRFRewardMSKey];
	behaviorSetting.fixWinWidthDeg = [[task defaults] floatForKey:GRFFixWindowWidthDegKey];
	behaviorSetting.respWinWidthDeg = [[task defaults] floatForKey:GRFRespWindowWidthDegKey];
	
	return &behaviorSetting;
}


StimSetting *getStimSetting(void) {

	static StimSetting stimSetting;
	
	stimSetting.stimDurationMS =  [[task defaults] integerForKey:GRFStimDurationMSKey];
	stimSetting.stimDurJitterPC =  [[task defaults] integerForKey:GRFStimJitterPCKey];
	stimSetting.interStimMS =  [[task defaults] integerForKey:GRFInterstimMSKey];
	stimSetting.interStimJitterPC = [[task defaults] integerForKey:GRFInterstimJitterPCKey];
	stimSetting.stimDistribution =  [[task defaults] integerForKey:GRFStimDistributionKey];
	stimSetting.minTargetOnTimeMS = [[task defaults] integerForKey:GRFMinTargetMSKey];
	stimSetting.meanTargetOnTimeMS = [[task defaults] integerForKey:GRFMeanTargetMSKey];
	stimSetting.maxTargetOnTimeMS = [[task defaults] integerForKey:GRFMaxTargetMSKey];
	stimSetting.changeScale =  [[task defaults] integerForKey:GRFChangeScaleKey];
	stimSetting.orientationChanges =  [[task defaults] integerForKey:GRFOrientationChangesKey];
	stimSetting.maxChangeDeg =  [[task defaults] floatForKey:GRFMaxDirChangeDegKey];
	stimSetting.minChangeDeg =  [[task defaults] floatForKey:GRFMinDirChangeDegKey];
	stimSetting.changeRemains =  [[task defaults] boolForKey:GRFChangeRemainKey];
	
	return &stimSetting;
}



// used in randUnitInterval()
#define kIA					16807
#define kIM					2147483647
#define kAM					(1.0 / kIM)
#define kIQ					127773
#define kIR					2836
#define kNTAB				32
#define kNDIV				(1 + (kIM - 1) / kNTAB)
#define kEPS				1.2e-7
#define kRNMX				(1.0 - kEPS)

float randUnitInterval(long *idum) {

	int j;
	long k;
	static long iy = 0;
	static long iv[kNTAB];
	float temp;	
	
	if (*idum <= 0 || !iy) {
		if (-(*idum) < 1)
			*idum = 1;
		else *idum = -(*idum);
		
		for (j = kNTAB + 7; j >= 0; j--) {
			k = (*idum) / kIQ;
			*idum = kIA * (*idum - k * kIQ) - kIR * k;
			if (*idum < 0)
				*idum += kIM;
			if (j < kNTAB)
				iv[j] = *idum;		
		}
		iy = iv[0];	
	}
	k = (*idum) / kIQ;
	*idum = kIA * (*idum - k * kIQ) - kIR *k;
	
	if (*idum < 0)
		*idum += kIM;	
	j = iy / kNDIV;
	iy = iv[j];
	iv[j] = *idum;
	
	temp = kAM * iy;

	if (temp > kRNMX)
		return kRNMX;
	else
		return temp;
}
	

// Get the parameters from user defaults that control what trials are displayed in a block, and put them
// into a structure.

void updateBlockStatus(void)
{
	long index;
	NSArray *changeArray;
	NSDictionary *entryDict;
	
	blockStatus.changes = [[task defaults] integerForKey:GRFOrientationChangesKey];
	blockStatus.instructTrials = [[task defaults] integerForKey:GRFInstructionTrialsKey];
	blockStatus.blockLimit = [[task defaults] integerForKey:GRFBlockLimitKey];
	changeArray = [[task defaults] arrayForKey:GRFChangeArrayKey];
	for (index = 0; index < blockStatus.changes; index++) {
		entryDict = [changeArray objectAtIndex:index];
		(blockStatus.orientationChangeDeg)[index] = [[entryDict valueForKey:GRFChangeKey] floatValue];
		blockStatus.validReps[index] = [[entryDict valueForKey:GRFValidRepsKey] longValue];
		blockStatus.invalidReps[index] = [[entryDict valueForKey:GRFInvalidRepsKey] longValue];
	}
}


