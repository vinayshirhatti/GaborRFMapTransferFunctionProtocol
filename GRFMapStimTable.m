//
//  GRFMapStimTable.m
//  GaborRFMap
//
//  Created by John Maunsell on 11/2/07.
//  Copyright 2007. All rights reserved.
//

#import "GRF.h"
#import "GRFMapStimTable.h"

static long GRFMapStimTableCounter = 0;

@implementation GRFMapStimTable

- (long)blocksDone;
{
	return blocksDone;
}

- (void)dumpStimList:(NSMutableArray *)list listIndex:(long)listIndex;
{
	StimDesc stimDesc;
	long index;
	
	NSLog(@"Mapping Stim List %ld", listIndex);
	NSLog(@"index type onFrame offFrame azi ele sig sf  ori");
	for (index = 0; index < [list count]; index++) {
		[[list objectAtIndex:index] getValue:&stimDesc];
		NSLog(@"%4ld:\t%4d\t%4ld\t%4ld\t%4.1f\t%4.1f\t%4.1f\t%4.1f\t%4.1f\t%4.1f", index, stimDesc.stimType, 
			stimDesc.stimOnFrame, stimDesc.stimOffFrame, stimDesc.azimuthDeg, stimDesc.elevationDeg,
			stimDesc.sigmaDeg, stimDesc.spatialFreqCPD, stimDesc.directionDeg,stimDesc.contrastPC);
	}
	NSLog(@"\n");
}

- (id) init
{
	if (!(self = [super init])) {
		return nil;
	}
    mapIndex = GRFMapStimTableCounter++;
	[self updateBlockParameters];	
	[self newBlock];
	return self;
}

- (float)linearValueWithIndex:(long)index count:(long)count min:(float)min max:(float)max;
{
	return (count < 2) ? min : (min + ((max - min) / (count - 1)) * index);
}

- (float)logValueWithIndex:(long)index count:(long)count min:(float)min max:(float)max;
{
	return (count < 2) ? min : min * (powf(max / min, (float)index/(count - 1)));
}

/* makeMapStimList

Make a mapping stimulus lists for one trial.  The list is constructed as an NSMutableArray of StimDesc or 
StimDesc structures.

In the simplest case, we just draw n unused entries from the done table.  If there are fewer than n entries
remaining, we take them all, clear the table, and then proceed.  We also make a provision for the case where 
several full table worth's will be needed to make the list.  Whenever we take all the entries remaining in 
the table, we simply draw them in order and then use shuffleStimList() to randomize their order.  Shuffling 
does not span the borders between successive doneTables, to ensure that each stimulus pairing will 
be presented n times before any appears n + 1 times, even if each appears several times within 
one trial.

Two types of padding stimuli are used.  Padding stimuli are inserted in the list after the target, so
that the stream of stimuli continues through the reaction time.  Padding stimuli are also optionally
put at the start of the trial.  This is so the first few stimulus presentations, which might have 
response transients, are not counted.  The number of padding stimuli at the end of the trial is 
determined by stimRateHz and reactTimeMS.  The number of padding stimuli at the start of the trial
is determined by rate of presentation and stimLeadMS.  Note that it is possible to set parameters 
so that there will never be anything except targets and padding stimuli (e.g., with a short 
maxTargetS and a long stimLeadMS).
*/

- (void)makeMapStimList:(NSMutableArray *)list index:(long)index lastFrame:(long)lastFrame
{
	long stim, frame, mapDurFrames, interDurFrames;
	float frameRateHz;
	StimDesc stimDesc;
	int localFreshCount;
	BOOL localList[kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues];
	float azimuthDegMin, azimuthDegMax, elevationDegMin, elevationDegMax, sigmaDegMin, sigmaDegMax, spatialFreqCPDMin, 
                spatialFreqCPDMax, directionDegMin, directionDegMax, radiusSigmaRatio, contrastPCMin, contrastPCMax;
	
	NSArray *stimTableDefaults = [[task defaults] arrayForKey:@"GRFStimTables"];
	NSDictionary *minDefaults = [stimTableDefaults objectAtIndex:0];
	NSDictionary *maxDefaults = [stimTableDefaults objectAtIndex:1];
	
	radiusSigmaRatio = [[[task defaults] objectForKey:GRFMapStimRadiusSigmaRatioKey] floatValue];
	
    switch (index) {
        case 0:
        default:
            azimuthDegMin = [[minDefaults objectForKey:@"azimuthDeg0"] floatValue];
            elevationDegMin = [[minDefaults objectForKey:@"elevationDeg0"] floatValue];
            spatialFreqCPDMin = [[minDefaults objectForKey:@"spatialFreqCPD0"] floatValue];
            sigmaDegMin = [[minDefaults objectForKey:@"sigmaDeg0"] floatValue];
            directionDegMin = [[minDefaults objectForKey:@"orientationDeg0"] floatValue];
            contrastPCMin = [[minDefaults objectForKey:@"contrastPC0"] floatValue];

            azimuthDegMax = [[maxDefaults objectForKey:@"azimuthDeg0"] floatValue];
            elevationDegMax = [[maxDefaults objectForKey:@"elevationDeg0"] floatValue];
            sigmaDegMax = [[maxDefaults objectForKey:@"sigmaDeg0"] floatValue];
            spatialFreqCPDMax = [[maxDefaults objectForKey:@"spatialFreqCPD0"] floatValue];
            directionDegMax = [[maxDefaults objectForKey:@"orientationDeg0"] floatValue];
            contrastPCMax = [[maxDefaults objectForKey:@"contrastPC0"] floatValue];
            break;
        case 1:
            azimuthDegMin = [[minDefaults objectForKey:@"azimuthDeg1"] floatValue];
            elevationDegMin = [[minDefaults objectForKey:@"elevationDeg1"] floatValue];
            spatialFreqCPDMin = [[minDefaults objectForKey:@"spatialFreqCPD1"] floatValue];
            sigmaDegMin = [[minDefaults objectForKey:@"sigmaDeg1"] floatValue];
            directionDegMin = [[minDefaults objectForKey:@"orientationDeg1"] floatValue];
            contrastPCMin = [[minDefaults objectForKey:@"contrastPC1"] floatValue];

            azimuthDegMax = [[maxDefaults objectForKey:@"azimuthDeg1"] floatValue];
            elevationDegMax = [[maxDefaults objectForKey:@"elevationDeg1"] floatValue];
            spatialFreqCPDMax = [[maxDefaults objectForKey:@"spatialFreqCPD1"] floatValue];
            sigmaDegMax = [[maxDefaults objectForKey:@"sigmaDeg1"] floatValue];
            directionDegMax = [[maxDefaults objectForKey:@"orientationDeg1"] floatValue];
            contrastPCMax = [[maxDefaults objectForKey:@"contrastPC1"] floatValue];
            break;
	}
	
	memcpy(&localList, &doneList, sizeof(doneList));
	localFreshCount = stimRemainingInBlock;
	frameRateHz = [[task stimWindow] frameRateHz];
	
	mapDurFrames = MAX(1, ceil([[task defaults] integerForKey:GRFMapStimDurationMSKey] / 1000.0 * frameRateHz));
	interDurFrames = ceil([[task defaults] integerForKey:GRFMapInterstimDurationMSKey] / 1000.0 * frameRateHz);
	
	[list removeAllObjects];
	
	for (stim = frame = 0; frame < lastFrame; stim++, frame += mapDurFrames + interDurFrames) {
		
		int azimuthIndex, elevationIndex, sigmaIndex, spatialFreqIndex, directionDegIndex, contrastIndex;
		NSDictionary *countsDict = (NSDictionary *)[[[task defaults] arrayForKey:@"GRFStimTableCounts"] objectAtIndex:0];
		int azimuthCount, elevationCount, sigmaCount, spatialFreqCount, directionDegCount, contrastCount;
		int startAzimuthIndex, startElevationIndex, startSigmaIndex, startSpatialFreqIndex, startDirectionDegIndex, startContrastIndex;
		BOOL stimDone = YES;
	
		azimuthCount = [[countsDict objectForKey:@"azimuthCount"] intValue];
		elevationCount = [[countsDict objectForKey:@"elevationCount"] intValue];
		sigmaCount = [[countsDict objectForKey:@"sigmaCount"] intValue];
		spatialFreqCount = [[countsDict objectForKey:@"spatialFreqCount"] intValue];
		directionDegCount = [[countsDict objectForKey:@"orientationCount"] intValue];
		contrastCount = [[countsDict objectForKey:@"contrastCount"] intValue];
                
		startAzimuthIndex = azimuthIndex = rand() % azimuthCount;
		startElevationIndex = elevationIndex = rand() % elevationCount;
		startSigmaIndex = sigmaIndex = rand() % sigmaCount;
		startSpatialFreqIndex = spatialFreqIndex = rand() % spatialFreqCount;
		startDirectionDegIndex = directionDegIndex = rand() % directionDegCount;
		startContrastIndex = contrastIndex = rand() % contrastCount;
		
		for (;;) {
			stimDone=localList[azimuthIndex][elevationIndex][sigmaIndex][spatialFreqIndex][directionDegIndex][contrastIndex];
			if (!stimDone) {
				break;
			}
			if ((azimuthIndex = ((azimuthIndex+1)%azimuthCount)) == startAzimuthIndex) {
				if ((elevationIndex = ((elevationIndex+1)%elevationCount)) == startElevationIndex) {
					if ((sigmaIndex = ((sigmaIndex+1)%sigmaCount)) == startSigmaIndex) {
						if ((spatialFreqIndex = ((spatialFreqIndex+1)%spatialFreqCount)) == startSpatialFreqIndex) {
							if ((directionDegIndex = ((directionDegIndex+1)%directionDegCount)) == startDirectionDegIndex) {
								if ((contrastIndex = ((contrastIndex+1)%contrastCount)) == startContrastIndex) {
									NSLog(@"Failed to find empty entry: Expected %d", localFreshCount);
									exit(0);
								}
							}
						}
					}
				}
			}
		}
					

		// this stimulus has not been done - add it to the list

		stimDesc.gaborIndex = index + 1;
		stimDesc.sequenceIndex = stim;
		stimDesc.stimOnFrame = frame;
		stimDesc.stimOffFrame = frame + mapDurFrames;
		stimDesc.stimType = kValidStim;
		
		stimDesc.azimuthIndex = azimuthIndex;
		stimDesc.elevationIndex = elevationIndex;
		stimDesc.sigmaIndex = sigmaIndex;
		stimDesc.spatialFreqIndex = spatialFreqIndex;
		stimDesc.directionIndex = directionDegIndex;
		stimDesc.contrastIndex = contrastIndex;
		
		stimDesc.azimuthDeg = [self linearValueWithIndex:azimuthIndex count:azimuthCount min:azimuthDegMin max:azimuthDegMax];
		stimDesc.elevationDeg = [self linearValueWithIndex:elevationIndex count:elevationCount min:elevationDegMin max:elevationDegMax];
		stimDesc.sigmaDeg = [self linearValueWithIndex:sigmaIndex count:sigmaCount min:sigmaDegMin max:sigmaDegMax];
		stimDesc.radiusDeg = stimDesc.sigmaDeg * radiusSigmaRatio;
		stimDesc.spatialFreqCPD = [self logValueWithIndex:spatialFreqIndex count:spatialFreqCount min:spatialFreqCPDMin max:spatialFreqCPDMax];
		stimDesc.directionDeg = [self linearValueWithIndex:directionDegIndex count:directionDegCount min:directionDegMin max:directionDegMax];
		
		stimDesc.contrastPC = contrastPCMin + ((contrastPCMax - contrastPCMin) / (contrastCount-1)) * contrastIndex;
		
		//[[task defaults] floatForKey:@"GRFMapStimContrastPC"];
		
		// Unused field
		
		stimDesc.orientationChangeDeg = 0.0;
		
		[list addObject:[NSValue valueWithBytes:&stimDesc objCType:@encode(StimDesc)]];
		
		localList[azimuthIndex][elevationIndex][sigmaIndex][spatialFreqIndex][directionDegIndex][contrastIndex] = TRUE;
		//		NSLog(@"%d %d %d %d %d",stimDesc.azimuthIndex,stimDesc.elevationIndex,stimDesc.sigmaIndex,stimDesc.spatialFreqIndex,stimDesc.directionIndex);
		if (--localFreshCount == 0) {
			bzero(&localList,sizeof(doneList));
			localFreshCount = stimInBlock;
		}
	}
//	[self dumpStimList:list listIndex:index];
	[currentStimList release];
	currentStimList = [list retain];
	// Count the stimlist as completed
}

- (MappingBlockStatus)mappingBlockStatus;
{
	MappingBlockStatus status;
    
	status.stimDone = stimInBlock - stimRemainingInBlock;
	status.blocksDone = blocksDone;
	status.stimLimit = stimInBlock;
	status.blockLimit = blockLimit;
	return status;
}

- (MapSettings)mapSettings;
{
 	MapSettings settings;
  	NSDictionary *countsDict = (NSDictionary *)[[[task defaults] arrayForKey:@"GRFStimTableCounts"] objectAtIndex:0];
  	NSDictionary *valuesDict;
   
	settings.azimuthDeg.n = [[countsDict objectForKey:@"azimuthCount"] intValue];
	settings.elevationDeg.n = [[countsDict objectForKey:@"elevationCount"] intValue];
	settings.sigmaDeg.n = [[countsDict objectForKey:@"sigmaCount"] intValue];
	settings.spatialFreqCPD.n = [[countsDict objectForKey:@"spatialFreqCount"] intValue];
	settings.directionDeg.n = [[countsDict objectForKey:@"orientationCount"] intValue];
	settings.contrastPC.n = [[countsDict objectForKey:@"contrastCount"] intValue];
 
  	valuesDict = (NSDictionary *)[[[task defaults] arrayForKey:@"GRFStimTables"] objectAtIndex:0];
    settings.azimuthDeg.minValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"azimuthDeg%ld", mapIndex]] floatValue];
    settings.elevationDeg.minValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"elevationDeg%ld", mapIndex]] floatValue];
    settings.sigmaDeg.minValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"sigmaDeg%ld", mapIndex]] floatValue];
    settings.spatialFreqCPD.minValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"spatialFreqCPD%ld", mapIndex]] floatValue];
    settings.directionDeg.minValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"orientationDeg%ld", mapIndex]] floatValue];
    settings.contrastPC.minValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"contrastPC%ld", mapIndex]] floatValue];
 
 	valuesDict = (NSDictionary *)[[[task defaults] arrayForKey:@"GRFStimTables"] objectAtIndex:1];
    settings.azimuthDeg.maxValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"azimuthDeg%ld", mapIndex]] floatValue];
    settings.elevationDeg.maxValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"elevationDeg%ld", mapIndex]] floatValue];
    settings.sigmaDeg.maxValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"sigmaDeg%ld", mapIndex]] floatValue];
    settings.spatialFreqCPD.maxValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"spatialFreqCPD%ld", mapIndex]] floatValue];
    settings.directionDeg.maxValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"orientationDeg%ld", mapIndex]] floatValue];
    settings.contrastPC.maxValue = [[valuesDict objectForKey:[NSString stringWithFormat:@"contrastPC%ld", mapIndex]] floatValue];

    return settings;
}

- (void)newBlock;
{
	bzero(&doneList, sizeof(doneList));
	stimRemainingInBlock = stimInBlock;
}

- (void)reset;
{
	[self updateBlockParameters];
	[self newBlock];
	blocksDone = 0;
}

- (void)tallyStimList:(NSMutableArray *)list  count:(long)count;
{
	// count = the number of stims that have been processed completely.
	//         The list is processed in order so the first count stims
	//         can be marked done.
	StimDesc stimDesc;
	int stim;
	NSMutableArray *l;
	
	if (list == nil) {
		l = currentStimList;
	}
	else {
		l = list;
	}
	
	for (stim = 0; stim < count; stim++) {
		short a=0, e=0, sf=0, sig=0, o=0, c=0;
		NSValue *val = [l objectAtIndex:stim];
		
		[val getValue:&stimDesc];
		a=stimDesc.azimuthIndex;
		e=stimDesc.elevationIndex;
		sf=stimDesc.spatialFreqIndex;
		sig=stimDesc.sigmaIndex;
		o=stimDesc.directionIndex;
		c=stimDesc.contrastIndex;
		
		doneList[a][e][sig][sf][o][c] = TRUE;
		if (--stimRemainingInBlock == 0 ) {
			[self newBlock];
			blocksDone++;
		}
	}
	return;
}

- (void)tallyStimList:(NSMutableArray *)list  upToFrame:(long)frameLimit;
{
	StimDesc stimDesc;
	long a, e, sf, sig, o, stim, c;
	NSValue *val;
	NSMutableArray *l;
	
	l = (list == nil) ? currentStimList : list;
	for (stim = 0; stim < [l count]; stim++) {
		val = [l objectAtIndex:stim];
		[val getValue:&stimDesc];
		if (stimDesc.stimOffFrame > frameLimit) {
			break;
		}
		a = stimDesc.azimuthIndex;
		e = stimDesc.elevationIndex;
		sf = stimDesc.spatialFreqIndex;
		sig = stimDesc.sigmaIndex;
		o = stimDesc.directionIndex;
		c = stimDesc.contrastIndex;
		doneList[a][e][sig][sf][o][c] = YES;
		if (--stimRemainingInBlock == 0 ) {
			[self newBlock];
			blocksDone++;
		}
	}
	return;
}

- (long)stimDoneInBlock;
{
	return stimInBlock - stimRemainingInBlock;
}

- (long)stimInBlock;
{
	return stimInBlock;
}

- (void)updateBlockParameters;
{
	long azimuthCount, elevationCount, sigmaCount, spatialFreqCount, directionCount, contrastCount;
	NSDictionary *countsDict = (NSDictionary *)[[[task defaults] arrayForKey:@"GRFStimTableCounts"] objectAtIndex:0];

	azimuthCount = [[countsDict objectForKey:@"azimuthCount"] intValue];
	elevationCount = [[countsDict objectForKey:@"elevationCount"] intValue];
	sigmaCount = [[countsDict objectForKey:@"sigmaCount"] intValue];
	spatialFreqCount = [[countsDict objectForKey:@"spatialFreqCount"] intValue];
	directionCount = [[countsDict objectForKey:@"orientationCount"] intValue];
	contrastCount = [[countsDict objectForKey:@"contrastCount"] intValue];
	
	stimInBlock = stimRemainingInBlock = azimuthCount * elevationCount * sigmaCount * spatialFreqCount * directionCount * contrastCount;
	blockLimit = [[task defaults] integerForKey:GRFMappingBlocksKey];
}

@end
