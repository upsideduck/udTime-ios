//
//  Period.h
//  udTime
//
//  Created by Johan Adell on 05/01/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Period : NSObject <NSCopying>
@property (nonatomic) NSInteger starttime;
@property (nonatomic) NSInteger endtime;
@property (nonatomic) NSInteger dbId;
@property (nonatomic) NSInteger modified;

-(NSDictionary *)exportDictionary;
-(void)import:(NSDictionary *)dictionary;
@end
