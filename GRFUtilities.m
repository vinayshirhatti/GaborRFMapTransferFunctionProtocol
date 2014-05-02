//
//  GRFUtilities.m
//  GaborRFMap
//
//  Created by Bram on 4/18/13.
//
//

#import "GRFUtilities.h"

enum {kUseLeftEye = 0, kUseRightEye, kUseBinocular};

NSString *GRFEyeToUseKey = @"GRFEyeToUse";

@implementation GRFUtilities

+ (BOOL)inWindow:(LLEyeWindow *)window;
{
    BOOL inWindow = NO;
    
    switch ([[task defaults] integerForKey:GRFEyeToUseKey]) {
        case kUseLeftEye:
        default:
            inWindow = [window inWindowDeg:([task currentEyesDeg])[kLeftEye]];
            break;
        case kUseRightEye:
            inWindow = [window inWindowDeg:([task currentEyesDeg])[kRightEye]];
            break;
        case kUseBinocular:
            inWindow = [window inWindowDeg:([task currentEyesDeg])[kLeftEye]] &&
            [window inWindowDeg:([task currentEyesDeg])[kRightEye]];
            break;
    }
    return inWindow;
}


@end
