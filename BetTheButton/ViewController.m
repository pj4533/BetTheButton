//
//  ViewController.m
//  BetTheButton
//
//  Created by PJ Gray on 4/18/15.
//  Copyright (c) 2015 Say Goodnight Software. All rights reserved.
//

#import "ViewController.h"
#import <SocketRocket/SRWebSocket.h>
#import <AFNetworking/AFNetworking.h>
#import "ButtonTimerView.h"
#import <FBDigitalFont/FBLCDFontView.h>

typedef enum : NSUInteger {
    ButtonColor_Red,
    ButtonColor_Orange,
    ButtonColor_Yellow,
    ButtonColor_Green,
    ButtonColor_Blue,
    ButtonColor_Purple,
    ButtonColor_UnPicked
} ButtonColor;

NSString * const ButtonColor_toString[] = {
    @"Red",
    @"Orange",
    @"Yellow",
    @"Green",
    @"Blue",
    @"Purple",
    @"Unpicked"
};


@interface ViewController () <SRWebSocketDelegate> {
    SRWebSocket *_webSocket;
    NSNumber* _previousSecondsLeft;
    ButtonColor _chosenColor;
    NSArray* _buttonColorToLowerBound;
}
@property (weak, nonatomic) IBOutlet UIButton *redButton;
@property (weak, nonatomic) IBOutlet UIButton *orangeButton;
@property (weak, nonatomic) IBOutlet UIButton *yellowButton;
@property (weak, nonatomic) IBOutlet UIButton *greenButton;
@property (weak, nonatomic) IBOutlet UIButton *blueButton;
@property (weak, nonatomic) IBOutlet UIButton *purpleButton;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet FBLCDFontView *countdownView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _buttonColorToLowerBound = @[
                                 @1,
                                 @12,
                                 @22,
                                 @32,
                                 @42,
                                 @52,
                                 @-1
                                 ];
    
    self.countdownView.lineWidth = 4.0;
    self.countdownView.drawOffLine = YES;
    self.countdownView.edgeLength = 20;
    self.countdownView.margin = 10.0;
    self.countdownView.backgroundColor = [UIColor blackColor];
    self.countdownView.horizontalPadding = 20;
    self.countdownView.verticalPadding = 14;
    self.countdownView.glowSize = 10.0;
    self.countdownView.innerGlowSize = 3.0;
    [self.countdownView resetSize];
    
    
    _chosenColor = ButtonColor_UnPicked;
    
    NSString *path = @"https://www.reddit.com/r/thebutton/";
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    manager.responseSerializer = [AFCompoundResponseSerializer serializer];
    
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"text/html"];
    
    [manager GET:path parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSString* encodedString = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
        
        NSString* pattern = @"wss://wss.redditmedia.com/thebutton\\?h=[^\"]*";
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                               options:0 error:NULL];
        
        // create an NSRange object using our regex object for the first match in the string httpline
        NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:encodedString options:0 range:NSMakeRange(0, [encodedString length])];
        
        NSString* websocketUrlString = [encodedString substringWithRange:rangeOfFirstMatch];
        [self connectWebSocketWithString:websocketUrlString];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)connectWebSocketWithString:(NSString*)urlString {
    _webSocket.delegate = nil;
    _webSocket = nil;
    
    SRWebSocket *newWebSocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:urlString]];
    newWebSocket.delegate = self;
    
    [newWebSocket open];
}

#pragma mark - SRWebSocket delegate

- (void)webSocketDidOpen:(SRWebSocket *)newWebSocket {
    _webSocket = newWebSocket;
    [_webSocket send:[NSString stringWithFormat:@"Hello from %@", [UIDevice currentDevice].name]];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"ERROR: %@", error);
    //    [self connectWebSocket];
}

- (void)endedWithColor:(ButtonColor)endedColor {
    self.statusLabel.text = @"";
    self.statusLabel.alpha = 1.0;
    if (_chosenColor == ButtonColor_UnPicked) {
        self.statusLabel.text = [NSString stringWithFormat:@"%@: %@s",
                                 ButtonColor_toString[endedColor],
                                 _previousSecondsLeft];
    } else {
        if (_chosenColor == endedColor) {
            self.statusLabel.text = [NSString stringWithFormat:@"%@: %@s  WINNER!",
                                     ButtonColor_toString[endedColor],
                                     _previousSecondsLeft];
        } else {
            self.statusLabel.text = [NSString stringWithFormat:@"%@: %@s  YOU LOSE",
                                     ButtonColor_toString[endedColor],
                                     _previousSecondsLeft];
        }
    }
    
    [self reset];
    
    [UIView animateWithDuration:0.66 delay:1.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.statusLabel.alpha = 0.0;
    } completion:nil];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSNumber* secondsLeft = dict[@"payload"][@"seconds_left"];
    
    [self.buttonTimerView animateTickWithSecondsRemaining:secondsLeft];
    
    self.countdownView.text = [NSString stringWithFormat:@"%@", secondsLeft];
    
    if (_previousSecondsLeft && (secondsLeft.integerValue >= _previousSecondsLeft.integerValue)) {
        if (_previousSecondsLeft.integerValue > 51) {
            [self endedWithColor:ButtonColor_Purple];
        } else if (_previousSecondsLeft.integerValue > 41) {
            [self endedWithColor:ButtonColor_Blue];
        } else if (_previousSecondsLeft.integerValue > 31) {
            [self endedWithColor:ButtonColor_Green];
        } else if (_previousSecondsLeft.integerValue > 21) {
            [self endedWithColor:ButtonColor_Yellow];
        } else if (_previousSecondsLeft.integerValue > 11) {
            [self endedWithColor:ButtonColor_Orange];
        } else {
            [self endedWithColor:ButtonColor_Red];
        }
    } else if (secondsLeft.integerValue < [_buttonColorToLowerBound[_chosenColor] integerValue]) {
        self.statusLabel.text = @"";
        self.statusLabel.alpha = 1.0;
        self.statusLabel.text = @"YOU LOSE";
        [self reset];
        
        [UIView animateWithDuration:0.66 delay:1.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.statusLabel.alpha = 0.0;
        } completion:nil];
    }
    
    _previousSecondsLeft = secondsLeft;
}

- (void)zoomLabelWithText:(NSString*)zoomString {
}

- (void)reset {
    _chosenColor = ButtonColor_UnPicked;
    [self unoutlineView:self.redButton];
    [self unoutlineView:self.orangeButton];
    [self unoutlineView:self.yellowButton];
    [self unoutlineView:self.greenButton];
    [self unoutlineView:self.blueButton];
    [self unoutlineView:self.purpleButton];
}

- (void)outlineView:(UIView*)view {
    view.layer.borderColor = [UIColor whiteColor].CGColor;
    view.layer.borderWidth = 2.0f;
}

- (void)unoutlineView:(UIView*)view {
    view.layer.borderColor = [UIColor whiteColor].CGColor;
    view.layer.borderWidth = 0.0f;
}

#pragma mark - Buttons

- (IBAction)purpleTapped:(id)sender {
    if (_chosenColor == ButtonColor_UnPicked) {
        [self outlineView:sender];
        NSLog(@"PURPLE CHOSEN");
        _chosenColor = ButtonColor_Purple;
    }
}

- (IBAction)blueTapped:(id)sender {
    if (_chosenColor == ButtonColor_UnPicked) {
        [self outlineView:sender];
        NSLog(@"BLUE CHOSEN");
        _chosenColor = ButtonColor_Blue;
    }
}

- (IBAction)greenTapped:(id)sender {
    if (_chosenColor == ButtonColor_UnPicked) {
        [self outlineView:sender];
        NSLog(@"GREEN CHOSEN");
        _chosenColor = ButtonColor_Green;
    }
}

- (IBAction)yellowTapped:(id)sender {
    if (_chosenColor == ButtonColor_UnPicked) {
        [self outlineView:sender];
        NSLog(@"YELLOW CHOSEN");
        _chosenColor = ButtonColor_Yellow;
    }
}


@end
