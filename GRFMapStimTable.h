//
//  GRFMapStimTable.h
//  GaborRFMap
//
//  Created by John Maunsell on 11/2/07.
//  Copyright 2007. All rights reserved.
//

#import "GRF.h"

@interface GRFMapStimTable : NSObject
{
	long blocksDone;
	long blockLimit;
	BOOL doneList[kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues][kMaxMapValues];
    long mapIndex;                  // index to instance of GRFMapStimTable
	int stimRemainingInBlock;
	int stimInBlock;
	NSMutableArray *currentStimList;
}

- (long)blocksDone;
- (void)dumpStimList:(NSMutableArray *)list listIndex:(long)listIndex;
- (float)contrastValueFromIndex:(long)index count:(long)count min:(float)min max:(float)max;
- (float)tfValueFromIndex:(long)index count:(long)count min:(float)min max:(float)max; // [Vinay] - map tf levels the same way as contrast, but make sure that the maximum level doesn't exceed (refresh rate)/2
- (id)initWithIndex:(long)index;
- (float)linearValueWithIndex:(long)index count:(long)count min:(float)min max:(float)max;
- (float)logValueWithIndex:(long)index count:(long)count min:(float)min max:(float)max;
- (void)makeMapStimList:(NSMutableArray *)list index:(long)index lastFrame:(long)lastFrame pTrial:(TrialDesc *)pTrial;
- (MappingBlockStatus)mappingBlockStatus;
- (MapSettings)mapSettings;
- (void)newBlock;
- (void)reset;
- (long)stimInBlock;
- (void)tallyStimList:(NSMutableArray *)list  count:(long)count;
- (void)tallyStimList:(NSMutableArray *)list  upToFrame:(long)frameLimit;
- (long)stimDoneInBlock;
- (void)updateBlockParameters;

@end
