//
//  AWProtocol.h
//  udTime
//
//  Created by Johan Adell on 27/07/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

@protocol accessAsworkAndAgainstworkItems <NSObject>
@required
-(NSString *)accessType;
-(NSNumber *)accessTime;
-(NSNumber *)accessId;
-(void)setAccessTime:(NSNumber *)time;
@end
