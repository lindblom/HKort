//
//  Hemkop.m
//  Program
//
//  Created by Christopher Lindblom on 2011-12-26.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "Hemkop.h"
#import "ASIFormDataRequest.h"
#import "TFHpple.h"

@interface Hemkop () <UIWebViewDelegate>

@property (strong, nonatomic) NSString * balance;
@property (strong, nonatomic) NSString * message;
@property (strong, nonatomic) NSString * transactions;
@end

@implementation Hemkop {
    int _status;
}

@synthesize balance = _balance;
@synthesize message = _message;
@synthesize delegate = _delegate;
@synthesize transactions = _transactions;

- (void) done {
    if (_status == 0)
        [self.delegate infoUpdated];
}

- (void) getLastestTransactions {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd";
    
    NSDate *today = [NSDate date];
    NSDate *oneYearAgo = [today dateByAddingTimeInterval:(-3600*24*365)];
    
    //NSLog([formatter stringFromDate:today]);
    //NSLog([formatter stringFromDate:oneYearAgo]);
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://kundkort.hemkop.se/showdoc.asp?docid=785&hemkop_datumFrom=%@&hemkop_datumTom=%@", [formatter stringFromDate:oneYearAgo], [formatter stringFromDate:today]]];
    
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    
    [request setCompletionBlock:^{
        //NSLog(@"Transactions: \n %@", [request responseString]);
        TFHpple * doc = [[TFHpple alloc] initWithHTMLData:[request responseData]];
        NSArray *rows = [doc searchWithXPathQuery:@"//*[contains(@class,'transaction_row')]"];
        
        NSMutableArray *transaction_rows = [[NSMutableArray alloc] init];
        
        for (TFHppleElement *element in rows) {
            //NSLog(@"%@", [element content]);
            NSArray *new_transaction = [[NSArray alloc] initWithObjects:
                                        [[[element children] objectAtIndex:1] content],         // event
                                        [NSString stringWithFormat:@"%@ : %@",                         // date : value
                                         [[[element children] objectAtIndex:0] content],
                                         [[[element children] objectAtIndex:3] content]]
                                        , nil ];
            [transaction_rows addObject:new_transaction];
            //NSLog(@"datum: %@", [[[element children] objectAtIndex:0] content]); // date
            //NSLog(@"butik: %@", [[[element children] objectAtIndex:1] content]); // event
            //NSLog(@"värde: %@", [[[element children] objectAtIndex:3] content]); // value
        }
        
        self.transactions = [transaction_rows copy];
        self.message = @"Transaktioner hämtade...";
        [self.delegate newMessage];
        _status--;
        [self done];
    }];
    
    [request setFailedBlock:^{
        [self.delegate failedWithMessage:@"Det gick inte hämta transaktioner."];
        NSLog(@"%@", [request error]);
    }];
    
    [request startAsynchronous];

}

- (void) getSaldo {
    NSURL *url = [NSURL URLWithString:@"https://kundkort.hemkop.se/showdoc.asp?docid=780&show=minasidor"];
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    
    [request setCompletionBlock:^{
        NSLog(@"Läser saldo");
        TFHpple * doc = [[TFHpple alloc] initWithHTMLData:[request responseData]];
        self.balance = [(TFHppleElement *)[[doc searchWithXPathQuery:@"//*[@id = 'ctl00_cpTop_lblAktuelltSaldo']"] lastObject] content];
        NSLog(@"Saldo: %@", self.balance);
        self.message = @"Saldo hämtat...";
        [self.delegate newMessage];
        _status--;
        [self done];
        //NSLog(@"Saldo: \n %@", [request responseString]);
    }];
    [request setFailedBlock:^{
        [self.delegate failedWithMessage:@"Det gick inte hämta saldo."];
        NSLog(@"%@", [request error]);
    }];
    
    [request startAsynchronous];
}

- (void) update:(NSString *)username withPassword:(NSString *)password {
    NSLog(@"Inne i newUpdate.");
    
    _status = 0;
    
    [ASIHTTPRequest clearSession];
    
    // Login
    NSURL *url = [NSURL URLWithString:@"https://kundkort.hemkop.se/scripts/cgiip.exe/WService=axfood/axfood/common/loginhemkop.p"];
    __block ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
    [request addPostValue:username forKey:@"hemkop_personnummer"];
    [request addPostValue:password forKey:@"hemkop_password"];
    
    self.message = @"Loggar in...";
    [self.delegate newMessage];
    
    [request setCompletionBlock:^{
        // Use when fetching text data
        // NSLog(@"%@", [request responseString]);
        
        
        if ([[request responseString] rangeOfString:@"failed"].location != NSNotFound) {
            
            self.message = @"Uppdatering misslyckades.";
            [self.delegate newMessage];
            [self.delegate failedWithMessage:@"Felaktigt personnummer eller lösenord."];
            
        } else {
            
            self.message = @"Hämtar transaktioner och saldo...";
            [self.delegate newMessage];
            
            _status++;
            [self getSaldo];
            
            _status++;
            [self getLastestTransactions];
        }
    }];
    
    [request setFailedBlock:^{
        [self.delegate failedWithMessage:@"Det gick inte komma åt inloggningssidan."];
        NSLog(@"%@", [request error]);
    }];
    
    [request startAsynchronous];
}

/*
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
*/

@end
