/*
GRFStimuli.m
Stimulus generation for GaborRFMap
March 29, 2003 JHRM
*/

#import "GRF.h"
#import "GaborRFMap.h"
#import "GRFStimuli.h"
#import "UtilityFunctions.h"

#define kDefaultDisplayIndex	1		// Index of stim display when more than one display
#define kMainDisplayIndex		0		// Index of main stimulus display
#define kPixelDepthBits			32		// Depth of pixels in stimulus window
#define	stimWindowSizePix		250		// Height and width of stim window on main display

#define kTargetBlue				0.0
#define kTargetGreen			1.0
#define kMidGray				0.5
#define kPI						(atan(1) * 4)
#define kTargetRed				1.0
#define kDegPerRad				57.295779513

#define kAdjusted(color, contrast)  (kMidGray + (color - kMidGray) / 100.0 * contrast)

NSString *stimulusMonitorID = @"GaborRFMap Stimulus";

@implementation GRFStimuli

- (void) dealloc;
{
	[[task monitorController] removeMonitorWithID:stimulusMonitorID];
	[taskStimList release];
	[mapStimList0 release];
	[mapStimList1 release];
	[fixSpot release];
    [targetSpot release];
    [gabors release];

    [super dealloc];
}

- (void)doFixSettings;
{
	[fixSpot runSettingsDialog];
}

- (void)doGabor0Settings;
{
	[[self taskGabor] runSettingsDialog];
}

- (void)dumpStimList;
{
	StimDesc stimDesc;
	long index;
	
	NSLog(@"\ncIndex stim0Type stim1Type stimOnFrame stimOffFrame SF");
	for (index = 0; index < [taskStimList count]; index++) {
		[[taskStimList objectAtIndex:index] getValue:&stimDesc];
		NSLog(@"%4ld:\t%d\t %ld %ld %.2f", index, stimDesc.stimType, stimDesc.stimOnFrame, stimDesc.stimOffFrame, 
              stimDesc.spatialFreqCPD);
		NSLog(@"stim is %s", (stimDesc.stimType == kValidStim) ? "valid" : 
              ((stimDesc.stimType == kTargetStim) ? "target" : "other"));
	}
	NSLog(@"\n");
}

- (void)erase;
{
	[[task stimWindow] lock];
    glClearColor(kMidGray, kMidGray, kMidGray, 0);
    glClear(GL_COLOR_BUFFER_BIT);
	[[NSOpenGLContext currentContext] flushBuffer];
	[[task stimWindow] unlock];
}

- (id)init;
{
	float frameRateHz = [[task stimWindow] frameRateHz]; 
	
	if (!(self = [super init])) {
		return nil;
	}
	monitor = [[[LLIntervalMonitor alloc] initWithID:stimulusMonitorID 
					description:@"Stimulus frame intervals"] autorelease];
	[[task monitorController] addMonitor:monitor];
	[monitor setTargetIntervalMS:1000.0 / frameRateHz];
	taskStimList = [[NSMutableArray alloc] init];
	mapStimList0 = [[NSMutableArray alloc] init];
	mapStimList1 = [[NSMutableArray alloc] init];
	
// Create and initialize the visual stimuli

	gabors = [[NSArray arrayWithObjects:[self initGabor:YES],
                            [self initGabor:NO], [self initGabor:NO], nil] retain];
	[[gabors objectAtIndex:kMapGabor0] setAchromatic:YES];
	[[gabors objectAtIndex:kMapGabor1] setAchromatic:YES];
	fixSpot = [[LLFixTarget alloc] init];
	[fixSpot bindValuesToKeysWithPrefix:@"GRFFix"];
    targetSpot = [[LLFixTarget alloc] init];
	//[targetSpot bindValuesToKeysWithPrefix:@"GRFFix"];


	return self;
}

- (LLGabor *)initGabor:(BOOL)bindTemporalFreq;
{
	static long counter = 0;
	LLGabor *gabor;
	
	gabor = [[LLGabor alloc] init];				// Create a gabor stimulus
	[gabor setDisplays:[[task stimWindow] displays] displayIndex:[[task stimWindow] displayIndex]];
    if (bindTemporalFreq) {
        [gabor removeKeysFromBinding:[NSArray arrayWithObjects:LLGaborDirectionDegKey, 
                    LLGaborTemporalPhaseDegKey, LLGaborContrastKey, LLGaborSpatialPhaseDegKey, nil]];
    }
    else {
        [gabor removeKeysFromBinding:[NSArray arrayWithObjects:LLGaborDirectionDegKey, LLGaborTemporalPhaseDegKey,
                    LLGaborContrastKey, LLGaborSpatialPhaseDegKey, LLGaborTemporalFreqHzKey, nil]];
    }
	[gabor bindValuesToKeysWithPrefix:[NSString stringWithFormat:@"GRF%ld", counter++]];
	return gabor;
}

/*

makeStimList()

Make stimulus lists for one trial.  Three lists are made: one for the task gabor, and one each for the
mapping gabors at the two locations.  Each list is constructed as an NSMutableArry of StimDesc or StimDesc
structures.

Task Stim List: The target in the specified targetIndex position (0 based counting). 

Mapping Stim List: The list is constructed so that each stimulus type appears n times before any appears (n+1).
Details of the construction, as well as monitoring how many stimuli and blocks have been completed are handled
by mapStimTable.

*/

- (void)makeStimLists:(TrialDesc *)pTrial;
{
	long targetIndex;
	long stim, nextStimOnFrame, lastStimOffFrame = 0;
	long stimDurFrames, interDurFrames, stimJitterPC, interJitterPC, stimJitterFrames, interJitterFrames;
	long stimDurBase, interDurBase;
	float frameRateHz;
	StimDesc stimDesc;
	LLGabor *taskGabor = [self taskGabor];
	
    trial = *pTrial;
	[taskStimList removeAllObjects];
	targetIndex = MIN(pTrial->targetIndex, pTrial->numStim);
	
// Now we make a second pass through the list adding the stimulus times.  We also insert 
// the target stimulus (if this isn't a catch trial) and set the invalid stimuli to kNull
// if this is an instruction trial.

	frameRateHz = [[task stimWindow] frameRateHz];
	stimJitterPC = [[task defaults] integerForKey:GRFStimJitterPCKey];
	interJitterPC = [[task defaults] integerForKey:GRFInterstimJitterPCKey];
	stimDurFrames = ceil([[task defaults] integerForKey:GRFStimDurationMSKey] / 1000.0 * frameRateHz);
	interDurFrames = ceil([[task defaults] integerForKey:GRFInterstimMSKey] / 1000.0 * frameRateHz);
	stimJitterFrames = round(stimDurFrames / 100.0 * stimJitterPC);
	interJitterFrames = round(interDurFrames / 100.0 * interJitterPC);
	stimDurBase = stimDurFrames - stimJitterFrames;
	interDurBase = interDurFrames - interJitterFrames;
/*
    // randomize
    if ([[task defaults] boolForKey:GRFRandTaskGaborDirectionKey]) {
        [taskGabor setDirectionDeg:rand() % 180];
    }
*/
	pTrial->targetOnTimeMS = 0;
    
 	for (stim = nextStimOnFrame = 0; stim < pTrial->numStim; stim++) {

// Set the default values
	
		stimDesc.gaborIndex = kTaskGabor;
		stimDesc.sequenceIndex = stim;
		stimDesc.stimType = kValidStim;
		stimDesc.contrastPC = 100.0*[taskGabor contrast];
        stimDesc.temporalFreqHz = [taskGabor temporalFreqHz];
		stimDesc.azimuthDeg = [taskGabor azimuthDeg];
		stimDesc.elevationDeg = [taskGabor elevationDeg];
		stimDesc.sigmaDeg = [taskGabor sigmaDeg];
		stimDesc.spatialFreqCPD = [taskGabor spatialFreqCPD];
        stimDesc.directionDeg = [taskGabor directionDeg];
		stimDesc.radiusDeg = [taskGabor radiusDeg];
        stimDesc.temporalModulation = [taskGabor temporalModulation];
	
// If it's not a catch trial and we're in a target spot, set the target 
        
		if (!pTrial->catchTrial) {
			if ((stimDesc.sequenceIndex == targetIndex) ||
                (stimDesc.sequenceIndex > targetIndex && [[task defaults] boolForKey:GRFChangeRemainKey])) {
				stimDesc.stimType = kTargetStim;
				stimDesc.directionDeg += pTrial->orientationChangeDeg;
			}
        }

// Load the information about the on and off frames
	
		stimDesc.stimOnFrame = nextStimOnFrame;
		if (stimJitterFrames > 0) {
			stimDesc.stimOffFrame = stimDesc.stimOnFrame + 
					MAX(1, stimDurBase + (rand() % (2 * stimJitterFrames + 1)));
		}
		else {
			stimDesc.stimOffFrame = stimDesc.stimOnFrame +  MAX(1, stimDurFrames);
		}
		lastStimOffFrame = stimDesc.stimOffFrame;
		if (interJitterFrames > 0) {
			nextStimOnFrame = stimDesc.stimOffFrame + 
				MAX(1, interDurBase + (rand() % (2 * interJitterFrames + 1)));
		}
		else {
			nextStimOnFrame = stimDesc.stimOffFrame + MAX(0, interDurFrames);
		}

// Set to null if HideTaskGaborKey is set
        if ([[task defaults] boolForKey:GRFHideTaskGaborKey])
            stimDesc.stimType = kNullStim;
        
// Put the stimulus descriptor into the list

		[taskStimList addObject:[NSValue valueWithBytes:&stimDesc objCType:@encode(StimDesc)]];

// Save the estimated target on time

		if (stimDesc.stimType == kTargetStim) {
			pTrial->targetOnTimeMS = stimDesc.stimOnFrame / frameRateHz * 1000.0;	// this is a theoretical value
		}
	}
//	[self dumpStimList];
	
// The task stim list is done, now we need to get the mapping stim lists

    [[(GaborRFMap*)task mapStimTable0] makeMapStimList:mapStimList0 index:0 lastFrame:lastStimOffFrame pTrial:pTrial];
	[[(GaborRFMap*)task mapStimTable1] makeMapStimList:mapStimList1 index:1 lastFrame:lastStimOffFrame pTrial:pTrial];

}
	
- (void)loadGabor:(LLGabor *)gabor withStimDesc:(StimDesc *)pSD;
{	
	if (pSD->spatialFreqCPD == 0) {					// Change made by Incheol and Kaushik to get gaussians
		[gabor directSetSpatialPhaseDeg:90.0];
	}
	[gabor directSetSigmaDeg:pSD->sigmaDeg];		// *** Should be directSetSigmaDeg
	[gabor directSetRadiusDeg:pSD->radiusDeg];
	[gabor directSetAzimuthDeg:pSD->azimuthDeg elevationDeg:pSD->elevationDeg];
	[gabor directSetSpatialFreqCPD:pSD->spatialFreqCPD];
	[gabor directSetDirectionDeg:pSD->directionDeg];
	[gabor directSetContrast:pSD->contrastPC / 100.0];
    [gabor directSetTemporalFreqHz:pSD->temporalFreqHz];
    if (pSD->temporalFreqHz == [[task stimWindow] frameRateHz]/2) { // [Vinay] - added this to adjust the temporal phase when the temporal frequency = (refresh rate)/2 (the maximum level allowed) so that each frame doesn't capture the zero level but the max and min levels every alternate frame
        [gabor directSetTemporalPhaseDeg:90.0];
    }
    [gabor setTemporalModulation:pSD->temporalModulation];
}

- (void)clearStimLists:(TrialDesc *)pTrial
{
	// tally stim lists first?
	[mapStimList0 removeAllObjects];
	[mapStimList1 removeAllObjects];
}

- (LLGabor *)mappingGabor0;
{
	return [gabors objectAtIndex:kMapGabor0];
}

- (LLGabor *)mappingGabor1;
{
	return [gabors objectAtIndex:kMapGabor1];
}

- (LLIntervalMonitor *)monitor;
{
	return monitor;
}

- (void)presentStimSequence;
{
    long index, trialFrame, taskGaborFrame;
	NSArray *stimLists;
	StimDesc stimDescs[kGabors], *pSD;
	long stimIndices[kGabors];
	long stimOffFrames[kGabors];
	long gaborFrames[kGabors];
	LLGabor *theGabor;
	NSAutoreleasePool *threadPool;
	BOOL listDone = NO;
//	long stimCounter = 0;
    BOOL useSingleITC18;
	
    threadPool = [[NSAutoreleasePool alloc] init];		// create a threadPool for this thread
	[LLSystemUtil setThreadPriorityPeriodMS:1.0 computationFraction:0.250 constraintFraction:1.0];
	
	stimLists = [[NSArray arrayWithObjects:taskStimList, mapStimList0, mapStimList1, nil] retain];

// Set up the stimulus calibration, including the offset then present the stimulus sequence

	[[task stimWindow] lock];
	[[task stimWindow] setScaleOffsetDeg:[[task eyeCalibrator] offsetDeg]];
	[[task stimWindow] scaleDisplay];

// Set up the gabors

	[gabors makeObjectsPerformSelector:@selector(store)];
	for (index = 0; index < kGabors; index++) {
		stimIndices[index] = 0;
		gaborFrames[index] = 0;
		[[[stimLists objectAtIndex:index] objectAtIndex:0] getValue:&stimDescs[index]];
		[self loadGabor:[gabors objectAtIndex:index] withStimDesc:&stimDescs[index]];
		stimOffFrames[index] = stimDescs[index].stimOffFrame;
	}
    
    // Set up the targetSpot if needed
/*
    if ([[task defaults] boolForKey:GRFAlphaTargetDetectionTaskKey]) {
        [targetSpot setState:YES];
        NSColor *targetColor = [[fixSpot foreColor]retain];
        [targetSpot setForeColor:[targetColor colorWithAlphaComponent:[[task defaults] floatForKey:GRFTargetAlphaKey]]];
        [targetSpot setOuterRadiusDeg:[[task defaults]floatForKey:GRFTargetRadiusKey]];
        [targetSpot setShape:kLLCircle];
        [targetColor release];
    }
*/	
	targetOnFrame = -1;

    for (trialFrame = taskGaborFrame = 0; !listDone && !abortStimuli; trialFrame++) {
		glClear(GL_COLOR_BUFFER_BIT);
		for (index = 0; index < kGabors; index++) {
			if (trialFrame >= stimDescs[index].stimOnFrame && trialFrame < stimDescs[index].stimOffFrame) {
				if (stimDescs[index].stimType != kNullStim) {
                    theGabor = [gabors objectAtIndex:index];
                    [theGabor directSetFrame:[NSNumber numberWithLong:gaborFrames[index]]];	// advance for temporal modulation
                    [theGabor draw];
/*
                    if (!trial.catchTrial && index == kTaskGabor && stimDescs[index].stimType == kTargetStim) {
                        [targetSpot setAzimuthDeg:stimDescs[index].azimuthDeg elevationDeg:stimDescs[index].elevationDeg];
                        [targetSpot draw];
                    }
*/
                    gaborFrames[index]++;
                }
			}
		}
		[fixSpot draw];
		[[NSOpenGLContext currentContext] flushBuffer];
		glFinish();
		if (trialFrame == 0) {
			[monitor reset];
		}
		else {
			[monitor recordEvent];
		}

// Update Gabors as needed

		for (index = 0; index < kGabors; index++) {
			pSD = &stimDescs[index];

 // If this is the frame after the last draw of a stimulus, post an event declaring it off.  We have to do this first,
 // because the off of one stimulus may occur on the same frame as the on of the next

            useSingleITC18 = [[task defaults] boolForKey:GRFUseSingleITC18Key];
            
			if (trialFrame == stimOffFrames[index]) {
                [[task dataDoc] putEvent:@"stimulusOff" withData:&index];
                [[task dataDoc] putEvent:@"stimulusOffTime"];
                if (!useSingleITC18) {
                    [digitalOut outputEvent:kStimulusOffDigitOutCode withData:index];
                }
				if (++stimIndices[index] >= [[stimLists objectAtIndex:index] count]) {	// no more entries in list
					listDone = YES;
				}
			}
			
// If this is the first frame of a Gabor, post an event describing it

			if (trialFrame == pSD->stimOnFrame) {
				[[task dataDoc] putEvent:@"stimulusOn" withData:&index];
                [[task dataDoc] putEvent:@"stimulusOnTime"];
                [[task dataDoc] putEvent:@"stimulus" withData:pSD];

                if (!useSingleITC18) {
                    [digitalOut outputEvent:kStimulusOnDigitOutCode withData:index];
                }
				// put the digital events
				if (index == kTaskGabor) {
					[digitalOut outputEventName:@"taskGabor" withData:(long)(pSD->stimType)];
				}
				else {
					if (pSD->stimType != kNullStim) {
						if (index == kMapGabor0)
							[digitalOut outputEventName:@"mapping0" withData:(long)(pSD->stimType)];
						if (index == kMapGabor1)
							[digitalOut outputEventName:@"mapping1" withData:(long)(pSD->stimType)];
					}
				}
				
				// Other prperties of the Gabor
				if (index == kMapGabor0 && pSD->stimType != kNullStim && !([[task defaults] boolForKey:GRFHideLeftDigitalKey])) {
					//NSLog(@"Sending left digital codes...");
					[digitalOut outputEventName:@"contrast" withData:(long)(10*(pSD->contrastPC))];
                    [digitalOut outputEventName:@"temporalFreq" withData:(long)(10*(pSD->temporalFreqHz))];
					[digitalOut outputEventName:@"azimuth" withData:(long)(100*(pSD->azimuthDeg))];
					[digitalOut outputEventName:@"elevation" withData:(long)(100*(pSD->elevationDeg))];
					[digitalOut outputEventName:@"orientation" withData:(long)((pSD->directionDeg))];
					[digitalOut outputEventName:@"spatialFreq" withData:(long)(100*(pSD->spatialFreqCPD))];
					[digitalOut outputEventName:@"radius" withData:(long)(100*(pSD->radiusDeg))];
					[digitalOut outputEventName:@"sigma" withData:(long)(100*(pSD->sigmaDeg))];
				}
				
				if (index == kMapGabor1 && pSD->stimType != kNullStim && !([[task defaults] boolForKey:GRFHideRightDigitalKey])) {
					//NSLog(@"Sending right digital codes...");
					[digitalOut outputEventName:@"contrast" withData:(long)(10*(pSD->contrastPC))];
                    [digitalOut outputEventName:@"temporalFreq" withData:(long)(10*(pSD->temporalFreqHz))];
					[digitalOut outputEventName:@"azimuth" withData:(long)(100*(pSD->azimuthDeg))];
					[digitalOut outputEventName:@"elevation" withData:(long)(100*(pSD->elevationDeg))];
					[digitalOut outputEventName:@"orientation" withData:(long)((pSD->directionDeg))];
					[digitalOut outputEventName:@"spatialFreq" withData:(long)(100*(pSD->spatialFreqCPD))];
					[digitalOut outputEventName:@"radius" withData:(long)(100*(pSD->radiusDeg))];
					[digitalOut outputEventName:@"sigma" withData:(long)(100*(pSD->sigmaDeg))];
				}
                
                if (pSD->stimType == kTargetStim) {
					targetPresented = YES;
					targetOnFrame = trialFrame;
                    if (!useSingleITC18) {
                        [digitalOut outputEvent:kTargetOnDigitOutCode withData:(kTargetOnDigitOutCode+1)];
                    }
				}
				stimOffFrames[index] = stimDescs[index].stimOffFrame;		// previous done by now, save time for this one
			}

// If we've drawn the current stimulus for the last time, load the Gabor with the next stimulus settings

			if (trialFrame == stimOffFrames[index] - 1) {
				if ((stimIndices[index] + 1) < [[stimLists objectAtIndex:index] count]) {	// check there are more
					[[[stimLists objectAtIndex:index] objectAtIndex:(stimIndices[index] + 1)] getValue:&stimDescs[index]];
				[self loadGabor:[gabors objectAtIndex:index] withStimDesc:&stimDescs[index]];
					gaborFrames[index] = 0;
				}
			}
		}
    }
	
// If there was no target (catch trial), we nevertheless need to set a valid targetOnFrame time (now)

	targetOnFrame = (targetOnFrame < 0) ? trialFrame : targetOnFrame;

// Clear the display and leave the back buffer cleared

    glClear(GL_COLOR_BUFFER_BIT);
    [[NSOpenGLContext currentContext] flushBuffer];
	glFinish();

	[[task stimWindow] unlock];
	
// The temporal counterphase might have changed some settings.  We restore these here.

	[gabors makeObjectsPerformSelector:@selector(restore)];
	stimulusOn = abortStimuli = NO;
	[stimLists release];
    [threadPool release];
}

- (void)setFixSpot:(BOOL)state;
{
	[fixSpot setState:state];
	if (state) {
		if (!stimulusOn) {
			[[task stimWindow] lock];
			[[task stimWindow] setScaleOffsetDeg:[[task eyeCalibrator] offsetDeg]];
			[[task stimWindow] scaleDisplay];
			glClear(GL_COLOR_BUFFER_BIT);
			[fixSpot draw];
			[[NSOpenGLContext currentContext] flushBuffer];
			[[task stimWindow] unlock];
		}
	}
}

// Shuffle the stimulus sequence by repeated passed along the list and paired substitution

- (void)shuffleStimListFrom:(short)start count:(short)count;
{
	long rep, reps, stim, index, temp, indices[kMaxOriChanges];
	NSArray *block;
	
	reps = 5;	
	for (stim = 0; stim < count; stim++) {			// load the array of indices
		indices[stim] = stim;
	}
	for (rep = 0; rep < reps; rep++) {				// shuffle the array of indices
		for (stim = 0; stim < count; stim++) {
			index = rand() % count;
			temp = indices[index];
			indices[index] = indices[stim];
			indices[stim] = temp;
		}
	}
	block = [taskStimList subarrayWithRange:NSMakeRange(start, count)];
	for (index = 0; index < count; index++) {
		[taskStimList replaceObjectAtIndex:(start + index) withObject:[block objectAtIndex:indices[index]]];
	}
}

- (void)startStimSequence;
{
	if (stimulusOn) {
		return;
	}
	stimulusOn = YES;
	targetPresented = NO;
	[NSThread detachNewThreadSelector:@selector(presentStimSequence) toTarget:self
				withObject:nil];
}

- (BOOL)stimulusOn;
{
	return stimulusOn;
}

// Stop on-going stimulation and clear the display

- (void)stopAllStimuli;
{
	if (stimulusOn) {
		abortStimuli = YES;
		while (stimulusOn) {};
	}
	else {
		[stimuli setFixSpot:NO];
		[self erase];
	}
}

- (void)tallyStimLists:(long)count
{
	[[(GaborRFMap *)task mapStimTable0] tallyStimList:mapStimList0 count:count];
	[[(GaborRFMap *)task mapStimTable1] tallyStimList:mapStimList1 count:count];
}

- (long)targetOnFrame;
{
	return targetOnFrame;
}

- (BOOL)targetPresented;
{
	return targetPresented;
}

- (LLGabor *)taskGabor;
{
	return [gabors objectAtIndex:kTaskGabor];
}

@end
