//
//  SyncQueueTableViewController.m
//  
//
//  Created by Johan Adell on 04/03/14.
//
//

#import "SyncQueueTableViewController.h"
#import "SyncQueueItemTableViewController.h"
#import "SyncItem.h"

@interface SyncQueueTableViewController ()
@property (strong, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation SyncQueueTableViewController

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
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
     [self.delegete updateSyncQueueWithObject:self.syncQueue];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"syncQueueItemSegue"])
    {
        // Get reference to the destination view controller
        SyncQueueItemTableViewController *sqitvc = [segue destinationViewController];
        
        // Pass any objects to the view controller here, like...
        
        if([sender isKindOfClass:[UITableViewCell class]]) {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
            SyncItem *syncItem = [self.syncQueue objectAtIndex:indexPath.row];
            sqitvc.syncItem = [syncItem copy];
            sqitvc.syncQueueIndex = indexPath;
            sqitvc.delegate = self;
        }
        
    }
}

- (void)updateSyncQueueWithItem:(SyncItem *)syncItem AtIndex:(NSIndexPath *)indexPath{
    [self.syncQueue replaceObjectAtIndex:indexPath.row withObject:syncItem];
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  
    // Return the number of sections.
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0)
        return [self.successfullySynced count];
    else
        return [self.syncQueue count];

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if(indexPath.section == 0){
        static NSString *CellIdentifier = @"syncedItemCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
        SyncItem *syncItem = [self.successfullySynced objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@ at %@",[syncItem SyncTypeLabelFor:syncItem.syncType],[self timestampToTime:[NSNumber numberWithInteger:syncItem.time]]];
    }else if(indexPath.section == 1){
        static NSString *CellIdentifier = @"syncItemCell";
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        
        SyncItem *syncItem = [self.syncQueue objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%lu: %@ at %@",(long)(indexPath.row+1),[syncItem SyncTypeLabelFor:syncItem.syncType],[self timestampToTime:[NSNumber numberWithInteger:syncItem.time]]];
    }
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *sectionName;
    switch (section)
    {
        case 0:
            sectionName = @"Syncronized in current period";
            break;
        case 1:
            sectionName = @"Not syncronized in current period";
            break;
            // ...
        default:
            sectionName = @"";
            break;
    }
    return sectionName;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.syncQueue removeObjectAtIndex:indexPath.row];
        [self.tableView beginUpdates];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationRight];
        [self.tableView endUpdates];
    }
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
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
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

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

-(NSString *)timestampToTime:(NSNumber *)timestamp{
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[timestamp integerValue]];
    NSDateFormatter *format = [[NSDateFormatter alloc] init];
    [format setDateFormat:@"HH:mm:ss"];
    
    return [format stringFromDate:date];
}

@end
