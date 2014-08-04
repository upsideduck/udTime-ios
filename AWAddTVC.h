//
//  AWAddTVC.h
//  udTime
//
//  Created by Johan Adell on 31/07/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AWAddTVC : UITableViewController<UIPickerViewDataSource, UIPickerViewDelegate>
@property (nonatomic, strong) NSDate *lowerDateLimit;
@property (nonatomic, strong) NSDate *upperDateLimit;
@property (strong, nonatomic) NSString *mainType;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@end
