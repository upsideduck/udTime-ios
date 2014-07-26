//
//  SyncItem.h
//  udTime
//
//  Created by Johan Adell on 23/01/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Period.h"

@interface SyncItem : NSObject <NSCopying>

extern NSInteger SYNC_STARTWORK;
extern NSInteger SYNC_ENDWORK;
extern NSInteger SYNC_STARTBREAK;
extern NSInteger SYNC_ENDBREAK;

@property (nonatomic) NSInteger time;
@property (nonatomic) NSInteger syncType;
@property (nonatomic) NSInteger syncId;

- (id)initWithSyncType:(NSInteger)syncType andTime:(NSInteger)time;
- (NSString *)SyncTypeLabelFor:(NSInteger)type;
- (NSString *)SyncTypeLabel;
+ (NSArray*)syncTypesLabels;
@end
