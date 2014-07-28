//
//  AWEditTVC.h
//  udTime
//
//  Created by Johan Adell on 27/07/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Asworktime.h"
#import "Againstworktime.h"
#import "AWProtocol.h"

extern NSString *asworktime;
extern NSString *againstworktime;


@interface AWEditTVC : UITableViewController
@property (strong, nonatomic) id<accessAsworkAndAgainstworkItems> awItem;
@property (strong, nonatomic) NSString *type;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@end
