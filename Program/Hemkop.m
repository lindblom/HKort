//
//  Hemkop.m
//  Program
//
//  Created by Christopher Lindblom on 2011-12-26.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Hemkop.h"

@interface Hemkop () <UIWebViewDelegate>

@property (strong, nonatomic) NSString * username;
@property (strong, nonatomic) NSString * password;
@property (strong, nonatomic) NSString * balance;
@property (strong, nonatomic) NSString * message;
@property (strong, nonatomic) NSString * transactions;
@end

@implementation Hemkop

@synthesize balance = _balance;
@synthesize theWeb = _theWeb;
@synthesize message = _message;
@synthesize username = _username;
@synthesize password = _password;
@synthesize delegate = _delegate;
@synthesize transactions = _transactions;

int _loaded = 0;

- (UIWebView *) theWeb {
    if (!_theWeb)
    {
        _theWeb = [[UIWebView alloc] init];
        _theWeb.delegate = self;
    }
    return _theWeb;
}

- (void) reset {
    _loaded = 0;
    self.theWeb = nil;
}

- (void) update:(NSString *) username withPassword:(NSString *) password {
    
    self.username = username;
    self.password = password;
    //NSLog(@"Inne i update, U:%@, P:%@", username, password);
    [self reset];
    [self.theWeb loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://kundkort.hemkop.se/showdoc.asp?docid=1209"]]];
    self.message = @"Laddar inloggningssidan ...";
    [self.delegate newMessage];
}

- (void) extract:(NSInteger) rows {
    NSMutableArray *transactions = [NSMutableArray array];
    
    if (rows == 0){
        [transactions addObject:@"Inga transaktioner funna."];
        //NSLog(@"Inga transaktioner denna månad än.");
    }
    else
        for (NSInteger i = 0; i < rows; i++) {
            NSMutableArray *transactionRow = [NSMutableArray array];
            [transactionRow addObject: [NSString stringWithFormat:@"%@",
                                      [self.theWeb stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:@"document.getElementsByClassName('transaction_row')[%i].children[1].innerText", i]]]];
            [transactionRow addObject: [NSString stringWithFormat:@"%@: %@",
                                        [self.theWeb stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:@"document.getElementsByClassName('transaction_row')[%i].children[0].innerText", i]],
                                        [self.theWeb stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:@"document.getElementsByClassName('transaction_row')[%i].children[3].innerText", i]]]];
            [transactions addObject:[transactionRow copy]];
        }
    self.transactions = [transactions copy];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    self.message = @"Uppdatering misslyckades.";
    [self.delegate newMessage];
    [self.delegate failedWithMessage:@"Kunde inte kontakta servern."];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    _loaded++;
    NSLog(@"%d", _loaded);
    
    if(_loaded == 1)
    {
        NSLog(@"Loggar in med:%@, %@", self.username, self.password);
        self.message = @"Loggar in ...";
        [self.delegate newMessage];
        [self.theWeb stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat: @"document.forms['login'].hemkop_personnummer.value='%@';document.forms['login'].hemkop_password.value='%@';document.forms['login'].submit();", self.username, self.password]];
    }
    else if (_loaded == 3)
    {
        if([[[[self.theWeb request] URL] description] isEqualToString: @"https://kundkort.hemkop.se/showdoc.asp?docid=1209&status=failed"])
        {
            self.message = @"Uppdatering misslyckades.";
            [self.delegate newMessage];
            [self.delegate failedWithMessage:@"Felaktigt personnummer eller lösenord."];
        }
        else
        {
            self.message = @"Hämtar saldo ...";
            [self.delegate newMessage];
            
            self.balance = [NSString stringWithFormat:@"Hemköp betalkortsaldo: %@", [self.theWeb stringByEvaluatingJavaScriptFromString:@"document.getElementById('ctl00_cpTop_lblAktuelltSaldo').innerText;"]];
            
            //NSString *new_location = [self.theWeb stringByEvaluatingJavaScriptFromString: @"document.getElementById('ctl00_cpTop_UrlKontoUtdrag').href;"];
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.dateFormat = @"yyyy-MM-dd";
            
            NSDate *today = [NSDate date];
            NSDate *oneYearAgo = [today dateByAddingTimeInterval:(-3600*24*365)];
            
            //NSLog([formatter stringFromDate:today]);
            //NSLog([formatter stringFromDate:oneYearAgo]);
            
            [self.theWeb loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://kundkort.hemkop.se/showdoc.asp?docid=785&hemkop_datumFrom=%@&hemkop_datumTom=%@", [formatter stringFromDate:oneYearAgo], [formatter stringFromDate:today]]]]];
            
            self.message = @"Hämtar senaste transaktioner ...";
            [self.delegate newMessage];
        }
    }
    else if (_loaded == 4)
    {
        [self extract:[[self.theWeb stringByEvaluatingJavaScriptFromString: @"document.getElementsByClassName('transaction_row').length"] integerValue]];
        
        [self.delegate infoUpdated];
    }
}



@end
