//
//  WeekStatsCDTVC.m
//  udTime
//
//  Created by Johan Adell on 20/03/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "WeekStatsCDTVC.h"
#import "WeekDetailTVC.h"
#import "WorkAddTVC.h"
#import "AWAddTVC.h"
#import "Week.h"
#import "AppDelegate.h"
#import "AFNetworking.h"
#import "udTimeServer.h"
#import "Week+udTime.h"
#import "Work+udTime.h"
#import "Break+udtime.h"
#import "Asworktime+udtime.h"
#import "Againstworktime+udtime.h"
#import "StatsTotalsTableViewCell.h"
#import "Work.h"
#import "Break.h"
#import "Againstworktime.h"
#import "Asworktime.h"
#import "Time.h"

@interface WeekStatsCDTVC ()
//@property (strong, nonatomic) NSURLSession *udtimeDownloadSession;
@end

@implementation WeekStatsCDTVC

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    UIManagedDocument *document = [(AppDelegate *)[[UIApplication sharedApplication] delegate] document];
    if (document.documentState == UIDocumentStateNormal) {
        self.managedObjectContext = document.managedObjectContext;
    }

    [self.refreshControl addTarget:self action:@selector(refreshView:) forControlEvents:UIControlEventValueChanged];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(stopRefreshControl:)                                                     name:@"stopLoading"
                                               object:nil];
    if (self.managedObjectContext) {
        [udTimeServer synchronizeInternalDBWithServerOn:self.managedObjectContext];
    }
     NSLog(@"On WeekStats %@",self.managedObjectContext);
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self stopRefreshControl:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext = managedObjectContext;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Week"];
    request.predicate = nil;
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"year"
                                                              ascending:NO
                                 ],[NSSortDescriptor sortDescriptorWithKey:@"week"
                                                                 ascending:NO
                                    ]];
    
    
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:managedObjectContext
                                                                          sectionNameKeyPath:@"year"
                                                                                   cacheName:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"WeekDetailSegue"])
    {
        // Get reference to the destination view controller
        WeekDetailTVC *wditvc = [segue destinationViewController];
        
        // Pass any objects to the view controller here, like...
        
        if([sender isKindOfClass:[UITableViewCell class]]) {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
            Week *week = [self.fetchedResultsController objectAtIndexPath:indexPath];
            wditvc.week = week;
            wditvc.managedObjectContext = self.managedObjectContext;
        }
        
    }else if ([[segue identifier] isEqualToString:@"Add New Work Segue"]){
        // Get reference to the destination view controller
        UINavigationController *uinc = [segue destinationViewController];
        WorkAddTVC *watvc = (WorkAddTVC *)[uinc viewControllers][0];
        // Pass any objects to the view controller here, like...
        watvc.managedObjectContext = self.managedObjectContext;
    }else if ([[segue identifier] isEqualToString:@"Add New AW Segue"] && [sender integerValue] == 1){
        // Get reference to the destination view controller
        UINavigationController *uinc = [segue destinationViewController];
        AWAddTVC *awatvc = (AWAddTVC *)[uinc viewControllers][0];
        // Pass any objects to the view controller here, like...
        awatvc.managedObjectContext = self.managedObjectContext;
        awatvc.mainType = @"againstworktime";
    }else if ([[segue identifier] isEqualToString:@"Add New AW Segue"] && [sender integerValue] == 2){
        // Get reference to the destination view controller
        UINavigationController *uinc = [segue destinationViewController];
        AWAddTVC *awatvc = (AWAddTVC *)[uinc viewControllers][0];
        // Pass any objects to the view controller here, like...
        awatvc.managedObjectContext = self.managedObjectContext;
        awatvc.mainType = @"asworktime";
    }
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    StatsTotalsTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Week Cell"];
    
    Week *week = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    cell.statPeriod.text = [NSString stringWithFormat:@"Week %d", [week.week intValue]];
    cell.worked.text = [NSString stringWithFormat:@"%@", [Time secondsToReadableTime:week.worked]];
    cell.periodDifference.text = [NSString stringWithFormat:@"%@", week.weekdifftime];
    if([[week.weekdifftime substringToIndex:1] isEqualToString:@"-"]){
        cell.periodDifference.textColor = [UIColor colorWithRed:253.0f/255.0f green:134.0f/255.0f blue:9.0f/255.0f alpha:1.0f];
    }else{
        cell.periodDifference.textColor = [UIColor colorWithRed:137.0f/255.0f green:197.0f/255.0f blue:6.0f/255.0f alpha:1.0f];
    }
    
    cell.totalDifference.text = [NSString stringWithFormat:@"%@", week.totaldifftime];
    return cell;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    
    if ([[self.fetchedResultsController sections] count] > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        return [sectionInfo numberOfObjects];
    } else
        return 0;
    
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[self.fetchedResultsController sections] count] > 0) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections] objectAtIndex:section];
        return [sectionInfo name];
    } else
        return nil;
}

#pragma mark - Scene actions

- (void)refreshView:(UIRefreshControl *)sender {
    // Do something...
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"forceRefreshStats"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    if (self.managedObjectContext) {
        [udTimeServer synchronizeInternalDBWithServerOn:self.managedObjectContext];
    }
    //[sender endRefreshing];
    
}
- (void)stopRefreshControl:(NSNotification *)note {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"forceRefreshStats"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.refreshControl endRefreshing];
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
