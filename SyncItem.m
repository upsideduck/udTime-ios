//
//  SyncItem.m
//  udTime
//
//  Created by Johan Adell on 23/01/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "SyncItem.h"

@implementation SyncItem
NSInteger SYNC_STARTWORK = 1;
NSInteger SYNC_STARTBREAK = 2;
NSInteger SYNC_ENDBREAK = 3;
NSInteger SYNC_ENDWORK = 4;

+ (NSArray *)syncTypesLabels{
    return @[@"Start work", @"Start break", @"End break",@"End work"];
}

- (id)initWithSyncType:(NSInteger)type andTime:(NSInteger)time
{
    self = [super init];
    if(self) {
        self.syncType = type;
        self.time = time;
    }
    self.syncId = [[NSDate date] timeIntervalSince1970] + ((arc4random() % 1000) + 1);      //should be unique
    return(self);
}

- (NSString *)SyncTypeLabel{
    return [self SyncTypeLabelFor:self.syncType];
}

- (NSString *)SyncTypeLabelFor:(NSInteger)type{
    switch (type) {
        case 1:
            return @"Start work";
            break;
        case 4:
            return @"End work";
            break;
        case 2:
            return @"Start break";
            break;
        case 3:
            return @"End break";
            break;
        default:
            return @"Unknown";
            break;
    }
}

-(id)copyWithZone:(NSZone *)zone
{
    // We'll ignore the zone for now
    SyncItem *aCopy = [[SyncItem alloc] init];
    aCopy.syncType = self.syncType;
    aCopy.time = self.time;
    aCopy.syncId = self.syncId;
    
    return aCopy;
}

@end
