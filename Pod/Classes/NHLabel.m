//
//  NLabel.m
//  Pods
//
//  Created by Naithar on 22.04.15.
//
//

#import "NHLabel.h"

NSString *const kNHLabelCallToSelector = @"callTo:";
NSString *const kNHLabelSmsToSelector = @"smsTo:";
NSString *const kNHLabelEmailToSelector = @"emailTo:";
NSString *const kNHLabelUrlToSelector = @"urlTo:";

NSString *const kNHLabelMenuName = @"LabelMenuName";
NSString *const kNHLabelMenuTitle = @"LabelMenuTitle";
NSString *const kNHLabelMenuLocalizationTable = @"LabelMenuLocalizationTable";
NSString *const kNHLabelMenuSelector = @"LabelMenuSelector";

NSString *const kNHLabelHashtagPattern = @"(#\\w+)";
NSString *const kNHLabelMentionPattern = @"(\\A|\\W)(@\\w+)";

@interface NHLabel ()

@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, strong) UILongPressGestureRecognizer *longPressRecognizer;

@property (nonatomic, strong) NSMutableDictionary *customSelectors;

//@property (nonatomic, copy) NSDictionary *defaultLinkAttributes;
//@property (nonatomic, copy) NSDictionary *defaultHashtagAttributes;
//@property (nonatomic, copy) NSDictionary *defaultMentionAttributes;
@end

@implementation NHLabel


- (instancetype)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.userInteractionEnabled = YES;
    
    _canPerform = YES;
    _additionalSelectors = @[];
    _customSelectors = [@{} mutableCopy];
    _textInsets = UIEdgeInsetsZero;

    _linkAttributes = [[NHLabel appearance] linkAttributes];
    _hashtagAttributes = [[NHLabel appearance] hashtagAttributes];
    _mentionAttributes = [[NHLabel appearance] mentionAttributes];


    self.tapRecognizer = [[UITapGestureRecognizer alloc]
                                initWithTarget:self
                                action:@selector(tapGestureRecognizerAction:)];
    self.tapRecognizer.numberOfTouchesRequired = 1;
    self.tapRecognizer.numberOfTapsRequired = 1;
    [self addGestureRecognizer:self.tapRecognizer];

    self.longPressRecognizer = [[UILongPressGestureRecognizer alloc]
                          initWithTarget:self
                          action:@selector(longPressGestureRecognizerAction:)];
    [self addGestureRecognizer:self.longPressRecognizer];

}

- (void)addCustomAction:(NSString*)name
              withTitle:(NSString*)title
            andSelector:(SEL)selector {
    [self addCustomAction:name
                withTitle:title
        localizationTable:nil
              andSelector:selector];
}

- (void)addCustomAction:(NSString*)name
              withTitle:(NSString*)title
      localizationTable:(NSString*)table
            andSelector:(SEL)selector {
    self.customSelectors[name] = @{
                                   kNHLabelMenuName : name,
                                   kNHLabelMenuTitle : title,
                                   kNHLabelMenuLocalizationTable : table ?: [NSNull null],
                                   kNHLabelMenuSelector : NSStringFromSelector(selector)
                                   };
}
- (void)removeCustomAction:(NSString*)name {
    [self.customSelectors removeObjectForKey:name];
}

- (void)tapGestureRecognizerAction:(UITapGestureRecognizer*)recognizer {
    if (!self.useSingleTouch) {
        [UIView animateWithDuration:0.3 animations:^{
            [[UIMenuController sharedMenuController] setMenuVisible:NO];
            [self resignFirstResponder];

        }];
        return;
    }

    if (!self.isFirstResponder) {
        [self becomeFirstResponder];
    }
    else {
        [UIView animateWithDuration:0.3 animations:^{
            [[UIMenuController sharedMenuController] setMenuVisible:NO];
            [self resignFirstResponder];

        }];
    }
}

- (void)longPressGestureRecognizerAction:(UILongPressGestureRecognizer*)recognizer {
    if (self.useSingleTouch) {
        return;
    }

    if (recognizer.state == UIGestureRecognizerStateBegan) {
    if (!self.isFirstResponder) {
        [self becomeFirstResponder];
    }
    }
}


- (NSString*)createTextForAction {
    if (self.actionStringFormatBlock) {
        return self.actionStringFormatBlock(self.text);
    }

    if (self.actionStringFormat != nil) {
        NSString *tempText = [NSString
                              stringWithFormat:self.actionStringFormat,
                              [self.text
                               stringByTrimmingCharactersInSet:[NSCharacterSet
                                                                characterSetWithCharactersInString:@"@/"]]];

        return tempText;
    }

    return self.text;
}

- (void)copy:(NSObject*)sender {
    [self resignFirstResponder];
    [UIPasteboard generalPasteboard].string = [self createTextForAction];
    [self resignFirstResponder];
}

- (void)callTo:(NSObject*)sender {
    [self resignFirstResponder];
    [[UIApplication sharedApplication]
     openURL:[NSURL
              URLWithString:[NSString
                             stringWithFormat:@"tel:%@",
                             [self createTextForAction]]]];
    [self resignFirstResponder];
}

- (void)smsTo:(NSObject*)sender {
    [self resignFirstResponder];
    [[UIApplication sharedApplication]
     openURL:[NSURL
              URLWithString:[NSString
                             stringWithFormat:@"sms:%@",
                             [self createTextForAction]]]];
    [self resignFirstResponder];
}

- (void)emailTo:(NSObject*)sender {
    [self resignFirstResponder];
    [[UIApplication sharedApplication]
     openURL:[NSURL
              URLWithString:[NSString
                             stringWithFormat:@"mailto:%@",
                             [self createTextForAction]]]];

    [self resignFirstResponder];
}

- (void)urlTo:(NSObject*)sender {
    [self resignFirstResponder];
    [[UIApplication sharedApplication]
     openURL:[NSURL
              URLWithString:[self createTextForAction]]];
    [self resignFirstResponder];
}

- (void)menuDidHide:(NSObject*)sender {
    [self resignFirstResponder];
}

- (BOOL)becomeFirstResponder {
    if (self.isFirstResponder
        || !self.canBecomeFirstResponder) {
        return NO;
    }

    if ([super becomeFirstResponder]) {
        self.alpha = 0.6;

        NSMutableArray *customMenuItems = [@[
                                     [[UIMenuItem alloc]
                                      initWithTitle:NSLocalizedStringFromTable(@"NLabel.call", @"NLabel", nil)
                                      action:@selector(callTo:)],
                                     [[UIMenuItem alloc]
                                      initWithTitle:NSLocalizedStringFromTable(@"NLabel.sms", @"NLabel", nil)
                                      action:@selector(smsTo:)],
                                     [[UIMenuItem alloc]
                                      initWithTitle:NSLocalizedStringFromTable(@"NLabel.email", @"NLabel", nil)
                                      action:@selector(emailTo:)],
                                     [[UIMenuItem alloc]
                                      initWithTitle:NSLocalizedStringFromTable(@"NLabel.url", @"NLabel", nil)
                                      action:@selector(urlTo:)],
                                     ] mutableCopy];

        [self.customSelectors enumerateKeysAndObjectsUsingBlock:^(NSString* key,
                                                                  NSDictionary *obj,
                                                                  BOOL *stop) {
            NSString *title = obj[kNHLabelMenuTitle];
            NSString *localizationTable = obj[kNHLabelMenuLocalizationTable];
            SEL selector = NSSelectorFromString(obj[kNHLabelMenuSelector]);

            NSString *menuItemTitle = ([localizationTable isEqual:[NSNull null]]
                                       || localizationTable == nil
                                       ? NSLocalizedString(title, nil)
                                       : NSLocalizedStringFromTable(title, localizationTable, nil));

            [customMenuItems addObject:[[UIMenuItem alloc]
                                        initWithTitle:menuItemTitle action:selector]];
        }];

        [[UIMenuController sharedMenuController] setMenuItems:customMenuItems];
        [[UIMenuController sharedMenuController] setTargetRect:self.bounds inView:self];
        [[UIMenuController sharedMenuController] setMenuVisible:YES animated:YES];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(menuDidHide:)
                                                     name:UIMenuControllerWillHideMenuNotification
                                                   object:nil];

        __weak __typeof(self) weakSelf = self;
        if ([weakSelf.delegate respondsToSelector:@selector(labelDidBecomeFirstResponder:)]) {
            [weakSelf.delegate labelDidBecomeFirstResponder:weakSelf];
        }
    }

    return [super becomeFirstResponder];
}

- (BOOL)resignFirstResponder {

    if (self.isFirstResponder
        && self.canResignFirstResponder) {
        self.alpha = 1;
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:UIMenuControllerWillHideMenuNotification
                                                      object:nil];


        __weak __typeof(self) weakSelf = self;
        if ([weakSelf.delegate respondsToSelector:@selector(labelDidResignFirstResponder:)]) {
            [weakSelf.delegate labelDidResignFirstResponder:weakSelf];
        }

        return [super resignFirstResponder];
    }

    return NO;
}

- (BOOL)canBecomeFirstResponder {
    return self.canPerform;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return (self.canPerform
            && (action == @selector(copy:)
                || ([self.additionalSelectors
                     containsObject:NSStringFromSelector(action)])));
}

- (void)drawTextInRect:(CGRect)rect {
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.textInsets)];
}

- (CGRect)textRectForBounds:(CGRect)bounds
     limitedToNumberOfLines:(NSInteger)numberOfLines {
    return [super textRectForBounds:UIEdgeInsetsInsetRect(bounds, self.textInsets)
             limitedToNumberOfLines:numberOfLines];
}

- (void)findLinksHashtagsAndMentions {
    [self findLinks:self.linkAttributes
           hashtags:self.hashtagAttributes
           mentions:self.mentionAttributes];
}

- (void)findLinks:(NSDictionary*)linkAttributes
         hashtags:(NSDictionary*)hashtagAttributes
         mentions:(NSDictionary*)mentionAttributes {

    NSMutableAttributedString *tempAttributedString;

    if (!self.attributedText) {
        NSMutableParagraphStyle *paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];

        paragraphStyle.lineBreakMode = self.lineBreakMode;
        paragraphStyle.alignment = self.textAlignment;

        tempAttributedString = [[NSMutableAttributedString alloc]
                                initWithString:self.text ?: @""
                                attributes:@{
                                             NSFontAttributeName : self.font,
                                             NSForegroundColorAttributeName : self.textColor,
                                             NSParagraphStyleAttributeName : paragraphStyle
                                             }];
    }
    else {
        tempAttributedString = [self.attributedText mutableCopy];
    }

    if (linkAttributes) {
        [self findLinksInAttributedString:tempAttributedString
                           withAttributes:linkAttributes];
    }

    if (hashtagAttributes) {
        [self findHashtagsInAttributedString:tempAttributedString
                              withAttributes:hashtagAttributes ?: self.hashtagAttributes];
    }

    if (mentionAttributes) {
        [self findMentionsInAttributedString:tempAttributedString
                              withAttributes:mentionAttributes ?: self.mentionAttributes];
    }

    self.attributedText = tempAttributedString;

}

- (void)findLinksInAttributedString:(NSMutableAttributedString*)string
                     withAttributes:(NSDictionary*)attributes {
    if (!string) {
        return;
    }

    NSRange textRange = NSMakeRange(0, [string length]);

    NSDataDetector *dataDetector = [NSDataDetector
                                    dataDetectorWithTypes:NSTextCheckingTypeLink
                                    error:nil];

    [dataDetector enumerateMatchesInString:[string string]
                                   options:0
                                     range:textRange
                                usingBlock:^(NSTextCheckingResult *result,
                                             NSMatchingFlags flags,
                                             BOOL *stop) {
                                    NSRange linkRange = result.range;

                                    [string addAttributes:attributes ?: self.linkAttributes
                                                    range:linkRange];
                                }];
}

- (void)findHashtagsInAttributedString:(NSMutableAttributedString*)string
                     withAttributes:(NSDictionary*)attributes {
    if (!string) {
        return;
    }

    NSRange textRange = NSMakeRange(0, [string length]);

    NSRegularExpression *hashtagRegExp = [NSRegularExpression
                                          regularExpressionWithPattern:kNHLabelHashtagPattern
                                          options:0
                                          error:nil];



    [hashtagRegExp enumerateMatchesInString:[string string]
                                    options:0
                                      range:textRange
                                 usingBlock:^(NSTextCheckingResult *result,
                                              NSMatchingFlags flags,
                                              BOOL *stop) {
                                     NSRange hashtagRange = [result rangeAtIndex:0];

                                     [string addAttributes:attributes ?: self.hashtagAttributes
                                                     range:hashtagRange];
                                 }];
}

- (void)findMentionsInAttributedString:(NSMutableAttributedString*)string
                     withAttributes:(NSDictionary*)attributes {
    if (!string) {
        return;
    }

    NSRange textRange = NSMakeRange(0, [string length]);

    NSRegularExpression *mentionRegExp = [NSRegularExpression
                                          regularExpressionWithPattern:kNHLabelMentionPattern
                                          options:0
                                          error:nil];

    [mentionRegExp enumerateMatchesInString:[string string]
                                    options:0
                                      range:textRange
                                 usingBlock:^(NSTextCheckingResult *result,
                                              NSMatchingFlags flags,
                                              BOOL *stop) {
                                     NSRange mentionRange = [result rangeAtIndex:0];

                                     [string addAttributes:attributes ?: self.mentionAttributes
                                                     range:mentionRange];
                                 }];
}

@end