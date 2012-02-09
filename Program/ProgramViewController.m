//
//  ProgramViewController.m
//  Program
//
//  Created by Christopher Lindblom on 2011-12-20.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "ProgramViewController.h"

@interface ProgramViewController() {
    GADBannerView *bannerView_;
}

- (BOOL) userInfoFilledIn;
- (void) resetReloadButton;
- (GADRequest *) buildRequest;

@end

@implementation ProgramViewController

@synthesize display = _display;
@synthesize hemkop = _hemkop;
@synthesize transactionsTable = _transactionsTable;
@synthesize reloadButton = _reloadButton;
@synthesize statusBar = _statusBar;
@synthesize statusMessage = _statusMessage;

- (void) infoUpdated {
    self.display.text = [NSString stringWithFormat: @"Aktuellt saldo: %@", self.hemkop.balance];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm";
    
    NSDate *today = [NSDate date];
    self.statusMessage.text = [NSString stringWithFormat:@"Uppdaterat: %@", [formatter stringFromDate:today]];
    [self.transactionsTable reloadData];
    [self resetReloadButton];
}

- (void) failedWithMessage:(NSString *) message {
    self.statusMessage.text = @"Uppdatering misslyckades.";
    [[[UIAlertView alloc] initWithTitle:@"Uppdatering misslyckades" message:message delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
    [self resetReloadButton];
}

- (void) newMessage {
    self.statusMessage.text = self.hemkop.message;
    // self.display.text = self.hemkop.message;
}

- (void) resetReloadButton {
    [self.statusBar setItems:[NSArray arrayWithObject:_reloadButton]];
    //self.navigationItem.leftBarButtonItem = _reloadButton;
}

- (IBAction)reloadButtonAction:(id)sender {
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [spinner startAnimating];
    
    //self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
    
    [self.statusBar setItems:[NSArray arrayWithObject:[[UIBarButtonItem alloc] initWithCustomView:spinner]]];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (defaults)
    {
        NSString *username = [defaults objectForKey:@"username"];
        NSString *password = [defaults objectForKey:@"password"];
        if (username.length != 12)
            [[[UIAlertView alloc] initWithTitle:@"Felaktiga uppgifter" message:@"Personnummret anges med 12 siffror." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        else if (password.length != 3)
            [[[UIAlertView alloc] initWithTitle:@"Felaktiga uppgifter" message:@"Lösenordet skall vara 3 siffor." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil] show];
        else
            [self.hemkop update:username withPassword:password];
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.hemkop.transactions count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.transactionsTable dequeueReusableCellWithIdentifier:@"Transaction Row"];
    if ([[self.hemkop.transactions objectAtIndex:indexPath.row] isKindOfClass:[NSString class]]) {
        cell.textLabel.text = [self.hemkop.transactions objectAtIndex:indexPath.row];
        cell.detailTextLabel.text = @"";
    } else {
        cell.textLabel.text = [[self.hemkop.transactions objectAtIndex:indexPath.row] objectAtIndex:0];
        cell.detailTextLabel.text = [[self.hemkop.transactions objectAtIndex:indexPath.row] objectAtIndex:1];
    }
    return cell;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.reloadButton.enabled = [self userInfoFilledIn];
    
    // Initiate a request with the user info.
    GADRequest *request = [self buildRequest];
    [bannerView_ loadRequest:request];
}

- (GADRequest *) buildRequest {
    GADRequest *request = [GADRequest request];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (defaults)
    {
        NSString *username = [defaults objectForKey:@"username"];
        
        if (username.length == 12) {
            // Gender
            NSInteger genderDigit = [[username substringWithRange:NSRangeFromString(@"{10, 1}")] integerValue];
            //NSLog(@"%i", genderDigit);
            
            if (genderDigit % 2 == 1) {
                //NSLog(@"Male");
                request.gender = kGADGenderMale;
            } else {
                //NSLog(@"Female");
                request.gender = kGADGenderFemale;
            }
            
            // Age
            NSDateFormatter *formater = [[NSDateFormatter alloc] init];
            [formater setDateFormat:@"YYYYMMDD"];
            NSString *bdateString = [username substringToIndex:8];
            //NSLog(@"%@", bdateString);
            
            NSDate *bdate = [formater dateFromString:bdateString];
            
            if (bdate) request.birthday = bdate;
        }
    }
    
    request.testDevices = [NSArray arrayWithObjects:
                           GAD_SIMULATOR_ID,                                           // Simulator
                           //@"bafad71af32144acc1a16a23e9bf927404f3ecb2",                // Test iOS
                           nil];
    return request;
}

#define MY_BANNER_UNIT_ID @"a14f21b2de97e55"

- (void) viewDidLoad {
    [super viewDidLoad];
    
    // Create a view of the standard size at the bottom of the screen.
    bannerView_ = [[GADBannerView alloc] initWithFrame:CGRectMake(0.0,
                                            self.view.frame.size.height - self.navigationController.navigationBar.frame.size.height - self.statusBar.frame.size.height -
                                            GAD_SIZE_320x50.height,
                                            GAD_SIZE_320x50.width,
                                            GAD_SIZE_320x50.height)];
    
    // Specify the ad's "unit identifier." This is your AdMob Publisher ID.
    bannerView_.adUnitID = MY_BANNER_UNIT_ID;
    
    // Let the runtime know which UIViewController to restore after taking
    // the user wherever the ad goes and add it to the view hierarchy.
    bannerView_.rootViewController = self;
    [self.view addSubview:bannerView_];
}

- (void) webViewDidFinishLoad:(UIWebView *)webView {
}

- (Hemkop *) hemkop {
    if (!_hemkop)
    {
        _hemkop = [[Hemkop alloc] init];
        _hemkop.delegate = self;
    }
    return _hemkop;
}

- (void)viewDidUnload {
    [self setHemkop:nil];
    [self setTransactionsTable:nil];
    [self setReloadButton:nil];
    [self setStatusBar:nil];
    [self setStatusMessage:nil];
    [super viewDidUnload];
}

- (BOOL) userInfoFilledIn {
    BOOL result = NO;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (defaults)
    {
        NSString *username = [defaults objectForKey:@"username"];
        NSString *password = [defaults objectForKey:@"password"];
        result = (username.length == 12 && password.length == 3);
    }
    return result;
}
@end
