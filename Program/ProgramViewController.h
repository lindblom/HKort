//
//  ProgramViewController.h
//  Program
//
//  Created by Christopher Lindblom on 2011-12-20.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Hemkop.h"
#import "GADBannerView.h"

@interface ProgramViewController : UIViewController <HemkopReciever, UIWebViewDelegate, UITableViewDataSource, UITableViewDelegate>
@property (strong, nonatomic) IBOutlet UILabel *display;
@property (strong, nonatomic) Hemkop * hemkop;
@property (weak, nonatomic) IBOutlet UIWebView *debugWeb;
@property (strong, nonatomic) IBOutlet UITableView *transactionsTable;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *reloadButton;
@property (weak, nonatomic) IBOutlet UIToolbar *statusBar;
@property (weak, nonatomic) IBOutlet UILabel *statusMessage;

@end
