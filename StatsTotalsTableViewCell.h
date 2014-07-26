//
//  WeekTotalsTableViewCell.h
//  udTime
//
//  Created by Johan Adell on 24/03/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StatsTotalsTableViewCell : UITableViewCell
@property (strong, nonatomic) IBOutlet UILabel *statPeriod;
@property (strong, nonatomic) IBOutlet UILabel *worked;
@property (strong, nonatomic) IBOutlet UILabel *totalDifference;
@property (strong, nonatomic) IBOutlet UILabel *periodDifference;

@end
