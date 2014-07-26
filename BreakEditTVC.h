//
//  BreakEditTVC.h
//  udTime
//
//  Created by Johan Adell on 19/07/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Break.h"

@interface BreakEditTVC : UITableViewController
@property (strong, nonatomic) Break *breakItem;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@end
