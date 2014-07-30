//
//  WorkEditTVC.m
//  udTime
//
//  Created by Johan Adell on 19/07/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "WorkEditTVC.h"
#import "Break.h"
#import "BreaksForWorkTVC.h"
#import "Time.h"
#import "AFNetworking.h"
#import "udTimeServer.h"

@interface WorkEditTVC ()
@property (strong, nonatomic) IBOutlet UITableViewCell *starttimeCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *endtimeCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *breaksCell;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (strong, nonatomic) IBOutlet UIDatePicker *starttimePicker;
@property (strong, nonatomic) IBOutlet UIDatePicker *endtimePicker;
@property (nonatomic) BOOL starttimePickerIsShowing;
@property (nonatomic) BOOL endtimePickerIsShowing;
@property (nonatomic) NSInteger numberOfBreaks;
@end

@implementation WorkEditTVC

#define kStarttimePickerIndex 1
#define kEndtimePickerIndex 3
#define kPickerCellHeight 162

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    [self.starttimePicker setDate:self.work.starttime];
    [self.endtimePicker setDate:self.work.endtime];
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self reloadStats];
}

-(BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender{
    if ([identifier isEqualToString:@"List Breaks"] && self.numberOfBreaks > 0){
        return YES;
    }
    
    return NO;
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"List Breaks"])
    {
        // Get reference to the destination view controller
        BreaksForWorkTVC *bfwtvc = [segue destinationViewController];
        bfwtvc.work = self.work;
        // Pass any objects to the view controller here, like...
        bfwtvc.managedObjectContext = self.managedObjectContext;
        
    }
}

-(void)reloadStats{
    NSDateFormatter *dateTimeformatter = [[NSDateFormatter alloc] init];
    [dateTimeformatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    self.starttimeCell.detailTextLabel.text = [dateTimeformatter stringFromDate:self.work.starttime];
    self.endtimeCell.detailTextLabel.text = [dateTimeformatter stringFromDate:self.work.endtime];
    
    self.numberOfBreaks = [self.work.breaks count];
    NSInteger breakTime = 0;
    NSArray *breaks = [self.work.breaks allObjects];
    for(Break *breakP in breaks){
        breakTime += [breakP.endtime timeIntervalSinceDate:breakP.starttime];
    }
    
    self.breaksCell.detailTextLabel.text = [NSString stringWithFormat:@"%@ (%ld breaks)", [Time secondsToReadableTime:[NSNumber numberWithInteger:breakTime]], (long)self.numberOfBreaks];
    
    if (self.numberOfBreaks == 0){
        self.breaksCell.accessoryType = UITableViewCellAccessoryNone;
        self.breaksCell.selectionStyle = UITableViewCellSelectionStyleNone;
    }else{
        self.breaksCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        self.breaksCell.selectionStyle = UITableViewCellSelectionStyleDefault;
    }
}

- (IBAction)saveWork:(UIBarButtonItem *)sender{
    NSDateFormatter *dateTimeformatter = [[NSDateFormatter alloc] init];
    [dateTimeformatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *starttime = [dateTimeformatter dateFromString:self.starttimeCell.detailTextLabel.text];
    NSDate *endtime = [dateTimeformatter dateFromString:self.endtimeCell.detailTextLabel.text];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"action": @"updatework",
                                 @"id": [self.work.workid stringValue],
                                 @"start_time": [NSString stringWithFormat:@"%.f", [starttime timeIntervalSince1970]],
                                 @"end_time": [NSString stringWithFormat:@"%.f", [endtime timeIntervalSince1970]],
                                 @"username": [udTimeServer username],
                                 @"password": [udTimeServer password],
                                 @"output": @"json"};
    [manager GET:API_URL
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             //NSLog(@"%@", responseObject);
             if(![udTimeServer successOnResult:responseObject onAction:@"results.login"]) {
                 NSLog(@"Login error");
                 return;
             }else if(![udTimeServer successOnResult:responseObject onAction:@"results.updatework"]) {
                 NSLog(@"Update error");
                 return;
             }
             
             //First do a manual update if eveything successfull then sync with server
             self.work.starttime = starttime;
             self.work.endtime = endtime;
             if (self.managedObjectContext) {
                 [udTimeServer synchronizeInternalDBWithServerOn:self.managedObjectContext];
             }
             [self.navigationController popViewControllerAnimated:YES];
             
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             
             NSLog(@"Major failure");
         }];
}


- (IBAction)delteWork:(UIButton *)sender{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"action": @"removework",
                                 @"id": [self.work.workid stringValue],
                                 @"username": [udTimeServer username],
                                 @"password": [udTimeServer password],
                                 @"output": @"json"};
    [manager GET:API_URL
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             //NSLog(@"%@", responseObject);
             if(![udTimeServer successOnResult:responseObject onAction:@"results.login"]) {
                 NSLog(@"Login error");
                 return;
             }else if(![udTimeServer successOnResult:responseObject onAction:@"results.removework"]) {
                 NSLog(@"Remove error");
                 return;
             }
             
             [self.managedObjectContext deleteObject:self.work];
             if (self.managedObjectContext) {
                 [udTimeServer synchronizeInternalDBWithServerOn:self.managedObjectContext];
             }
             [self.navigationController popViewControllerAnimated:YES];
             
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             
             NSLog(@"Major failure");
         }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == (kStarttimePickerIndex - 1)){
        if (self.starttimePickerIsShowing){
            [self hidePickerCellAt:kStarttimePickerIndex];
        }else {
            [self showPickerCellAt:kStarttimePickerIndex];
        }
        [self hidePickerCellAt:kEndtimePickerIndex];
    }else if (indexPath.row == (kEndtimePickerIndex - 1)){
        if (self.endtimePickerIsShowing){
            [self hidePickerCellAt:kEndtimePickerIndex];
        }else {
            [self showPickerCellAt:kEndtimePickerIndex];
        }
        [self hidePickerCellAt:kStarttimePickerIndex];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)showPickerCellAt:(NSInteger)row {
    
    if(row == kStarttimePickerIndex) self.starttimePickerIsShowing = YES;
    else if(row == kEndtimePickerIndex) self.endtimePickerIsShowing = YES;
    
    [self.tableView beginUpdates];
    
    [self.tableView endUpdates];
    
    UIPickerView *picker;
    if(row == kStarttimePickerIndex)
        picker = (UIPickerView *)self.starttimePicker;
    else if(row == kEndtimePickerIndex)
        picker = (UIPickerView *)self.endtimePicker;
    
    picker.hidden = NO;
    picker.alpha = 0.0f;
    
    [UIView animateWithDuration:0.25 animations:^{
        picker.alpha = 1.0f;
    }];
}

- (void)hidePickerCellAt:(NSInteger)row{
    
    if(row == kStarttimePickerIndex) self.starttimePickerIsShowing = NO;
    else if(row == kEndtimePickerIndex) self.endtimePickerIsShowing = NO;
    
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    
    UIPickerView *picker;
    if(row == kStarttimePickerIndex)
        picker = (UIPickerView *)self.starttimePicker;
    else if(row == kEndtimePickerIndex)
        picker = (UIPickerView *)self.endtimePicker;
    
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         picker.alpha = 0.0f;
                     }
                     completion:^(BOOL finished){
                         picker.hidden = YES;
                     }];
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat height = self.tableView.rowHeight;
    
    if (indexPath.row == kStarttimePickerIndex){
        
        height = self.starttimePickerIsShowing ? kPickerCellHeight : 0.0f;
        
    }else if(indexPath.row == kEndtimePickerIndex){
        
        height = self.endtimePickerIsShowing ? kPickerCellHeight : 0.0f;
    }
    
    return height;
}

- (IBAction)starttimePickerChanged:(UIDatePicker *)sender {
    NSDateFormatter *dateTimeformatter = [[NSDateFormatter alloc] init];
    [dateTimeformatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    self.starttimeCell.detailTextLabel.text = [dateTimeformatter stringFromDate:sender.date];
    
    if ([self.starttimePicker.date isEqualToDate:self.work.starttime] && [self.endtimePicker.date isEqualToDate:self.work.endtime]) self.saveButton.enabled = NO;
    else
        self.saveButton.enabled = YES;
    
}

- (IBAction)endttimePickerChanged:(UIDatePicker *)sender {
    NSDateFormatter *dateTimeformatter = [[NSDateFormatter alloc] init];
    [dateTimeformatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    self.endtimeCell.detailTextLabel.text = [dateTimeformatter stringFromDate:sender.date];
    
    if ([self.starttimePicker.date isEqualToDate:self.work.starttime] && [self.endtimePicker.date isEqualToDate:self.work.endtime]) self.saveButton.enabled = NO;
    else
        self.saveButton.enabled = YES;
    
    
}

@end
