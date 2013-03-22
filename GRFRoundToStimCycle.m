//
//  GRFRoundToStimCycle.m
//  GaborRFMap
//
//  Created by Incheol Kang on 3/6/07.
//  Copyright 2007. All rights reserved.
//

#import "GRF.h"
#import "GRFRoundToStimCycle.h"

@implementation GRFRoundToStimCycle

+ (Class)transformedValueClass;
{ 
	return [NSNumber class]; 
}

+ (BOOL)allowsReverseTransformation;
{
	return YES;
}

- (id)reverseTransformedValue:(id)value;
{
	long stimulusMS, interstimMS;
	float output;
	
	stimulusMS = [[task defaults] integerForKey:GRFStimDurationMSKey]; 
	interstimMS = [[task defaults] integerForKey:GRFInterstimMSKey];
	
	output = round((float)[value longValue] / (stimulusMS + interstimMS)) * (stimulusMS + interstimMS);
    return [NSNumber numberWithLong:output];
}

- (id)transformedValue:(id)value;
{
	long output;
	output = [value longValue];
	return [NSNumber numberWithLong:output];
}

@end
