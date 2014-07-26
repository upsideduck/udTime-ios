//
//  BreaksForWorkTVC.h
//  udTime
//
//  Created by Johan Adell on 19/07/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Work.h"

@interface BreaksForWorkTVC : UITableViewController
@property (strong, nonatomic) Work *work;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@end
