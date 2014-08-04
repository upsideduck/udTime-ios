//
//  MonthDetailTVC.m
//  udTime
//
//  Created by Johan Adell on 10/04/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "MonthDetailTVC.h"
#import "WorkAddTVC.h"
#import "AWAddTVC.h"
#import "AppDelegate.h"
#import "Work.h"
#import "Break.h"
#import "Asworktime.h"
#import "Againstworktime.h"
#import "Time.h"
#import "WorkEditTVC.h"
#import "AWEditTVC.h"

@interface MonthDetailTVC ()
@property (nonatomic, strong) NSArray *workArr;
@property (nonatomic, strong) NSArray *asworktimeArr;
@property (nonatomic, strong) NSArray *againstworktimeArr;
@property (nonatomic, strong) NSMutableArray *datasource;
@property (nonatomic, strong) NSArray *sections;
@end

@implementation MonthDetailTVC

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (NSMutableArray *)datasource{
    if(!_datasource) _datasource = [[NSMutableArray alloc] init];
    return _datasource;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIManagedDocument *document = [(AppDelegate *)[[UIApplication sharedApplication] delegate] document];
    if (document.documentState == UIDocumentStateNormal) {
        self.managedObjectContext = document.managedObjectContext;
        
    }
    
   
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handlemonthStatsUpdated:)                                                     name:@"monthStatsUpdated"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleperiodsStatsUpdated:)                                                     name:@"periodsStatsUpdated"
                                               object:nil];
    [self reloadStats];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    NSArray *datesInMonth = [self datesOfMonthNumber:[self.month.month integerValue] ofYearNumber:[self.month.year integerValue]];
    
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"Edit Work"])
    {
        // Get reference to the destination view controller
        WorkEditTVC *wetvc = [segue destinationViewController];
        
        // Pass any objects to the view controller here, like...
        
        if([sender isKindOfClass:[UITableViewCell class]]) {
            // wdtvc.managedObjectContext = self.managedObjectContext;
            NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
            Work *work = self.datasource[indexPath.section][indexPath.row];
            wetvc.work = work;
            wetvc.managedObjectContext = self.managedObjectContext;
        }
    
    }else  if ([[segue identifier] isEqualToString:@"Edit AW"]){
        // Get reference to the destination view controller
        AWEditTVC *awetvc = [segue destinationViewController];
        
        // Pass any objects to the view controller here, like...
        
        if([sender isKindOfClass:[UITableViewCell class]]) {
            // wdtvc.managedObjectContext = self.managedObjectContext;
            NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
            id obj = self.datasource[indexPath.section][indexPath.row];
            awetvc.awItem = obj;
            awetvc.managedObjectContext = self.managedObjectContext;
            if([obj isKindOfClass:[Asworktime class]]){
                awetvc.type = @"asworktime";
                NSLog(@"AsWorktime");
            }else if([obj isKindOfClass:[Againstworktime class]]){
                awetvc.type = @"againstworktime";
            }else{
                NSLog(@"???");
            }
            
        }
    }else if ([[segue identifier] isEqualToString:@"Add New Work Segue"]){
        // Get reference to the destination view controller
        UINavigationController *uinc = [segue destinationViewController];
        WorkAddTVC *watvc = (WorkAddTVC *)[uinc viewControllers][0];
        
        // Pass any objects to the view controller here, like...
        watvc.managedObjectContext = self.managedObjectContext;
        
        watvc.lowerDateLimit = [datesInMonth firstObject];
        watvc.upperDateLimit = [[datesInMonth lastObject] dateByAddingTimeInterval:60*60*24];
    }else if ([[segue identifier] isEqualToString:@"Add New AW Segue"] && [sender integerValue] == 1){
        // Get reference to the destination view controller
        UINavigationController *uinc = [segue destinationViewController];
        AWAddTVC *awatvc = (AWAddTVC *)[uinc viewControllers][0];
        // Pass any objects to the view controller here, like...
        awatvc.managedObjectContext = self.managedObjectContext;
        awatvc.mainType = @"againstworktime";
        awatvc.lowerDateLimit = [datesInMonth firstObject];
        awatvc.upperDateLimit = [[datesInMonth lastObject] dateByAddingTimeInterval:60*60*24];
    }else if ([[segue identifier] isEqualToString:@"Add New AW Segue"] && [sender integerValue] == 2){
        // Get reference to the destination view controller
        UINavigationController *uinc = [segue destinationViewController];
        AWAddTVC *awatvc = (AWAddTVC *)[uinc viewControllers][0];
        // Pass any objects to the view controller here, like...
        awatvc.managedObjectContext = self.managedObjectContext;
        awatvc.mainType = @"asworktime";
        awatvc.lowerDateLimit = [datesInMonth firstObject];
        awatvc.upperDateLimit = [[datesInMonth lastObject] dateByAddingTimeInterval:60*60*24];
    }
}

- (IBAction)addItem:(UIBarButtonItem *)sender
{
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:@"Add new:" delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Work",@"Reduced work time",@"As work time", nil];
    
    [actionSheet showInView:[UIApplication sharedApplication].keyWindow];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0: //Add work
            [self performSegueWithIdentifier:@"Add New Work Segue" sender:self];
            break;
        case 1: //Add Reduced work time
            [self performSegueWithIdentifier:@"Add New AW Segue" sender:[NSNumber numberWithInteger:buttonIndex]];
            break;
        case 2: //Add as work time
            [self performSegueWithIdentifier:@"Add New AW Segue" sender:[NSNumber numberWithInteger:buttonIndex]];
            break;
        default:
            break;
    }
}

-(void)reloadStats{
     self.datasource = nil;  //reset datasource
    
    self.workArr = [[self.month.workperiods allObjects] sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"starttime"
                                                                                                                  ascending:YES]]];
    self.asworktimeArr = [[self.month.asworktimeperiods allObjects] sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"date"
                                                                                                                              ascending:YES]]];
    self.againstworktimeArr = [[self.month.againstworktimeperiods allObjects] sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"date"
                                                                                                             
                                                                                                                                        ascending:YES]]];
    self.sections = [self datesOfMonthNumber:[self.month.month integerValue] ofYearNumber:[self.month.year integerValue]];
    
    for (int i = 0; i < [self.sections count]; i++) {
        [self.datasource addObject:[[NSMutableArray alloc] init]];
    }
    
    for (int i = 0; i < [self.sections count]; i++) {
        for (Againstworktime *aw in self.againstworktimeArr) {
            if([self isSameDayWithDate1:aw.date date2:self.sections[i]]){
                [self.datasource[i] addObject:aw];
            }
        }
        for (Asworktime *as in self.asworktimeArr) {
            if([self isSameDayWithDate1:as.date date2:self.sections[i]]){
                [self.datasource[i] addObject:as];
            }
        }
        for (Work *work in self.workArr) {
            if([self isSameDayWithDate1:work.starttime date2:self.sections[i]]){
                [self.datasource[i] addObject:work];
            }
        }
    }
    [self.tableView reloadData];
}

- (NSArray *)datesOfMonthNumber:(NSInteger)monthNumber ofYearNumber:(NSInteger)yearNumber {
    
    NSDateComponents *comp = [[NSDateComponents alloc] init];
    [comp setMonth:monthNumber];
    [comp setYear:yearNumber];
    [comp setDay:1];
    
    NSCalendar * calendar = [NSCalendar currentCalendar];
    
    NSDate *date = [calendar dateFromComponents:comp];
    
    NSCalendar *cal = [NSCalendar currentCalendar];
    
    NSMutableArray *datesInMonth = [NSMutableArray array];
    NSRange rangeOfDaysThisMonth = [cal rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:date];
    
    NSDateComponents *components = [cal components:(NSDayCalendarUnit | NSMonthCalendarUnit | NSYearCalendarUnit | NSEraCalendarUnit) fromDate:date];
    [components setHour:0];
    [components setMinute:0];
    [components setSecond:0];
    
    for (NSInteger i = rangeOfDaysThisMonth.location; i < NSMaxRange(rangeOfDaysThisMonth); ++i) {
        [components setDay:i];
        NSDate *dayInMonth = [cal dateFromComponents:components];
        [datesInMonth addObject:dayInMonth];
    }
    
    return datesInMonth;
}

- (BOOL)isSameDayWithDate1:(NSDate*)date1 date2:(NSDate*)date2 {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    NSDateComponents* comp1 = [calendar components:unitFlags fromDate:date1];
    NSDateComponents* comp2 = [calendar components:unitFlags fromDate:date2];
    
    return [comp1 day]   == [comp2 day] &&
    [comp1 month] == [comp2 month] &&
    [comp1 year]  == [comp2 year];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    
    // Return the number of sections.
    return [self.sections count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.datasource[section] count];
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"EEE, yyyy-MM-dd"];
    return [df stringFromDate:self.sections[section]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;;
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    
    id period = self.datasource[indexPath.section][indexPath.row];
    if ([period isKindOfClass:[Work class]]) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"Work cell"];
        Work *work = (Work *)period;
        cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", [formatter stringFromDate:work.starttime], [formatter stringFromDate:work.endtime]] ;
        NSInteger breakTime = 0;
        NSArray *breaks = [work.breaks allObjects];
        for(Break *breakP in breaks){
            breakTime += [breakP.endtime timeIntervalSinceDate:breakP.starttime];
        }
        NSNumber *totaledWorkedTime = [[NSNumber alloc] initWithInteger:([work.endtime timeIntervalSinceDate:work.starttime] - breakTime)];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"Break: %@, Total worked time: %@", [Time secondsToReadableTime:[[NSNumber alloc] initWithInteger:breakTime]], [Time secondsToReadableTime:totaledWorkedTime]];
    }else if ([period isKindOfClass:[Asworktime class]]){
        Asworktime *aw = (Asworktime *)period;
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"As/Againstworktime Cell"];
        cell.textLabel.text = [NSString stringWithFormat:@"%@", aw.type];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [Time secondsToReadableTime:aw.time]];
    }else if ([period isKindOfClass:[Againstworktime class]]){
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"As/Againstworktime Cell"];
        Againstworktime *aw = (Againstworktime *)period;
        cell.textLabel.text = [NSString stringWithFormat:@"%@", aw.type];
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [Time secondsToReadableTime:aw.time]];
    }
    
    return cell;
}

- (void)handlemonthStatsUpdated:(NSNotification *)note {
    [self.tableView reloadData];
}

- (void)handleperiodsStatsUpdated:(NSNotification *)note {
    
    [self reloadStats];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
