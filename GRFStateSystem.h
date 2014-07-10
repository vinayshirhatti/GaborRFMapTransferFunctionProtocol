//
//  GRFStateSystem.h
//  Experiment
//
//  Copyright (c) 2006. All rights reserved.
//

#import "GRF.h"

#define		kFixOnSound				@"6C"
#define		kFixateSound			@"7G"
#define		kStimOnSound			@"5C"
#define		kStimOffSound			@"5C"
#define 	kCorrectSound			@"Correct"
#define 	kNotCorrectSound		@"NotCorrect"
#define     kSoundClose             @"200Hz100msSq" // [Vinay] - added for the Transfer Function Task
#define     kSoundOpen              @"4G"  // [Vinay] - added for the Transfer Function Task

extern long					eotCode;			// End Of Trial code
extern LLEyeWindow			*fixWindow;
extern LLScheduleController *scheduler;
extern LLEyeWindow			*respWindow;
extern TrialDesc			trial;
extern LLEyeWindow          *bigWindow; // [Vinay] - added for tfunc protocol

@interface GRFStateSystem : LLStateSystem {

}

@end

