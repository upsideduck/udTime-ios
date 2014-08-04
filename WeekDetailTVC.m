//
//  WeekDetailCDTVC.m
//  udTime
//
//  Created by Johan Adell on 31/03/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "WeekDetailTVC.h"
#import "AWAddTVC.h"
#import "AppDelegate.h"
#import "Work.h"
#import "Break.h"
#import "Asworktime.h"
#import "Againstworktime.h"
#import "WorkEditTVC.h"
#import "Time.h"
#import "AWEditTVC.h"
#import "WorkAddTVC.h"

@interface WeekDetailTVC ()
@property (nonatomic, strong) NSArray *workArr;
@property (nonatomic, strong) NSArray *asworktimeArr;
@property (nonatomic, strong) NSArray *againstworktimeArr;
@property (nonatomic, strong) NSMutableArray *datasource;
@property (nonatomic, strong) NSArray *sections;
@end

@implementation WeekDetailTVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (NSMutableArray *)datasource{
    if(!_datasource) _datasource = [[NSMutableArray alloc] init];
    return _datasource;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
    NSDateComponents *comp = [[NSDateComponents alloc] init];
    [comp setWeekOfYear:[self.week.week integerValue]];
    [comp setYear:[self.week.year integerValue]];
    [comp setHour:0];
    [comp setWeekday:2];
    
    NSCalendar * calendar = [NSCalendar currentCalendar];
    //[calendar setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    
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
        
        watvc.lowerDateLimit = [calendar dateFromComponents:comp];
        watvc.upperDateLimit = [NSDate dateWithTimeIntervalSince1970:([[calendar dateFromComponents:comp] timeIntervalSince1970] + 60*60*24*7)];
    }else if ([[segue identifier] isEqualToString:@"Add New AW Segue"] && [sender integerValue] == 1){
        // Get reference to the destination view controller
        UINavigationController *uinc = [segue destinationViewController];
        AWAddTVC *awatvc = (AWAddTVC *)[uinc viewControllers][0];
        // Pass any objects to the view controller here, like...
        awatvc.managedObjectContext = self.managedObjectContext;
        awatvc.mainType = @"againstworktime";
        awatvc.lowerDateLimit = [calendar dateFromComponents:comp];
        awatvc.upperDateLimit = [NSDate dateWithTimeIntervalSince1970:([[calendar dateFromComponents:comp] timeIntervalSince1970] + 60*60*24*7)];
    }else if ([[segue identifier] isEqualToString:@"Add New AW Segue"] && [sender integerValue] == 2){
        // Get reference to the destination view controller
        UINavigationController *uinc = [segue destinationViewController];
        AWAddTVC *awatvc = (AWAddTVC *)[uinc viewControllers][0];
        // Pass any objects to the view controller here, like...
        awatvc.managedObjectContext = self.managedObjectContext;
        awatvc.mainType = @"asworktime";
        awatvc.lowerDateLimit = [calendar dateFromComponents:comp];
        awatvc.upperDateLimit = [NSDate dateWithTimeIntervalSince1970:([[calendar dateFromComponents:comp] timeIntervalSince1970] + 60*60*24*7)];

    }

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIManagedDocument *document = [(AppDelegate *)[[UIApplication sharedApplication] delegate] document];
    if (document.documentState == UIDocumentStateNormal) {
        self.managedObjectContext = document.managedObjectContext;
        
    }
    [self reloadStats];
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleweekStatsUpdated:)                                                     name:@"weekStatsUpdated"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleperiodsStatsUpdated:)                                                     name:@"periodsStatsUpdated"
                                               object:nil];
    [self reloadStats];
    NSLog(@"On WeekDet %@",self.managedObjectContext);
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

-(void)reloadStats{
    self.datasource = nil;  //reset datasource
    
    self.workArr = [[self.week.workperiods allObjects] sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"starttime"
                                                                                                                 ascending:YES]]];
    self.asworktimeArr = [[self.week.asworktimeperiods allObjects] sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"date"
                                                                                                                             ascending:YES]]];
    self.againstworktimeArr = [[self.week.againstworktimeperiods allObjects] sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"date"
                                                                                                                                       ascending:YES]]];
    for (int i = 0; i < 7; i++) {
        [self.datasource addObject:[[NSMutableArray alloc] init]];
    }
    self.sections = [self datesOfWeekNumber:[self.week.week integerValue] ofYearNumber:[self.week.year integerValue]];
    
    for (int i = 0; i < 7; i++) {
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

- (NSArray *)datesOfWeekNumber:(NSInteger)weeknumber ofYearNumber:(NSInteger)yearNumber {
    
    NSDateComponents *comp = [[NSDateComponents alloc] init];
    [comp setWeekOfYear:weeknumber];
    [comp setYear:yearNumber];
    [comp setHour:5];
    [comp setWeekday:2];
    
    NSCalendar * calendar = [NSCalendar currentCalendar];
    //calendar.firstWeekday = 2;
    
    NSDate *date = [calendar dateFromComponents:comp];
    
    NSDateComponents *offset = [[NSDateComponents alloc] init];
    NSMutableArray* dates = [NSMutableArray arrayWithObject:date];
    
    for (int i = 1; i < 7; i++) {
        [offset setDay:i];
        NSDate *nextDay = [calendar dateByAddingComponents:offset toDate:date options:0];
        [dates addObject:nextDay];
    }
    
    return dates;
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

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
    UITableViewCell *cell;
   
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
- (void)handleweekStatsUpdated:(NSNotification *)note {
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
