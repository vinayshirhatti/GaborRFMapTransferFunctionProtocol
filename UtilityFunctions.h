//
//  UtilityFunctions.h
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#include "GRF.h"

void			announceEvents(void);
BehaviorSetting *getBehaviorSetting(void);
StimSetting		*getStimSetting(void);
void			requestReset(void);
void			reset(void);
BOOL			selectTrial(long *pIndex);
float			spikeRateFromStimValue(float normalizedValue);
void			updateCatchTrialPC(void);
float			randUnitInterval(long *idum);
void			updateBlockStatus(void);
