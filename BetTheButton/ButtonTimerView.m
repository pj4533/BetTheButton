//
//  ButtonTimerView.m
//  TesterDerp
//
//  Created by PJ Gray on 4/16/15.
//  Copyright (c) 2015 EverTrue. All rights reserved.
//

#import "ButtonTimerView.h"

@interface ButtonTimerView () {
    UIView* _filledView;
}

@end
@implementation ButtonTimerView

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id) initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)animateTickWithSecondsRemaining:(NSNumber*)secondsRemaining {
    CGFloat segmentHeight = self.frame.size.height / 6.0;
    CGFloat tickHeight = segmentHeight / 10.0f;
    
    __block NSInteger currentHeight = (60 - secondsRemaining.integerValue) * tickHeight;
    _filledView.frame = CGRectMake(0.0, self.frame.size.height - currentHeight, self.frame.size.width, currentHeight);
    [UIView animateWithDuration:1.2 animations:^{
        currentHeight = currentHeight + tickHeight;
        _filledView.frame = CGRectMake(0.0, self.frame.size.height - currentHeight, self.frame.size.width, currentHeight);
    }];

    if (secondsRemaining.integerValue > 51) {
        _filledView.backgroundColor = [UIColor colorWithRed:130.0/255.0 green:0.0 blue:128.0/255.0 alpha:1];
    } else if (secondsRemaining.integerValue > 41) {
        _filledView.backgroundColor = [UIColor colorWithRed:0.0 green:131.0/255 blue:199.0/255 alpha:1];
    } else if (secondsRemaining.integerValue > 31) {
        _filledView.backgroundColor = [UIColor colorWithRed:2.0/255.0 green:190.0/255.0 blue:1.0/255.0 alpha:1];
    } else if (secondsRemaining.integerValue > 21) {
        _filledView.backgroundColor = [UIColor colorWithRed:229.0/255.0 green:217.0/255.0 blue:0.0 alpha:1];
    } else if (secondsRemaining.integerValue > 11) {
        _filledView.backgroundColor = [UIColor colorWithRed:229.0/255.0 green:149.0/255.0 blue:0.0 alpha:1];
    } else {
        _filledView.backgroundColor = [UIColor colorWithRed:229.0/255.0 green:0.0 blue:0.0 alpha:1];
    }

}

- (void)commonInit {
    _filledView = [[UIView alloc] initWithFrame:CGRectMake(0.0, self.frame.size.height, self.frame.size.width, 0)];
    [self addSubview:_filledView];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
