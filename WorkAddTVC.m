//
//  WorkAddTVC.m
//  udTime
//
//  Created by Johan Adell on 19/07/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "WorkAddTVC.h"
#import "Work+udTime.h"
#import "BreaksForWorkTVC.h"
#import "Time.h"
#import "AFNetworking.h"
#import "udTimeServer.h"

@interface WorkAddTVC ()
@property (strong, nonatomic) IBOutlet UITableViewCell *starttimeCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *endtimeCell;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (strong, nonatomic) IBOutlet UIDatePicker *starttimePicker;
@property (strong, nonatomic) IBOutlet UIDatePicker *endtimePicker;
@property (nonatomic) BOOL starttimePickerIsShowing;
@property (nonatomic) BOOL endtimePickerIsShowing;
@property (nonatomic) NSInteger numberOfBreaks;
@end

@implementation WorkAddTVC

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

-(NSDate *)lowerDateLimit{
    if (!_lowerDateLimit) _lowerDateLimit = [[NSDate alloc] initWithTimeIntervalSince1970:0];
    return _lowerDateLimit;
}

-(NSDate *)upperDateLimit{
    if (!_upperDateLimit) _upperDateLimit = [[NSDate alloc] initWithTimeIntervalSince1970:999999999999];
    return _upperDateLimit;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self setupStartValues];
    NSLog(@"On WorkAdd %@",self.managedObjectContext);
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleServerSynched:)                                                     name:@"serverSynched"
                                               object:nil];
}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

-(void)setupStartValues{
    NSDateFormatter *dateTimeformatter = [[NSDateFormatter alloc] init];
    [dateTimeformatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    self.starttimePicker.minimumDate = self.lowerDateLimit;
    self.starttimePicker.maximumDate = self.upperDateLimit;
    self.starttimePicker.date = [NSDate date];
    self.endtimePicker.minimumDate = self.lowerDateLimit;
    self.endtimePicker.maximumDate = self.upperDateLimit;
    self.endtimePicker.date = [NSDate date];
    
    self.starttimeCell.detailTextLabel.text = [dateTimeformatter stringFromDate:[NSDate date]];
    self.endtimeCell.detailTextLabel.text = [dateTimeformatter stringFromDate:[NSDate date]];
    

}

- (IBAction)saveWork:(UIBarButtonItem *)sender{
    NSDateFormatter *dateTimeformatter = [[NSDateFormatter alloc] init];
    [dateTimeformatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *starttime = [dateTimeformatter dateFromString:self.starttimeCell.detailTextLabel.text];
    NSDate *endtime = [dateTimeformatter dateFromString:self.endtimeCell.detailTextLabel.text];
    //NSString *modafter = [NSString stringWithFormat:@"%d", (int)[[udTimeServer timestampOfLastUpdatedPeriodOn:self.managedObjectContext] timeIntervalSince1970]];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"action": @"setwork",
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
                 [udTimeServer showServerMessage:@"Problem logging in"];
                 NSLog(@"Login error");
                 return;
             }else if(![udTimeServer successOnResult:responseObject onAction:@"results.setwork"]) {
                 [udTimeServer showServerMessage:@"Could not add work"];
                 NSLog(@"Add error");
                 return;
             }
             [udTimeServer synchronizeInternalDBWithServerOn:self.managedObjectContext];
             //[self dismissViewControllerAnimated:YES completion:nil];
             
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             [udTimeServer showServerMessage:@"Could not reach server"];
             NSLog(@"Major failure");
         }];
}

- (IBAction)cancelButton:(id)sender {
     [self dismissViewControllerAnimated:YES completion:nil];
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
    
    
}

- (IBAction)endttimePickerChanged:(UIDatePicker *)sender {
    NSDateFormatter *dateTimeformatter = [[NSDateFormatter alloc] init];
    [dateTimeformatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    
    self.endtimeCell.detailTextLabel.text = [dateTimeformatter stringFromDate:sender.date];
    
    
}

- (void)handleServerSynched:(NSNotification *)note {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
