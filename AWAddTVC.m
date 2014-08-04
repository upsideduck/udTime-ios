//
//  AWAddTVC.m
//  udTime
//
//  Created by Johan Adell on 31/07/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "AWAddTVC.h"
#import "AFNetworking.h"
#import "udTimeServer.h"

@interface AWAddTVC ()
@property (strong, nonatomic) IBOutlet UITableViewCell *starttimeCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *endtimeCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *timeCell;
@property (strong, nonatomic) IBOutlet UITableViewCell *typeCell;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (strong, nonatomic) IBOutlet UIDatePicker *starttimePicker;
@property (strong, nonatomic) IBOutlet UIDatePicker *endtimePicker;
@property (strong, nonatomic) IBOutlet UIDatePicker *timePicker;
@property (strong, nonatomic) IBOutlet UIPickerView *typePicker;
@property (nonatomic) BOOL starttimePickerIsShowing;
@property (nonatomic) BOOL endtimePickerIsShowing;
@property (nonatomic) BOOL timePickerIsShowing;
@property (nonatomic) BOOL typePickerIsShowing;
@property (strong, nonatomic) NSArray *asTypes;
@property (strong, nonatomic) NSArray *againstTypes;
@property (strong, nonatomic) NSNumber *selectedType;
@end

@implementation AWAddTVC

#define kStarttimePickerIndex 1
#define kEndtimePickerIndex 3
#define kTimePickerIndex 5
#define kTypePickerIndex 7
#define kPickerCellHeight 162
#define kStandardCellHeight 44
#define ASWORKTIME @"asworktime"
#define AGAINSTWORKTIME @"againstworktime"

-(NSString *)mainType{
    if(!_mainType) _mainType = @"asworktime";       //default value
    return _mainType;
}

-(NSNumber *)selectedType{
    if(!_selectedType) _selectedType = [NSNumber numberWithInteger:0];       //default value
    return _selectedType;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    self.asTypes = @[@"Vacation",@"Sick Leave"];
    self.againstTypes = @[@"Holiday"];
    
    self.typePicker.delegate = self;
    self.typePicker.dataSource = self;
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self setupStartValues];
    NSLog(@"On  AWAdd %@",self.managedObjectContext);
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleServerSynched:)                                                     name:@"serverSynched"
                                               object:nil];

}
- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

-(NSDate *)lowerDateLimit{
    if (!_lowerDateLimit) _lowerDateLimit = [[NSDate alloc] initWithTimeIntervalSince1970:0];
    return _lowerDateLimit;
}

-(NSDate *)upperDateLimit{
    if (!_upperDateLimit) _upperDateLimit = [[NSDate alloc] initWithTimeIntervalSince1970:999999999999];
    return _upperDateLimit;
}

-(void)setupStartValues{
    
    if([self.mainType isEqualToString:ASWORKTIME]){
        self.title = @"Addition";
        self.typeCell.detailTextLabel.text = self.asTypes[[self.selectedType integerValue]];
    }else if([self.mainType isEqualToString:AGAINSTWORKTIME]){
        self.title = @"Reduction";
        self.typeCell.detailTextLabel.text = self.againstTypes[[self.selectedType integerValue]];
    }
    
    NSDateFormatter *dateTimeformatter = [[NSDateFormatter alloc] init];
    [dateTimeformatter setDateFormat:@"yyyy-MM-dd"];
    NSDateFormatter *timeformatter = [[NSDateFormatter alloc] init];
    [timeformatter setDateFormat:@"HH:mm:ss"];
    [timeformatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    
    NSDate *initStartdate;
    self.starttimeCell.detailTextLabel.text = [dateTimeformatter stringFromDate:[NSDate date]];
    if([self.lowerDateLimit compare:[NSDate date]] == NSOrderedAscending && [self.upperDateLimit compare:[NSDate date]] == NSOrderedDescending)
        initStartdate = [NSDate date];
    else
        initStartdate = self.lowerDateLimit;
    self.starttimePicker.date = initStartdate;
    self.starttimeCell.detailTextLabel.text = [dateTimeformatter stringFromDate:initStartdate];
    self.starttimePicker.minimumDate = self.lowerDateLimit;
    self.starttimePicker.maximumDate = self.upperDateLimit;
    
    NSDate *initEnddate;
    self.endtimePicker.minimumDate = self.lowerDateLimit;
    self.endtimePicker.maximumDate = self.upperDateLimit;
    if([self.lowerDateLimit compare:[NSDate date]] == NSOrderedAscending && [self.upperDateLimit compare:[NSDate date]] == NSOrderedDescending)
       initEnddate = [NSDate date];
    else
        initEnddate = self.upperDateLimit;
    self.endtimePicker.date = initEnddate;
    self.endtimeCell.detailTextLabel.text = [dateTimeformatter stringFromDate:initEnddate];
    self.timeCell.detailTextLabel.text = [timeformatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:60*60*8]];
    [self.timePicker setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    self.timePicker.date = [NSDate dateWithTimeIntervalSince1970:60*60*8];
    
}

- (IBAction)saveAW:(UIBarButtonItem *)sender{
    NSDateFormatter *dateformatter = [[NSDateFormatter alloc] init];
    [dateformatter setDateFormat:@"yyyy-MM-dd"];
    [dateformatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    NSDateFormatter *dateTimeformatter = [[NSDateFormatter alloc] init];
    [dateTimeformatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [dateTimeformatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
    NSDate *starttime = [dateformatter dateFromString:self.starttimeCell.detailTextLabel.text];
    NSDate *endtime = [dateformatter dateFromString:self.endtimeCell.detailTextLabel.text];
    NSNumber *time = [NSNumber numberWithDouble:[[dateTimeformatter dateFromString:[NSString stringWithFormat:@"1970-01-01 %@", self.timeCell.detailTextLabel.text]] timeIntervalSince1970] ];

    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{@"action": [NSString stringWithFormat:@"set%@",self.mainType],
                                 @"starttime": [NSString stringWithFormat:@"%.f", [starttime timeIntervalSince1970]],
                                 @"endtime": [NSString stringWithFormat:@"%.f", [endtime timeIntervalSince1970]+60*60], //Make sure we include last day
                                 @"time": [time stringValue],
                                 @"type": [NSString stringWithFormat:@"%ld", [self.selectedType integerValue]+1],
                                 @"username": [udTimeServer username],
                                 @"password": [udTimeServer password],
                                 @"output": @"json"};
    [manager GET:API_URL
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             //NSLog(@"%@", responseObject);
             if(![udTimeServer successOnResult:responseObject onAction:@"results.login"]) {
                 NSLog(@"Login error");
                 [udTimeServer showServerMessage:@"Problem logging in"];
                 return;
             }else if(![udTimeServer successOnResult:responseObject onAction:[NSString stringWithFormat:@"results.set%@",self.mainType]]) {
                 NSLog(@"Add error");
                 [udTimeServer showServerMessage:@"Could not add period"];
                 return;
             }
             
             //Add new work to local db
             
             [udTimeServer synchronizeInternalDBWithServerOn:self.managedObjectContext];
             
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

// The number of columns of data
- (int)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

// The number of rows of data
- (long)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    if([self.mainType isEqualToString:ASWORKTIME])
        return self.asTypes.count;
    else if ([self.mainType isEqualToString:AGAINSTWORKTIME])
        return self.againstTypes.count;
    else
        return 0;
}
// The data to return for the row and component (column) that's being passed in
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    if([self.mainType isEqualToString:ASWORKTIME])
        return self.asTypes[row];
    else if ([self.mainType isEqualToString:AGAINSTWORKTIME])
        return self.againstTypes[row];
    else
        return nil;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == (kStarttimePickerIndex - 1) && indexPath.section == 0){
        if (self.starttimePickerIsShowing){
            [self hidePickerCellAt:kStarttimePickerIndex];
        }else {
            [self showPickerCellAt:kStarttimePickerIndex];
        }
        [self hidePickerCellAt:kEndtimePickerIndex];
        [self hidePickerCellAt:kTimePickerIndex];
        [self hidePickerCellAt:kTypePickerIndex];
    }else if (indexPath.row == (kEndtimePickerIndex - 1) && indexPath.section == 0){
        if (self.endtimePickerIsShowing){
            [self hidePickerCellAt:kEndtimePickerIndex];
        }else {
            [self showPickerCellAt:kEndtimePickerIndex];
        }
        [self hidePickerCellAt:kStarttimePickerIndex];
        [self hidePickerCellAt:kTimePickerIndex];
        [self hidePickerCellAt:kTypePickerIndex];
    }else if (indexPath.row == (kTimePickerIndex - 1) && indexPath.section == 0){
        if (self.timePickerIsShowing){
            [self hidePickerCellAt:kTimePickerIndex];
        }else {
            [self showPickerCellAt:kTimePickerIndex];
        }
        [self hidePickerCellAt:kStarttimePickerIndex];
        [self hidePickerCellAt:kEndtimePickerIndex];
        [self hidePickerCellAt:kTypePickerIndex];
    }else if (indexPath.row == (kTypePickerIndex - 1) && indexPath.section == 0){
        if (self.typePickerIsShowing){
            [self hidePickerCellAt:kTypePickerIndex];
        }else {
            [self showPickerCellAt:kTypePickerIndex];
        }
        [self hidePickerCellAt:kStarttimePickerIndex];
        [self hidePickerCellAt:kTimePickerIndex];
        [self hidePickerCellAt:kEndtimePickerIndex];
    }
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)showPickerCellAt:(NSInteger)row {
    
    if(row == kStarttimePickerIndex) self.starttimePickerIsShowing = YES;
    else if(row == kEndtimePickerIndex) self.endtimePickerIsShowing = YES;
    else if(row == kTimePickerIndex) self.timePickerIsShowing = YES;
    else if(row == kTypePickerIndex) self.typePickerIsShowing = YES;
    
    [self.tableView beginUpdates];
    
    
    
    UIPickerView *picker;
    if(row == kStarttimePickerIndex)
        picker = (UIPickerView *)self.starttimePicker;
    else if(row == kEndtimePickerIndex)
        picker = (UIPickerView *)self.endtimePicker;
    else if(row == kTimePickerIndex)
        picker = (UIPickerView *)self.timePicker;
    else if(row == kTypePickerIndex)
        picker = (UIPickerView *)self.typePicker;
    
    picker.hidden = NO;
    picker.alpha = 0.0f;
    
    [UIView animateWithDuration:0.25 animations:^{
        picker.alpha = 1.0f;
    }];
    [self.tableView endUpdates];
}

- (void)hidePickerCellAt:(NSInteger)row{
    
    if(row == kStarttimePickerIndex) self.starttimePickerIsShowing = NO;
    else if(row == kEndtimePickerIndex) self.endtimePickerIsShowing = NO;
    else if(row == kTimePickerIndex) self.timePickerIsShowing = NO;
    else if(row == kTypePickerIndex) self.typePickerIsShowing = NO;
    
    [self.tableView beginUpdates];
   
    
    UIPickerView *picker;
    if(row == kStarttimePickerIndex)
        picker = (UIPickerView *)self.starttimePicker;
    else if(row == kEndtimePickerIndex)
        picker = (UIPickerView *)self.endtimePicker;
    else if(row == kTimePickerIndex)
        picker = (UIPickerView *)self.timePicker;
    else if(row == kTypePickerIndex)
        picker = (UIPickerView *)self.typePicker;
    
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         picker.alpha = 0.0f;
                     }
                     completion:^(BOOL finished){
                         picker.hidden = YES;
                     }];
    
    [self.tableView endUpdates];
}


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CGFloat height = self.tableView.rowHeight;
    
    if (indexPath.row == kStarttimePickerIndex){
        
        height = self.starttimePickerIsShowing ? kPickerCellHeight : 0.0f;
        
    }else if(indexPath.row == kEndtimePickerIndex){
        
        height = self.endtimePickerIsShowing ? kPickerCellHeight : 0.0f;
    }else if(indexPath.row == kTimePickerIndex){
        
        height = self.timePickerIsShowing ? kPickerCellHeight : 0.0f;
    }else if(indexPath.row == kTypePickerIndex){
        
        height = self.typePickerIsShowing ? kPickerCellHeight : 0.0f;
    }
    
    return height;
}

- (IBAction)starttimePickerChanged:(UIDatePicker *)sender {
    NSDateFormatter *dateTimeformatter = [[NSDateFormatter alloc] init];
    [dateTimeformatter setDateFormat:@"yyyy-MM-dd"];
    
    self.starttimeCell.detailTextLabel.text = [dateTimeformatter stringFromDate:sender.date];
    
    
}

- (IBAction)endttimePickerChanged:(UIDatePicker *)sender {
    NSDateFormatter *dateTimeformatter = [[NSDateFormatter alloc] init];
    [dateTimeformatter setDateFormat:@"yyyy-MM-dd"];
    
    self.endtimeCell.detailTextLabel.text = [dateTimeformatter stringFromDate:sender.date];
    
    
}

- (IBAction)timePickerChanged:(UIDatePicker *)sender {
    NSDateFormatter *timeformatter = [[NSDateFormatter alloc] init];
    [timeformatter setDateFormat:@"HH:mm:ss"];
    [timeformatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];

    
    self.timeCell.detailTextLabel.text = [timeformatter stringFromDate:sender.date];
    
    
}

#pragma mark PickerView Delegate
-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row
      inComponent:(NSInteger)component
{
    if([self.mainType isEqualToString:ASWORKTIME]){
        self.typeCell.detailTextLabel.text = self.asTypes[row];
    }else if([self.mainType isEqualToString:AGAINSTWORKTIME]){
        self.typeCell.detailTextLabel.text = self.againstTypes[row];
    }
    self.selectedType = [NSNumber numberWithInteger:row];
}
- (void)handleServerSynched:(NSNotification *)note {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
