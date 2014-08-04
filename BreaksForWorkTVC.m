//
//  BreaksForWorkTVC.m
//  udTime
//
//  Created by Johan Adell on 19/07/14.
//  Copyright (c) 2014 Johan Adell. All rights reserved.
//

#import "BreaksForWorkTVC.h"
#import "BreakAddTVC.h"
#import "Break.h"
#import "Time.h"
#import "BreakEditTVC.h"

@interface BreaksForWorkTVC ()
@property (strong, nonatomic) NSArray *breaks;
@end

@implementation BreaksForWorkTVC

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
    
    NSSortDescriptor *sortNameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"starttime" ascending:YES];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortNameDescriptor, nil];

    self.breaks = [[self.work.breaks allObjects] sortedArrayUsingDescriptors:sortDescriptors];
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
    NSLog(@"On BreaksForWork %@",self.managedObjectContext);
    //if ([self.work.breaks count] == 0) [self.navigationController popViewControllerAnimated:YES];   //jump back one more level
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    if ([self.work.breaks count] == 0) [self.navigationController popViewControllerAnimated:YES];   //jump back one more level
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"Edit Break"])
    {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        // Get reference to the destination view controller
        BreakEditTVC *betvc = [segue destinationViewController];
        betvc.breakItem = [self.breaks objectAtIndex:indexPath.row];
        // Pass any objects to the view controller here, like...
        betvc.managedObjectContext = self.managedObjectContext;
    }else if ([[segue identifier] isEqualToString:@"Add New Break Segue"]){
        // Get reference to the destination view controller
        UINavigationController *uinc = [segue destinationViewController];
        BreakAddTVC *batvc = (BreakAddTVC *)[uinc viewControllers][0];
        // Pass any objects to the view controller here, like...
        batvc.managedObjectContext = self.managedObjectContext;
        
        batvc.lowerDateLimit = self.work.starttime;
        batvc.upperDateLimit = self.work.endtime;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.work.breaks count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Break cell" forIndexPath:indexPath];
    
    Break *breakItem = [self.breaks objectAtIndex:indexPath.row];
    NSDate *starttime = breakItem.starttime;
    NSDate *endtime = breakItem.endtime;
    
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc] init];
    [timeFormatter setDateFormat:@"HH:mm:ss"];
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", [timeFormatter stringFromDate:starttime], [timeFormatter stringFromDate:endtime]];
    
    return cell;
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

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
