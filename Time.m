//
//  Time.m
//  udTime
//
//  Created by Johan Adell on 19/07/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "Time.h"

@implementation Time

+(NSString *)secondsToReadableTime:(NSNumber *)seconds{
    int secondsValue = [seconds intValue];
    int forHours = secondsValue / 3600,
    remainder = secondsValue % 3600,
    forMinutes = remainder / 60,
    forSeconds = remainder % 60;
    
    NSString *minutesString = (forMinutes < 10) ? [NSString stringWithFormat:@"0%i",forMinutes] : [NSString stringWithFormat:@"%i",forMinutes];
    NSString *secondsString = (forSeconds < 10) ? [NSString stringWithFormat:@"0%i",forSeconds] : [NSString stringWithFormat:@"%i",forSeconds];
    
    return [NSString stringWithFormat:@"%i:%@:%@", forHours, minutesString, secondsString];
}

@end
