/*
 Copyright (c) 2011-present, salesforce.com, inc. All rights reserved.
 
 Redistribution and use of this software in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright notice, this list of conditions
 and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice, this list of
 conditions and the following disclaimer in the documentation and/or other materials provided
 with the distribution.
 * Neither the name of salesforce.com, inc. nor the names of its contributors may be used to
 endorse or promote products derived from this software without specific prior written
 permission of salesforce.com, inc.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "RootViewController.h"

#import <SalesforceSDKCore/SFRestAPI.h>
#import <SalesforceSDKCore/SFRestRequest.h>

@implementation RootViewController

@synthesize dataRows;

#pragma mark Misc


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)dealloc
{
    self.dataRows = nil;
}


#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Mobile SDK Sample App";
    
    //Here we use a query that should work on either Force.com or Database.com
    SFRestRequest *request = [[SFRestAPI sharedInstance] requestForQuery:@"SELECT Name FROM Contact LIMIT 10"];
    [[SFRestAPI sharedInstance] send:request delegate:self];
}

#pragma mark - SFRestDelegate

- (void)request:(SFRestRequest *)request didLoadResponse:(id)jsonResponse {
    NSArray *records = jsonResponse[@"records"];
    NSLog(@"request:didLoadResponse: #records: %lu", (unsigned long)records.count);
    //self.dataRows = records;
    self.dataRows = [records mutableCopy];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}


- (void)request:(SFRestRequest*)request didFailLoadWithError:(NSError*)error {
    NSLog(@"request:didFailLoadWithError: %@", error);
    // Add your failed error handling here
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [self reinstateDeletedRowWithRequest:request];
                       [self.tableView reloadData];
                       UIAlertController *alert = [UIAlertController
                                                   alertControllerWithTitle:@"Cannot delete item"
                                                   message:[error.userInfo objectForKey:@"NSLocalizedDescription"]
                                                   preferredStyle:UIAlertControllerStyleAlert];
                       UIAlertAction* cancel = [UIAlertAction
                                                actionWithTitle:@"Cancel"
                                                style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                                                    [alert dismissViewControllerAnimated:YES completion:nil];
                                                }];
                       [alert addAction:cancel];
                       [self presentViewController:alert animated:YES completion:nil];
                   });

}

- (void)requestDidCancelLoad:(SFRestRequest *)request {
    NSLog(@"requestDidCancelLoad: %@", request);
    // Add your failed error handling here
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [self reinstateDeletedRowWithRequest:request];
                       [self.tableView reloadData];
                       UIAlertController *alert = [UIAlertController
                                                   alertControllerWithTitle:@"Cannot delete item"
                                                   message:@"The server cancelled the load"
                                                   preferredStyle:UIAlertControllerStyleAlert];

                       UIAlertAction* cancel = [UIAlertAction
                                                actionWithTitle:@"Cancel"
                                                style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                                                    [alert dismissViewControllerAnimated:YES completion:nil];
                                                }];
                       [alert addAction:cancel];
                       [self presentViewController:alert animated:YES completion:nil];
                   });

    }

- (void)requestDidTimeout:(SFRestRequest *)request {
    NSLog(@"requestDidTimeout: %@", request);
    // Add your failed error handling here
    dispatch_async(dispatch_get_main_queue(),
                   ^{
                       [self reinstateDeletedRowWithRequest:request];
                       [self.tableView reloadData];
                       UIAlertController *alert = [UIAlertController
                                                   alertControllerWithTitle:@"Cannot delete item"
                                                   message:@"The server request timed out"
                                                   preferredStyle:UIAlertControllerStyleAlert];

                       UIAlertAction* cancel = [UIAlertAction
                                                actionWithTitle:@"Cancel"
                                                style:UIAlertActionStyleDefault
                                                handler:^(UIAlertAction * action) {
                                                    [alert dismissViewControllerAnimated:YES completion:nil];
                                                }];
                       [alert addAction:cancel];
                       [self presentViewController:alert animated:YES completion:nil];
                   });
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (self.dataRows).count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView_ cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"CellIdentifier";
    
    // Dequeue or create a cell of the appropriate type.
    UITableViewCell *cell = [tableView_ dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        
    }
    // If you want to add an image to your cell, here's how.
    UIImage *image = [UIImage imageNamed:@"icon.png"];
    cell.imageView.image = image;
    
    // Configure the cell to show the data.
    NSDictionary *obj = dataRows[indexPath.row];
    cell.textLabel.text =  obj[@"Name"];
    
    // This adds the arrow to the right hand side.
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
    
}
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView
editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = [indexPath row];
    NSUInteger count = [dataRows count];
    if (row < count) {
        return UITableViewCellEditingStyleDelete;
    } else {
        return UITableViewCellEditingStyleNone;
    }

}

- (void)tableView:(UITableView *)tView
commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger row = [indexPath row];
    NSUInteger count = [dataRows count];
    if (row < count && editingStyle == UITableViewCellEditingStyleDelete)
    {
        //Remove from dictionary on server
        //Get the ID of the record from the row in dataRows
        //
        NSString *deletedId = [[dataRows objectAtIndex:row] objectForKey:@"Id"];
        // Capture these values before sending the delete request:
        //    -- the associated REST response object
        //    -- the index path
        NSMutableArray *deletedItemInfo = [[NSMutableArray alloc] init];
        [deletedItemInfo addObject:[dataRows objectAtIndex:row]];
        [deletedItemInfo addObject:indexPath];
        // Create a new DELETE request
        SFRestRequest *request = [[SFRestAPI sharedInstance]
                                  requestForDeleteWithObjectType:@"Contact"
                                  objectId:deletedId];
        if (self.deleteRequests == nil)
        {
            self.deleteRequests = [[NSMutableDictionary alloc] init];
        }
        
        [self.deleteRequests setObject:deletedItemInfo
                                forKey:[NSValue valueWithNonretainedObject:request]];
        [dataRows removeObjectAtIndex:row];
        
        [tView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                     withRowAnimation:TRUE];
        // Send the request
        [[SFRestAPI sharedInstance] send:request delegate:self];

    }

}

- (void)reinstateDeletedRowWithRequest:(SFRestRequest *)request
{
    // Reinsert deleted rows if the operation is DELETE and the ID matches the deleted ID.
    // The trouble is, the NSError parameter doesn't give us that info, so we can't really
    // judge which row caused this error.
    NSNumber *val = [NSNumber numberWithUnsignedInteger:[request hash]];
    NSArray *rowValues = [self.deleteRequests objectForKey:val];

    // To avoid possible problems with using the original row number, insert the data object at
    // the beginning of the dataRows dictionary (index 0).
    if (rowValues)
    {
        [dataRows insertObject:rowValues[0] atIndex:0];
        [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:rowValues[1]]
                         withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.deleteRequests removeObjectForKey:val];
    }
}


@end
