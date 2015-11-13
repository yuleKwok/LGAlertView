//
//  LGAlertView.m
//  LGAlertView
//
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Grigory Lutkov <Friend.LGA@gmail.com>
//  (https://github.com/Friend-LGA/LGAlertView)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#import "LGAlertView.h"
#import "LGAlertViewWindow.h"
#import "LGAlertViewController.h"
#import "LGAlertViewCell.h"
#import "LGAlertViewTextField.h"
#import "LGAlertViewShared.h"
#import "UIWindow+LGAlertView.h"

#define kLGAlertViewStatusBarHeight                   ([UIApplication sharedApplication].isStatusBarHidden ? 0.f : 20.f)
#define kLGAlertViewSeparatorHeight                   ([UIScreen mainScreen].scale == 1.f || [UIDevice currentDevice].systemVersion.floatValue < 7.0 ? 1.f : 0.5)
#define kLGAlertViewOffsetVertical                    (_offsetVertical >= 0 ? _offsetVertical : 8.f)
#define kLGAlertViewOffsetHorizontal                  8.f
#define kLGAlertViewButtonTitleMarginH                8.f
#define kLGAlertViewWidthStyleAlert                   (320.f - 20*2)
#define kLGAlertViewWidthStyleActionSheet             (320.f - 16*2)
#define kLGAlertViewInnerMarginH                      (_style == LGAlertViewStyleAlert ? 16.f : 12.f)
#define kLGAlertViewIsCancelButtonSeparate(alertView) (alertView.style == LGAlertViewStyleActionSheet && alertView.cancelButtonOffsetY > 0.f && !kLGAlertViewPadAndNotForce(alertView))
#define kLGAlertViewButtonWidthMin                    64.f
#define kLGAlertViewWindowPrevious(index)             (index > 0 && index < kLGAlertViewWindowsArray.count ? [kLGAlertViewWindowsArray objectAtIndex:(index-1)] : nil)
#define kLGAlertViewWindowNext(index)                 (kLGAlertViewWindowsArray.count > index+1 ? [kLGAlertViewWindowsArray objectAtIndex:(index+1)] : nil)
#define kLGAlertViewPadAndNotForce(alertView)         (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && !alertView.isPadShowActionSheetFromBottom)

static NSMutableArray *kLGAlertViewWindowsArray;
static UIColor *kLGAlertViewTintColor;
static BOOL kLGAlertViewColorful = YES;
static NSMutableArray *kLGAlertViewArray;

#pragma mark - Interface

@interface LGAlertView () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIGestureRecognizerDelegate>

typedef enum
{
    LGAlertViewTypeDefault           = 0,
    LGAlertViewTypeActivityIndicator = 1,
    LGAlertViewTypeProgressView      = 2,
    LGAlertViewTypeTextFields        = 3
}
LGAlertViewType;

@property (assign, nonatomic, getter=isExists) BOOL exists;

@property (strong, nonatomic) LGAlertViewWindow *window;

@property (strong, nonatomic) UIView *view;

@property (strong, nonatomic) LGAlertViewController *viewController;

@property (strong, nonatomic) UIView *backgroundView;

@property (strong, nonatomic) UIView *styleView;
@property (strong, nonatomic) UIView *styleCancelView;

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UITableView  *tableView;

@property (assign, nonatomic) LGAlertViewStyle style;
@property (strong, nonatomic) NSString         *title;
@property (strong, nonatomic) NSString         *message;
@property (strong, nonatomic) UIView           *innerView;
@property (strong, nonatomic) NSMutableArray   *buttonTitles;
@property (strong, nonatomic) NSString         *cancelButtonTitle;
@property (strong, nonatomic) NSString         *destructiveButtonTitle;

@property (strong, nonatomic) UILabel  *titleLabel;
@property (strong, nonatomic) UILabel  *messageLabel;
@property (strong, nonatomic) UIButton *destructiveButton;
@property (strong, nonatomic) UIButton *cancelButton;
@property (strong, nonatomic) UIButton *firstButton;
@property (strong, nonatomic) UIButton *secondButton;
@property (strong, nonatomic) UIButton *thirdButton;

@property (strong, nonatomic) NSMutableArray *textFieldSeparatorsArray;

@property (strong, nonatomic) UIView *separatorHorizontalView;
@property (strong, nonatomic) UIView *separatorVerticalView1;
@property (strong, nonatomic) UIView *separatorVerticalView2;

@property (assign, nonatomic) CGPoint scrollViewCenterShowed;
@property (assign, nonatomic) CGPoint scrollViewCenterHidden;

@property (assign, nonatomic) CGPoint cancelButtonCenterShowed;
@property (assign, nonatomic) CGPoint cancelButtonCenterHidden;

@property (strong, nonatomic) UIActivityIndicatorView *activityIndicator;

@property (strong, nonatomic) UIProgressView *progressView;
@property (strong, nonatomic) UILabel        *progressLabel;

@property (strong, nonatomic) NSString *progressLabelText;

@property (assign, nonatomic) LGAlertViewType type;

@property (assign, nonatomic) CGFloat keyboardHeight;

@property (assign, nonatomic, getter=isUserButtonsTitleColor)                           BOOL userButtonsTitleColor;
@property (assign, nonatomic, getter=isUserButtonsTitleColorHighlighted)                BOOL userButtonsTitleColorHighlighted;
@property (assign, nonatomic, getter=isUserButtonsBackgroundColorHighlighted)           BOOL userButtonsBackgroundColorHighlighted;
@property (assign, nonatomic, getter=isUserCancelButtonTitleColor)                      BOOL userCancelButtonTitleColor;
@property (assign, nonatomic, getter=isUserCancelButtonTitleColorHighlighted)           BOOL userCancelButtonTitleColorHighlighted;
@property (assign, nonatomic, getter=isUserCancelButtonBackgroundColorHighlighted)      BOOL userCancelButtonBackgroundColorHighlighted;
@property (assign, nonatomic, getter=isUserDestructiveButtonTitleColorHighlighted)      BOOL userDestructiveButtonTitleColorHighlighted;
@property (assign, nonatomic, getter=isUserDestructiveButtonBackgroundColorHighlighted) BOOL userDestructiveButtonBackgroundColorHighlighted;
@property (assign, nonatomic, getter=isUserActivityIndicatorViewColor)                  BOOL userActivityIndicatorViewColor;
@property (assign, nonatomic, getter=isUserProgressViewProgressTintColor)               BOOL userProgressViewProgressTintColor;

@property (strong, nonatomic) NSMutableDictionary *buttonsPropertiesDictionary;
@property (strong, nonatomic) NSMutableArray *buttonsEnabledArray;

- (void)layoutInvalidateWithSize:(CGSize)size;

@end

#pragma mark - Implementation

@implementation LGAlertView

- (instancetype)initWithTitle:(NSString *)title
                      message:(NSString *)message
                        style:(LGAlertViewStyle)style
                 buttonTitles:(NSArray *)buttonTitles
            cancelButtonTitle:(NSString *)cancelButtonTitle
       destructiveButtonTitle:(NSString *)destructiveButtonTitle
{
    self = [super init];
    if (self)
    {
        _style = style;
        _title = title;
        _message = message;
        _buttonTitles = buttonTitles.mutableCopy;
        _cancelButtonTitle = cancelButtonTitle;
        _destructiveButtonTitle = destructiveButtonTitle;

        [self setupDefaults];
    }
    return self;
}

- (instancetype)initWithViewAndTitle:(NSString *)title
                             message:(NSString *)message
                               style:(LGAlertViewStyle)style
                                view:(UIView *)view
                        buttonTitles:(NSArray *)buttonTitles
                   cancelButtonTitle:(NSString *)cancelButtonTitle
              destructiveButtonTitle:(NSString *)destructiveButtonTitle
{
    self = [super init];
    if (self)
    {
        _style = style;
        _title = title;
        _message = message;
        _innerView = view;
        _buttonTitles = buttonTitles.mutableCopy;
        _cancelButtonTitle = cancelButtonTitle;
        _destructiveButtonTitle = destructiveButtonTitle;

        [self setupDefaults];
    }
    return self;
}

- (instancetype)initWithActivityIndicatorAndTitle:(NSString *)title
                                          message:(NSString *)message
                                            style:(LGAlertViewStyle)style
                                     buttonTitles:(NSArray *)buttonTitles
                                cancelButtonTitle:(NSString *)cancelButtonTitle
                           destructiveButtonTitle:(NSString *)destructiveButtonTitle
{
    self = [super init];
    if (self)
    {
        _style = style;
        _title = title;
        _message = message;
        _buttonTitles = buttonTitles.mutableCopy;
        _cancelButtonTitle = cancelButtonTitle;
        _destructiveButtonTitle = destructiveButtonTitle;

        _type = LGAlertViewTypeActivityIndicator;

        [self setupDefaults];
    }
    return self;
}

- (instancetype)initWithProgressViewAndTitle:(NSString *)title
                                     message:(NSString *)message
                                       style:(LGAlertViewStyle)style
                           progressLabelText:(NSString *)progressLabelText
                                buttonTitles:(NSArray *)buttonTitles
                           cancelButtonTitle:(NSString *)cancelButtonTitle
                      destructiveButtonTitle:(NSString *)destructiveButtonTitle
{
    self = [super init];
    if (self)
    {
        _style = style;
        _title = title;
        _message = message;
        _buttonTitles = buttonTitles.mutableCopy;
        _cancelButtonTitle = cancelButtonTitle;
        _destructiveButtonTitle = destructiveButtonTitle;
        _progressLabelText = progressLabelText;

        _type = LGAlertViewTypeProgressView;

        [self setupDefaults];
    }
    return self;
}

- (instancetype)initWithTextFieldsAndTitle:(NSString *)title
                                   message:(NSString *)message
                        numberOfTextFields:(NSUInteger)numberOfTextFields
                    textFieldsSetupHandler:(void(^)(UITextField *textField, NSUInteger index))textFieldsSetupHandler
                              buttonTitles:(NSArray *)buttonTitles
                         cancelButtonTitle:(NSString *)cancelButtonTitle
                    destructiveButtonTitle:(NSString *)destructiveButtonTitle
{
    self = [super init];
    if (self)
    {
        _title = title;
        _message = message;
        _buttonTitles = buttonTitles.mutableCopy;
        _cancelButtonTitle = cancelButtonTitle;
        _destructiveButtonTitle = destructiveButtonTitle;

        _type = LGAlertViewTypeTextFields;

        _textFieldsArray = [NSMutableArray new];
        _textFieldSeparatorsArray = [NSMutableArray new];

        for (NSUInteger i=0; i<numberOfTextFields; i++)
        {
            LGAlertViewTextField *textField = [LGAlertViewTextField new];
            textField.delegate = self;
            textField.tag = i;

            if (i == numberOfTextFields-1)
                textField.returnKeyType = UIReturnKeyDone;
            else
                textField.returnKeyType = UIReturnKeyNext;

            if (textFieldsSetupHandler) textFieldsSetupHandler(textField, i);

            [_textFieldsArray addObject:textField];

            // -----

            UIView *separatorView = [UIView new];
            [_textFieldSeparatorsArray addObject:separatorView];
        }

        [self setupDefaults];
    }
    return self;
}

+ (instancetype)alertViewWithTitle:(NSString *)title
                           message:(NSString *)message
                             style:(LGAlertViewStyle)style
                      buttonTitles:(NSArray *)buttonTitles
                 cancelButtonTitle:(NSString *)cancelButtonTitle
            destructiveButtonTitle:(NSString *)destructiveButtonTitle
{
    return [[self alloc] initWithTitle:title
                               message:message
                                 style:style
                          buttonTitles:buttonTitles
                     cancelButtonTitle:cancelButtonTitle
                destructiveButtonTitle:destructiveButtonTitle];
}

+ (instancetype)alertViewWithViewAndTitle:(NSString *)title
                                  message:(NSString *)message
                                    style:(LGAlertViewStyle)style
                                     view:(UIView *)view
                             buttonTitles:(NSArray *)buttonTitles
                        cancelButtonTitle:(NSString *)cancelButtonTitle
                   destructiveButtonTitle:(NSString *)destructiveButtonTitle
{
    return [[self alloc] initWithViewAndTitle:title
                                      message:message
                                        style:style
                                         view:view
                                 buttonTitles:buttonTitles
                            cancelButtonTitle:cancelButtonTitle
                       destructiveButtonTitle:destructiveButtonTitle];
}

+ (instancetype)alertViewWithActivityIndicatorAndTitle:(NSString *)title
                                               message:(NSString *)message
                                                 style:(LGAlertViewStyle)style
                                          buttonTitles:(NSArray *)buttonTitles
                                     cancelButtonTitle:(NSString *)cancelButtonTitle
                                destructiveButtonTitle:(NSString *)destructiveButtonTitle
{
    return [[self alloc] initWithActivityIndicatorAndTitle:title
                                                   message:message
                                                     style:style
                                              buttonTitles:buttonTitles
                                         cancelButtonTitle:cancelButtonTitle
                                    destructiveButtonTitle:destructiveButtonTitle];
}

+ (instancetype)alertViewWithProgressViewAndTitle:(NSString *)title
                                          message:(NSString *)message
                                            style:(LGAlertViewStyle)style
                                progressLabelText:(NSString *)progressLabelText
                                     buttonTitles:(NSArray *)buttonTitles
                                cancelButtonTitle:(NSString *)cancelButtonTitle
                           destructiveButtonTitle:(NSString *)destructiveButtonTitle
{
    return [[self alloc] initWithProgressViewAndTitle:title
                                              message:message
                                                style:style
                                    progressLabelText:progressLabelText
                                         buttonTitles:buttonTitles
                                    cancelButtonTitle:cancelButtonTitle
                               destructiveButtonTitle:destructiveButtonTitle];
}

+ (instancetype)alertViewWithTextFieldsAndTitle:(NSString *)title
                                        message:(NSString *)message
                             numberOfTextFields:(NSUInteger)numberOfTextFields
                         textFieldsSetupHandler:(void(^)(UITextField *textField, NSUInteger index))textFieldsSetupHandler
                                   buttonTitles:(NSArray *)buttonTitles
                              cancelButtonTitle:(NSString *)cancelButtonTitle
                         destructiveButtonTitle:(NSString *)destructiveButtonTitle
{
    return [[self alloc] initWithTextFieldsAndTitle:title
                                            message:message
                                 numberOfTextFields:numberOfTextFields
                             textFieldsSetupHandler:textFieldsSetupHandler
                                       buttonTitles:buttonTitles
                                  cancelButtonTitle:cancelButtonTitle
                             destructiveButtonTitle:destructiveButtonTitle];
}

#pragma mark -

- (instancetype)initWithTitle:(NSString *)title
                      message:(NSString *)message
                        style:(LGAlertViewStyle)style
                 buttonTitles:(NSArray *)buttonTitles
            cancelButtonTitle:(NSString *)cancelButtonTitle
       destructiveButtonTitle:(NSString *)destructiveButtonTitle
                actionHandler:(void(^)(LGAlertView *alertView, NSString *title, NSUInteger index))actionHandler
                cancelHandler:(void(^)(LGAlertView *alertView))cancelHandler
           destructiveHandler:(void(^)(LGAlertView *alertView))destructiveHandler
{
    self = [self initWithTitle:title
                       message:message
                         style:style
                  buttonTitles:buttonTitles
             cancelButtonTitle:cancelButtonTitle
        destructiveButtonTitle:destructiveButtonTitle];
    if (self)
    {
        _actionHandler = actionHandler;
        _cancelHandler = cancelHandler;
        _destructiveHandler = destructiveHandler;
    }
    return self;
}

- (instancetype)initWithViewAndTitle:(NSString *)title
                             message:(NSString *)message
                               style:(LGAlertViewStyle)style
                                view:(UIView *)view
                        buttonTitles:(NSArray *)buttonTitles
                   cancelButtonTitle:(NSString *)cancelButtonTitle
              destructiveButtonTitle:(NSString *)destructiveButtonTitle
                       actionHandler:(void(^)(LGAlertView *alertView, NSString *title, NSUInteger index))actionHandler
                       cancelHandler:(void(^)(LGAlertView *alertView))cancelHandler
                  destructiveHandler:(void(^)(LGAlertView *alertView))destructiveHandler
{
    self = [self initWithViewAndTitle:title
                              message:message
                                style:style
                                 view:view
                         buttonTitles:buttonTitles
                    cancelButtonTitle:cancelButtonTitle
               destructiveButtonTitle:destructiveButtonTitle];
    if (self)
    {
        _actionHandler = actionHandler;
        _cancelHandler = cancelHandler;
        _destructiveHandler = destructiveHandler;
    }
    return self;
}

- (instancetype)initWithActivityIndicatorAndTitle:(NSString *)title
                                          message:(NSString *)message
                                            style:(LGAlertViewStyle)style
                                     buttonTitles:(NSArray *)buttonTitles
                                cancelButtonTitle:(NSString *)cancelButtonTitle
                           destructiveButtonTitle:(NSString *)destructiveButtonTitle
                                    actionHandler:(void(^)(LGAlertView *alertView, NSString *title, NSUInteger index))actionHandler
                                    cancelHandler:(void(^)(LGAlertView *alertView))cancelHandler
                               destructiveHandler:(void(^)(LGAlertView *alertView))destructiveHandler
{
    self = [self initWithActivityIndicatorAndTitle:title
                                           message:message
                                             style:style
                                      buttonTitles:buttonTitles
                                 cancelButtonTitle:cancelButtonTitle
                            destructiveButtonTitle:destructiveButtonTitle];
    if (self)
    {
        _actionHandler = actionHandler;
        _cancelHandler = cancelHandler;
        _destructiveHandler = destructiveHandler;
    }
    return self;
}

- (instancetype)initWithProgressViewAndTitle:(NSString *)title
                                     message:(NSString *)message
                                       style:(LGAlertViewStyle)style
                           progressLabelText:(NSString *)progressLabelText
                                buttonTitles:(NSArray *)buttonTitles
                           cancelButtonTitle:(NSString *)cancelButtonTitle
                      destructiveButtonTitle:(NSString *)destructiveButtonTitle
                               actionHandler:(void(^)(LGAlertView *alertView, NSString *title, NSUInteger index))actionHandler
                               cancelHandler:(void(^)(LGAlertView *alertView))cancelHandler
                          destructiveHandler:(void(^)(LGAlertView *alertView))destructiveHandler
{
    self = [self initWithProgressViewAndTitle:title
                                      message:message
                                        style:style
                            progressLabelText:progressLabelText
                                 buttonTitles:buttonTitles
                            cancelButtonTitle:cancelButtonTitle
                       destructiveButtonTitle:destructiveButtonTitle];
    if (self)
    {
        _actionHandler = actionHandler;
        _cancelHandler = cancelHandler;
        _destructiveHandler = destructiveHandler;
    }
    return self;
}

- (instancetype)initWithTextFieldsAndTitle:(NSString *)title
                                   message:(NSString *)message
                        numberOfTextFields:(NSUInteger)numberOfTextFields
                    textFieldsSetupHandler:(void(^)(UITextField *textField, NSUInteger index))textFieldsSetupHandler
                              buttonTitles:(NSArray *)buttonTitles
                         cancelButtonTitle:(NSString *)cancelButtonTitle
                    destructiveButtonTitle:(NSString *)destructiveButtonTitle
                             actionHandler:(void(^)(LGAlertView *alertView, NSString *title, NSUInteger index))actionHandler
                             cancelHandler:(void(^)(LGAlertView *alertView))cancelHandler
                        destructiveHandler:(void(^)(LGAlertView *alertView))destructiveHandler
{
    self = [self initWithTextFieldsAndTitle:title
                                    message:message
                         numberOfTextFields:numberOfTextFields
                     textFieldsSetupHandler:textFieldsSetupHandler
                               buttonTitles:buttonTitles
                          cancelButtonTitle:cancelButtonTitle
                     destructiveButtonTitle:destructiveButtonTitle];
    if (self)
    {
        _actionHandler = actionHandler;
        _cancelHandler = cancelHandler;
        _destructiveHandler = destructiveHandler;
    }
    return self;
}

+ (instancetype)alertViewWithTitle:(NSString *)title
                           message:(NSString *)message
                             style:(LGAlertViewStyle)style
                      buttonTitles:(NSArray *)buttonTitles
                 cancelButtonTitle:(NSString *)cancelButtonTitle
            destructiveButtonTitle:(NSString *)destructiveButtonTitle
                     actionHandler:(void(^)(LGAlertView *alertView, NSString *title, NSUInteger index))actionHandler
                     cancelHandler:(void(^)(LGAlertView *alertView))cancelHandler
                destructiveHandler:(void(^)(LGAlertView *alertView))destructiveHandler
{
    return [[self alloc] initWithTitle:title
                               message:message
                                 style:style
                          buttonTitles:buttonTitles
                     cancelButtonTitle:cancelButtonTitle
                destructiveButtonTitle:destructiveButtonTitle
                         actionHandler:actionHandler
                         cancelHandler:cancelHandler
                    destructiveHandler:destructiveHandler];
}

+ (instancetype)alertViewWithViewAndTitle:(NSString *)title
                                  message:(NSString *)message
                                    style:(LGAlertViewStyle)style
                                     view:(UIView *)view
                             buttonTitles:(NSArray *)buttonTitles
                        cancelButtonTitle:(NSString *)cancelButtonTitle
                   destructiveButtonTitle:(NSString *)destructiveButtonTitle
                            actionHandler:(void(^)(LGAlertView *alertView, NSString *title, NSUInteger index))actionHandler
                            cancelHandler:(void(^)(LGAlertView *alertView))cancelHandler
                       destructiveHandler:(void(^)(LGAlertView *alertView))destructiveHandler
{
    return [[self alloc] initWithViewAndTitle:title
                                      message:message
                                        style:style
                                         view:view
                                 buttonTitles:buttonTitles
                            cancelButtonTitle:cancelButtonTitle
                       destructiveButtonTitle:destructiveButtonTitle
                                actionHandler:actionHandler
                                cancelHandler:cancelHandler
                           destructiveHandler:destructiveHandler];
}

+ (instancetype)alertViewWithActivityIndicatorAndTitle:(NSString *)title
                                               message:(NSString *)message
                                                 style:(LGAlertViewStyle)style
                                          buttonTitles:(NSArray *)buttonTitles
                                     cancelButtonTitle:(NSString *)cancelButtonTitle
                                destructiveButtonTitle:(NSString *)destructiveButtonTitle
                                         actionHandler:(void(^)(LGAlertView *alertView, NSString *title, NSUInteger index))actionHandler
                                         cancelHandler:(void(^)(LGAlertView *alertView))cancelHandler
                                    destructiveHandler:(void(^)(LGAlertView *alertView))destructiveHandler
{
    return [[self alloc] initWithActivityIndicatorAndTitle:title
                                                   message:message
                                                     style:style
                                              buttonTitles:buttonTitles
                                         cancelButtonTitle:cancelButtonTitle
                                    destructiveButtonTitle:destructiveButtonTitle
                                             actionHandler:actionHandler
                                             cancelHandler:cancelHandler
                                        destructiveHandler:destructiveHandler];
}

+ (instancetype)alertViewWithProgressViewAndTitle:(NSString *)title
                                          message:(NSString *)message
                                            style:(LGAlertViewStyle)style
                                progressLabelText:(NSString *)progressLabelText
                                     buttonTitles:(NSArray *)buttonTitles
                                cancelButtonTitle:(NSString *)cancelButtonTitle
                           destructiveButtonTitle:(NSString *)destructiveButtonTitle
                                    actionHandler:(void(^)(LGAlertView *alertView, NSString *title, NSUInteger index))actionHandler
                                    cancelHandler:(void(^)(LGAlertView *alertView))cancelHandler
                               destructiveHandler:(void(^)(LGAlertView *alertView))destructiveHandler
{
    return [[self alloc] initWithProgressViewAndTitle:title
                                              message:message
                                                style:style
                                    progressLabelText:progressLabelText
                                         buttonTitles:buttonTitles
                                    cancelButtonTitle:cancelButtonTitle
                               destructiveButtonTitle:destructiveButtonTitle
                                        actionHandler:actionHandler
                                        cancelHandler:cancelHandler
                                   destructiveHandler:destructiveHandler];
}

+ (instancetype)alertViewWithTextFieldsAndTitle:(NSString *)title
                                        message:(NSString *)message
                             numberOfTextFields:(NSUInteger)numberOfTextFields
                         textFieldsSetupHandler:(void(^)(UITextField *textField, NSUInteger index))textFieldsSetupHandler
                                   buttonTitles:(NSArray *)buttonTitles
                              cancelButtonTitle:(NSString *)cancelButtonTitle
                         destructiveButtonTitle:(NSString *)destructiveButtonTitle
                                  actionHandler:(void(^)(LGAlertView *alertView, NSString *title, NSUInteger index))actionHandler
                                  cancelHandler:(void(^)(LGAlertView *alertView))cancelHandler
                             destructiveHandler:(void(^)(LGAlertView *alertView))destructiveHandler
{
    return [[self alloc] initWithTextFieldsAndTitle:title
                                            message:message
                                 numberOfTextFields:numberOfTextFields
                             textFieldsSetupHandler:textFieldsSetupHandler
                                       buttonTitles:buttonTitles
                                  cancelButtonTitle:cancelButtonTitle
                             destructiveButtonTitle:destructiveButtonTitle
                                      actionHandler:actionHandler
                                      cancelHandler:cancelHandler
                                 destructiveHandler:destructiveHandler];
}

#pragma mark -

- (instancetype)initWithTitle:(NSString *)title
                      message:(NSString *)message
                        style:(LGAlertViewStyle)style
                 buttonTitles:(NSArray *)buttonTitles
            cancelButtonTitle:(NSString *)cancelButtonTitle
       destructiveButtonTitle:(NSString *)destructiveButtonTitle
                     delegate:(id<LGAlertViewDelegate>)delegate
{
    self = [self initWithTitle:title
                       message:message
                         style:style
                  buttonTitles:buttonTitles
             cancelButtonTitle:cancelButtonTitle
        destructiveButtonTitle:destructiveButtonTitle];
    if (self)
    {
        _delegate = delegate;
    }
    return self;
}

- (instancetype)initWithViewAndTitle:(NSString *)title
                             message:(NSString *)message
                               style:(LGAlertViewStyle)style
                                view:(UIView *)view
                        buttonTitles:(NSArray *)buttonTitles
                   cancelButtonTitle:(NSString *)cancelButtonTitle
              destructiveButtonTitle:(NSString *)destructiveButtonTitle
                            delegate:(id<LGAlertViewDelegate>)delegate
{
    self = [self initWithViewAndTitle:title
                              message:message
                                style:style
                                 view:view
                         buttonTitles:buttonTitles
                    cancelButtonTitle:cancelButtonTitle
               destructiveButtonTitle:destructiveButtonTitle];
    if (self)
    {
        _delegate = delegate;
    }
    return self;
}

- (instancetype)initWithActivityIndicatorAndTitle:(NSString *)title
                                          message:(NSString *)message
                                            style:(LGAlertViewStyle)style
                                     buttonTitles:(NSArray *)buttonTitles
                                cancelButtonTitle:(NSString *)cancelButtonTitle
                           destructiveButtonTitle:(NSString *)destructiveButtonTitle
                                         delegate:(id<LGAlertViewDelegate>)delegate
{
    self = [self initWithActivityIndicatorAndTitle:title
                                           message:message
                                             style:style
                                      buttonTitles:buttonTitles
                                 cancelButtonTitle:cancelButtonTitle
                            destructiveButtonTitle:destructiveButtonTitle];
    if (self)
    {
        _delegate = delegate;
    }
    return self;
}

- (instancetype)initWithProgressViewAndTitle:(NSString *)title
                                     message:(NSString *)message
                                       style:(LGAlertViewStyle)style
                           progressLabelText:(NSString *)progressLabelText
                                buttonTitles:(NSArray *)buttonTitles
                           cancelButtonTitle:(NSString *)cancelButtonTitle
                      destructiveButtonTitle:(NSString *)destructiveButtonTitle
                                    delegate:(id<LGAlertViewDelegate>)delegate
{
    self = [self initWithProgressViewAndTitle:title
                                      message:message
                                        style:style
                            progressLabelText:progressLabelText
                                 buttonTitles:buttonTitles
                            cancelButtonTitle:cancelButtonTitle
                       destructiveButtonTitle:destructiveButtonTitle];
    if (self)
    {
        _delegate = delegate;
    }
    return self;
}

- (instancetype)initWithTextFieldsAndTitle:(NSString *)title
                                   message:(NSString *)message
                        numberOfTextFields:(NSUInteger)numberOfTextFields
                    textFieldsSetupHandler:(void(^)(UITextField *textField, NSUInteger index))textFieldsSetupHandler
                              buttonTitles:(NSArray *)buttonTitles
                         cancelButtonTitle:(NSString *)cancelButtonTitle
                    destructiveButtonTitle:(NSString *)destructiveButtonTitle
                                  delegate:(id<LGAlertViewDelegate>)delegate
{
    self = [self initWithTextFieldsAndTitle:title
                                    message:message
                         numberOfTextFields:numberOfTextFields
                     textFieldsSetupHandler:textFieldsSetupHandler
                               buttonTitles:buttonTitles
                          cancelButtonTitle:cancelButtonTitle
                     destructiveButtonTitle:destructiveButtonTitle];
    if (self)
    {
        _delegate = delegate;
    }
    return self;
}

+ (instancetype)alertViewWithTitle:(NSString *)title
                           message:(NSString *)message
                             style:(LGAlertViewStyle)style
                      buttonTitles:(NSArray *)buttonTitles
                 cancelButtonTitle:(NSString *)cancelButtonTitle
            destructiveButtonTitle:(NSString *)destructiveButtonTitle
                          delegate:(id<LGAlertViewDelegate>)delegate
{
    return [[self alloc] initWithTitle:title
                               message:message
                                 style:style
                          buttonTitles:buttonTitles
                     cancelButtonTitle:cancelButtonTitle
                destructiveButtonTitle:destructiveButtonTitle
                              delegate:delegate];
}

+ (instancetype)alertViewWithViewAndTitle:(NSString *)title
                                  message:(NSString *)message
                                    style:(LGAlertViewStyle)style
                                     view:(UIView *)view
                             buttonTitles:(NSArray *)buttonTitles
                        cancelButtonTitle:(NSString *)cancelButtonTitle
                   destructiveButtonTitle:(NSString *)destructiveButtonTitle
                                 delegate:(id<LGAlertViewDelegate>)delegate
{
    return [[self alloc] initWithViewAndTitle:title
                                      message:message
                                        style:style
                                         view:view
                                 buttonTitles:buttonTitles
                            cancelButtonTitle:cancelButtonTitle
                       destructiveButtonTitle:destructiveButtonTitle
                                     delegate:delegate];
}

+ (instancetype)alertViewWithActivityIndicatorAndTitle:(NSString *)title
                                               message:(NSString *)message
                                                 style:(LGAlertViewStyle)style
                                          buttonTitles:(NSArray *)buttonTitles
                                     cancelButtonTitle:(NSString *)cancelButtonTitle
                                destructiveButtonTitle:(NSString *)destructiveButtonTitle
                                              delegate:(id<LGAlertViewDelegate>)delegate
{
    return [[self alloc] initWithActivityIndicatorAndTitle:title
                                                   message:message
                                                     style:style
                                              buttonTitles:buttonTitles
                                         cancelButtonTitle:cancelButtonTitle
                                    destructiveButtonTitle:destructiveButtonTitle
                                                  delegate:delegate];
}

+ (instancetype)alertViewWithProgressViewAndTitle:(NSString *)title
                                          message:(NSString *)message
                                            style:(LGAlertViewStyle)style
                                progressLabelText:(NSString *)progressLabelText
                                     buttonTitles:(NSArray *)buttonTitles
                                cancelButtonTitle:(NSString *)cancelButtonTitle
                           destructiveButtonTitle:(NSString *)destructiveButtonTitle
                                         delegate:(id<LGAlertViewDelegate>)delegate
{
    return [[self alloc] initWithProgressViewAndTitle:title
                                              message:message
                                                style:style
                                    progressLabelText:progressLabelText
                                         buttonTitles:buttonTitles
                                    cancelButtonTitle:cancelButtonTitle
                               destructiveButtonTitle:destructiveButtonTitle
                                             delegate:delegate];
}

+ (instancetype)alertViewWithTextFieldsAndTitle:(NSString *)title
                                        message:(NSString *)message
                             numberOfTextFields:(NSUInteger)numberOfTextFields
                         textFieldsSetupHandler:(void(^)(UITextField *textField, NSUInteger index))textFieldsSetupHandler
                                   buttonTitles:(NSArray *)buttonTitles
                              cancelButtonTitle:(NSString *)cancelButtonTitle
                         destructiveButtonTitle:(NSString *)destructiveButtonTitle
                                       delegate:(id<LGAlertViewDelegate>)delegate
{
    return [[self alloc] alertViewWithTextFieldsAndTitle:title
                                                 message:message
                                      numberOfTextFields:numberOfTextFields
                                  textFieldsSetupHandler:textFieldsSetupHandler
                                            buttonTitles:buttonTitles
                                       cancelButtonTitle:cancelButtonTitle
                                  destructiveButtonTitle:destructiveButtonTitle
                                                delegate:delegate];
}

#pragma mark -

- (void)setupDefaults
{
    if (!kLGAlertViewWindowsArray)
        kLGAlertViewWindowsArray = [NSMutableArray new];

    if (!kLGAlertViewArray)
        kLGAlertViewArray = [NSMutableArray new];

    // -----

    _buttonsEnabledArray = [NSMutableArray new];

    for (NSUInteger i=0; i<_buttonTitles.count; i++)
        [_buttonsEnabledArray addObject:[NSNumber numberWithBool:YES]];

    // -----

    _cancelOnTouch = !(_type == LGAlertViewTypeActivityIndicator || _type == LGAlertViewTypeProgressView || _type == LGAlertViewTypeTextFields);

    // -----

    _coverColor = [UIColor colorWithWhite:0.f alpha:0.5];
    _backgroundColor = [UIColor whiteColor];

    // -----

    _buttonsHeight = (([UIDevice currentDevice].systemVersion.floatValue < 9.0 || _style == LGAlertViewStyleAlert) ? 44.f : 56.f);
    _textFieldsHeight = 44.f;
    _offsetVertical = -1;
    _cancelButtonOffsetY = kLGAlertViewOffsetHorizontal;
    _heightMax = -1.f;
    _width = -1.f;

    // -----

    _layerCornerRadius = ([UIDevice currentDevice].systemVersion.floatValue < 9.0 ? 6.f : 12.f);
    _layerBorderColor = nil;
    _layerBorderWidth = 0.f;
    _layerShadowColor = nil;
    _layerShadowRadius = 0.f;
    _layerShadowOpacity = 1.f;
    _layerShadowOffset = CGSizeZero;

    // -----

    if (_style == LGAlertViewStyleAlert)
    {
        _titleTextColor     = [UIColor blackColor];
        _titleTextAlignment = NSTextAlignmentCenter;
        _titleFont          = [UIFont boldSystemFontOfSize:18.f];
    }
    else
    {
        _titleTextColor     = [UIColor grayColor];
        _titleTextAlignment = NSTextAlignmentCenter;
        _titleFont          = [UIFont boldSystemFontOfSize:14.f];
    }

    if (_style == LGAlertViewStyleAlert)
    {
        _messageTextColor     = [UIColor blackColor];
        _messageTextAlignment = NSTextAlignmentCenter;
        _messageFont          = [UIFont systemFontOfSize:14.f];
    }
    else
    {
        _messageTextColor     = [UIColor grayColor];
        _messageTextAlignment = NSTextAlignmentCenter;
        _messageFont          = [UIFont systemFontOfSize:14.f];
    }

    // -----

    if (!kLGAlertViewTintColor)
        kLGAlertViewTintColor = [UIColor colorWithRed:0.f green:0.5 blue:1.f alpha:1.f];

    _tintColor = kLGAlertViewTintColor;

    // -----

    _buttonsTitleColor                 = _tintColor;
    _buttonsTitleColorHighlighted      = [UIColor whiteColor];
    _buttonsTitleColorDisabled         = [UIColor grayColor];
    _buttonsTextAlignment              = NSTextAlignmentCenter;
    _buttonsFont                       = [UIFont systemFontOfSize:18.f];
    _buttonsNumberOfLines              = 1;
    _buttonsLineBreakMode              = NSLineBreakByTruncatingMiddle;
    _buttonsAdjustsFontSizeToFitWidth  = YES;
    _buttonsMinimumScaleFactor         = 14.f/18.f;
    _buttonsBackgroundColor            = nil;
    _buttonsBackgroundColorHighlighted = _tintColor;
    _buttonsBackgroundColorDisabled    = nil;
    _buttonsEnabled                    = YES;

    _cancelButtonTitleColor                 = _tintColor;
    _cancelButtonTitleColorHighlighted      = [UIColor whiteColor];
    _cancelButtonTitleColorDisabled         = [UIColor grayColor];
    _cancelButtonTextAlignment              = NSTextAlignmentCenter;
    _cancelButtonFont                       = [UIFont boldSystemFontOfSize:18.f];
    _cancelButtonNumberOfLines              = 1;
    _cancelButtonLineBreakMode              = NSLineBreakByTruncatingMiddle;
    _cancelButtonAdjustsFontSizeToFitWidth  = YES;
    _cancelButtonMinimumScaleFactor         = 14.f/18.f;
    _cancelButtonBackgroundColor            = nil;
    _cancelButtonBackgroundColorHighlighted = _tintColor;
    _cancelButtonBackgroundColorDisabled    = nil;
    _cancelButtonEnabled                    = YES;

    _destructiveButtonTitleColor                 = [UIColor redColor];
    _destructiveButtonTitleColorHighlighted      = [UIColor whiteColor];
    _destructiveButtonTitleColorDisabled         = [UIColor grayColor];
    _destructiveButtonTextAlignment              = NSTextAlignmentCenter;
    _destructiveButtonFont                       = [UIFont systemFontOfSize:18.f];
    _destructiveButtonNumberOfLines              = 1;
    _destructiveButtonLineBreakMode              = NSLineBreakByTruncatingMiddle;
    _destructiveButtonAdjustsFontSizeToFitWidth  = YES;
    _destructiveButtonMinimumScaleFactor         = 14.f/18.f;
    _destructiveButtonBackgroundColor            = nil;
    _destructiveButtonBackgroundColorHighlighted = [UIColor redColor];
    _destructiveButtonBackgroundColorDisabled    = nil;
    _destructiveButtonEnabled                    = YES;

    // -----

    self.colorful = kLGAlertViewColorful;

    // -----

    _activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    _activityIndicatorViewColor = _tintColor;

    _progressViewProgressTintColor = _tintColor;
    _progressViewTrackTintColor    = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.f];
    _progressViewProgressImage     = nil;
    _progressViewTrackImage        = nil;

    _progressLabelTextColor     = [UIColor blackColor];
    _progressLabelTextAlignment = NSTextAlignmentCenter;
    _progressLabelFont          = [UIFont systemFontOfSize:14.f];

    _separatorsColor = [UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1.f];

    _indicatorStyle = UIScrollViewIndicatorStyleBlack;
    _showsVerticalScrollIndicator = NO;

    // -----

    _view = [UIView new];
    _view.backgroundColor = [UIColor clearColor];
    _view.userInteractionEnabled = YES;
    _view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    _backgroundView = [UIView new];
    _backgroundView.alpha = 0.f;
    _backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_view addSubview:_backgroundView];

    // -----

    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cancelAction:)];
    tapGesture.delegate = self;
    [_backgroundView addGestureRecognizer:tapGesture];

    // -----

    _viewController = [[LGAlertViewController alloc] initWithAlertView:self view:_view];

    _window = [[LGAlertViewWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    _window.hidden = YES;
    _window.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _window.opaque = NO;
    _window.backgroundColor = [UIColor clearColor];
    _window.rootViewController = _viewController;
}

#pragma mark - Dealloc

- (void)dealloc
{
#if DEBUG
    NSLog(@"%s [Line %d]", __PRETTY_FUNCTION__, __LINE__);
#endif
}

#pragma mark - Observers

- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowVisibleChanged:) name:UIWindowDidBecomeVisibleNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowVisibleChanged:) name:UIWindowDidBecomeHiddenNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardVisibleChanged:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardVisibleChanged:) name:UIKeyboardWillHideNotification object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameChanged:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIWindowDidBecomeVisibleNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIWindowDidBecomeHiddenNotification object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillChangeFrameNotification object:nil];
}

#pragma mark - Window notifications

- (void)windowVisibleChanged:(NSNotification *)notification
{
    NSUInteger windowIndex = [kLGAlertViewWindowsArray indexOfObject:_window];

    //NSLog(@"windowVisibleChanged: %@", notification);

    UIWindow *windowNotif = notification.object;

    //NSLog(@"%@", NSStringFromClass([window class]));

    if ([NSStringFromClass([windowNotif class]) isEqualToString:@"UITextEffectsWindow"] ||
        [NSStringFromClass([windowNotif class]) isEqualToString:@"UIRemoteKeyboardWindow"] ||
        [NSStringFromClass([windowNotif class]) isEqualToString:@"LGAlertViewWindow"] ||
        [windowNotif isEqual:_window]) return;

    if (notification.name == UIWindowDidBecomeVisibleNotification)
    {
        if ([windowNotif isEqual:kLGAlertViewWindowPrevious(windowIndex)])
        {
            windowNotif.hidden = YES;

            [_window makeKeyAndVisible];
        }
        else if (!kLGAlertViewWindowNext(windowIndex))
        {
            _window.hidden = YES;

            [kLGAlertViewWindowsArray addObject:windowNotif];
        }
    }
    else if (notification.name == UIWindowDidBecomeHiddenNotification)
    {
        if ([windowNotif isEqual:kLGAlertViewWindowNext(windowIndex)] && [windowNotif isEqual:kLGAlertViewWindowsArray.lastObject])
        {
            [_window makeKeyAndVisible];

            [kLGAlertViewWindowsArray removeLastObject];
        }
    }
}

#pragma mark - Keyboard notifications

- (void)keyboardVisibleChanged:(NSNotification *)notification
{
    [LGAlertView keyboardAnimateWithNotificationUserInfo:notification.userInfo
                                              animations:^(CGFloat keyboardHeight)
     {
         if ([notification.name isEqualToString:UIKeyboardWillShowNotification])
             _keyboardHeight = keyboardHeight;
         else
             _keyboardHeight = 0.f;

         [self layoutInvalidateWithSize:_view.frame.size];
     }];
}

- (void)keyboardFrameChanged:(NSNotification *)notification
{
    //NSLog(@"%@", notification);

    if ([notification.userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue] == 0.f)
        _keyboardHeight = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height;
}

#pragma mark - UITextField Delegate

- (BOOL)textFieldShouldReturn:(LGAlertViewTextField *)textField
{
    if (textField.returnKeyType == UIReturnKeyNext)
    {
        if (_textFieldsArray.count > textField.tag+1)
        {
            LGAlertViewTextField *nextTextField = _textFieldsArray[textField.tag+1];
            [nextTextField becomeFirstResponder];
        }
    }
    else if (textField.returnKeyType == UIReturnKeyDone)
    {
        [textField resignFirstResponder];
    }

    return YES;
}

#pragma mark - UIGestureRecognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return self.isCancelOnTouch;
}

#pragma mark - Setters and Getters

- (void)setColorful:(BOOL)colorful
{
    _colorful = colorful;

    if (_colorful)
    {
        if (!self.isUserButtonsTitleColorHighlighted)
            _buttonsTitleColorHighlighted = [UIColor whiteColor];
        if (!self.isUserButtonsBackgroundColorHighlighted)
            _buttonsBackgroundColorHighlighted = _tintColor;

        if (!self.isUserCancelButtonTitleColorHighlighted)
            _cancelButtonTitleColorHighlighted = [UIColor whiteColor];
        if (!self.isUserCancelButtonBackgroundColorHighlighted)
            _cancelButtonBackgroundColorHighlighted = _tintColor;

        if (!self.isUserDestructiveButtonTitleColorHighlighted)
            _destructiveButtonTitleColorHighlighted = [UIColor whiteColor];
        if (!self.isUserDestructiveButtonBackgroundColorHighlighted)
            _destructiveButtonBackgroundColorHighlighted = [UIColor redColor];
    }
    else
    {
        if (!self.isUserButtonsTitleColorHighlighted)
            _buttonsTitleColorHighlighted = _buttonsTitleColor;
        if (!self.isUserButtonsBackgroundColorHighlighted)
            _buttonsBackgroundColorHighlighted = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.f];

        if (!self.isUserCancelButtonTitleColorHighlighted)
            _cancelButtonTitleColorHighlighted = _cancelButtonTitleColor;
        if (!self.isUserCancelButtonBackgroundColorHighlighted)
            _cancelButtonBackgroundColorHighlighted = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.f];

        if (!self.isUserDestructiveButtonTitleColorHighlighted)
            _destructiveButtonTitleColorHighlighted = _destructiveButtonTitleColor;
        if (!self.isUserDestructiveButtonBackgroundColorHighlighted)
            _destructiveButtonBackgroundColorHighlighted = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.f];
    }
}

- (void)setTintColor:(UIColor *)tintColor
{
    _tintColor = tintColor;

    if (!self.isUserButtonsTitleColor)
        _buttonsTitleColor = _tintColor;
    if (!self.isUserCancelButtonTitleColor)
        _cancelButtonTitleColor = _tintColor;

    if (!self.isColorful)
    {
        if (!self.isUserButtonsTitleColorHighlighted)
            _buttonsTitleColorHighlighted = _tintColor;
        if (!self.isUserCancelButtonTitleColorHighlighted)
            _cancelButtonTitleColorHighlighted = _tintColor;
    }

    if (!self.isUserButtonsBackgroundColorHighlighted)
        _buttonsBackgroundColorHighlighted = _tintColor;
    if (!self.isUserCancelButtonBackgroundColorHighlighted)
        _cancelButtonBackgroundColorHighlighted = _tintColor;

    if (!self.isUserActivityIndicatorViewColor)
        _activityIndicatorViewColor = _tintColor;
    if (!self.isUserProgressViewProgressTintColor)
        _progressViewProgressTintColor = _tintColor;
}

- (void)setButtonsHeight:(CGFloat)buttonsHeight
{
    if (buttonsHeight < 0) buttonsHeight = 0;

    _buttonsHeight = buttonsHeight;
}

- (void)setTextFieldsHeight:(CGFloat)textFieldsHeight
{
    if (textFieldsHeight < 0) textFieldsHeight = 0;

    _textFieldsHeight = textFieldsHeight;
}

- (void)setButtonsTitleColor:(UIColor *)buttonsTitleColor
{
    _buttonsTitleColor = buttonsTitleColor;

    _userButtonsTitleColor = YES;
}

- (void)setButtonsTitleColorHighlighted:(UIColor *)buttonsTitleColorHighlighted
{
    _buttonsTitleColorHighlighted = buttonsTitleColorHighlighted;

    _userButtonsTitleColorHighlighted = YES;
}

- (void)setButtonsBackgroundColorHighlighted:(UIColor *)buttonsBackgroundColorHighlighted
{
    _buttonsBackgroundColorHighlighted = buttonsBackgroundColorHighlighted;

    _userButtonsBackgroundColorHighlighted = YES;
}

- (void)setCancelButtonTitleColor:(UIColor *)cancelButtonTitleColor
{
    _cancelButtonTitleColor = cancelButtonTitleColor;

    _userCancelButtonTitleColor = YES;
}

- (void)setCancelButtonTitleColorHighlighted:(UIColor *)cancelButtonTitleColorHighlighted
{
    _cancelButtonTitleColorHighlighted = cancelButtonTitleColorHighlighted;

    _userCancelButtonTitleColorHighlighted = YES;
}

- (void)setCancelButtonBackgroundColorHighlighted:(UIColor *)cancelButtonBackgroundColorHighlighted
{
    _cancelButtonBackgroundColorHighlighted = cancelButtonBackgroundColorHighlighted;

    _userCancelButtonBackgroundColorHighlighted = YES;
}

- (void)setDestructiveButtonTitleColorHighlighted:(UIColor *)destructiveButtonTitleColorHighlighted
{
    _destructiveButtonTitleColorHighlighted = destructiveButtonTitleColorHighlighted;

    _userDestructiveButtonTitleColorHighlighted = YES;
}

- (void)setDestructiveButtonBackgroundColorHighlighted:(UIColor *)destructiveButtonBackgroundColorHighlighted
{
    _destructiveButtonBackgroundColorHighlighted = destructiveButtonBackgroundColorHighlighted;

    _userDestructiveButtonBackgroundColorHighlighted = YES;
}

- (void)setActivityIndicatorViewColor:(UIColor *)activityIndicatorViewColor
{
    _activityIndicatorViewColor = activityIndicatorViewColor;

    _userActivityIndicatorViewColor = YES;
}

- (void)setProgressViewProgressTintColor:(UIColor *)progressViewProgressTintColor
{
    _progressViewProgressTintColor = progressViewProgressTintColor;

    _userProgressViewProgressTintColor = YES;
}

- (BOOL)isShowing
{
    return (_showing && _window.isKeyWindow && !_window.isHidden);
}

#pragma mark - Class methods

+ (void)setTintColor:(UIColor *)color
{
    kLGAlertViewTintColor = color;
}

+ (void)setColorful:(BOOL)colorful
{
    kLGAlertViewColorful = colorful;
}

+ (NSArray *)getAlertViewsArray
{
    if (!kLGAlertViewArray)
        kLGAlertViewArray = [NSMutableArray new];

    return kLGAlertViewArray;
}

#pragma mark -

- (void)setProgress:(float)progress progressLabelText:(NSString *)progressLabelText
{
    if (_type == LGAlertViewTypeProgressView)
    {
        [_progressView setProgress:progress animated:YES];

        _progressLabel.text = progressLabelText;
    }
}

- (float)progress
{
    float progress = 0.f;

    if (_type == LGAlertViewTypeProgressView)
        progress = _progressView.progress;

    return progress;
}

- (void)setButtonAtIndex:(NSUInteger)index enabled:(BOOL)enabled
{
    if (_buttonTitles.count > index)
    {
        _buttonsEnabledArray[index] = [NSNumber numberWithBool:enabled];

        if (_tableView)
        {
            if (_destructiveButtonTitle.length)
                index++;

            LGAlertViewCell *cell = (LGAlertViewCell *)[_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
            cell.enabled = enabled;
        }
        else if (_scrollView)
        {
            switch (index)
            {
                case 0:
                    _firstButton.enabled = enabled;
                    break;
                case 1:
                    _secondButton.enabled = enabled;
                    break;
                case 2:
                    _thirdButton.enabled = enabled;
                    break;
                default:
                    break;
            }
        }
    }
}

- (BOOL)isButtonEnabledAtIndex:(NSUInteger)index
{
    return [_buttonsEnabledArray[index] boolValue];
}

- (void)setButtonPropertiesAtIndex:(NSUInteger)index
                           handler:(void(^)(LGAlertViewButtonProperties *properties))handler;
{
    if (handler && _buttonTitles.count > index)
    {
        if (!_buttonsPropertiesDictionary)
            _buttonsPropertiesDictionary = [NSMutableDictionary new];

        LGAlertViewButtonProperties *properties = _buttonsPropertiesDictionary[[NSNumber numberWithInteger:index]];
        if (!properties) properties = [LGAlertViewButtonProperties new];

        handler(properties);

        if (properties.isUserEnabled)
            _buttonsEnabledArray[index] = [NSNumber numberWithBool:properties.enabled];

        [_buttonsPropertiesDictionary setObject:properties forKey:[NSNumber numberWithInteger:index]];
    }
}

- (void)forceCancel
{
    NSAssert(_cancelButtonTitle.length > 0, @"Cancel button is not exists");

    [self cancelAction:nil];
}

- (void)forceDestructive
{
    NSAssert(_destructiveButtonTitle.length > 0, @"Destructive button is not exists");

    [self destructiveAction:nil];
}

- (void)forceActionAtIndex:(NSUInteger)index
{
    NSAssert(_buttonTitles.count > index, @"Button at index %lu is not exists", (long unsigned)index);

    [self actionActionAtIndex:index title:_buttonTitles[index + (_tableView && _destructiveButtonTitle.length ? 1 : 0)]];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _buttonTitles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    LGAlertViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];

    cell.title = _buttonTitles[indexPath.row];

    if (_destructiveButtonTitle.length && indexPath.row == 0)
    {
        cell.titleColor                 = _destructiveButtonTitleColor;
        cell.titleColorHighlighted      = _destructiveButtonTitleColorHighlighted;
        cell.titleColorDisabled         = _destructiveButtonTitleColorDisabled;
        cell.backgroundColorNormal      = _destructiveButtonBackgroundColor;
        cell.backgroundColorHighlighted = _destructiveButtonBackgroundColorHighlighted;
        cell.backgroundColorDisabled    = _destructiveButtonBackgroundColorDisabled;
        cell.separatorVisible           = (indexPath.row != _buttonTitles.count-1);
        cell.separatorColor_            = _separatorsColor;
        cell.textAlignment              = _destructiveButtonTextAlignment;
        cell.font                       = _destructiveButtonFont;
        cell.numberOfLines              = _destructiveButtonNumberOfLines;
        cell.lineBreakMode              = _destructiveButtonLineBreakMode;
        cell.adjustsFontSizeToFitWidth  = _destructiveButtonAdjustsFontSizeToFitWidth;
        cell.minimumScaleFactor         = _destructiveButtonMinimumScaleFactor;
        cell.enabled                    = _destructiveButtonEnabled;
    }
    else if (_cancelButtonTitle.length && !kLGAlertViewIsCancelButtonSeparate(self) && indexPath.row == _buttonTitles.count-1)
    {
        cell.titleColor                 = _cancelButtonTitleColor;
        cell.titleColorHighlighted      = _cancelButtonTitleColorHighlighted;
        cell.titleColorDisabled         = _cancelButtonTitleColorDisabled;
        cell.backgroundColorNormal      = _cancelButtonBackgroundColor;
        cell.backgroundColorHighlighted = _cancelButtonBackgroundColorHighlighted;
        cell.backgroundColorDisabled    = _cancelButtonBackgroundColorDisabled;
        cell.separatorVisible           = NO;
        cell.separatorColor_            = _separatorsColor;
        cell.textAlignment              = _cancelButtonTextAlignment;
        cell.font                       = _cancelButtonFont;
        cell.numberOfLines              = _cancelButtonNumberOfLines;
        cell.lineBreakMode              = _cancelButtonLineBreakMode;
        cell.adjustsFontSizeToFitWidth  = _cancelButtonAdjustsFontSizeToFitWidth;
        cell.minimumScaleFactor         = _cancelButtonMinimumScaleFactor;
        cell.enabled                    = _cancelButtonEnabled;
    }
    else
    {
        LGAlertViewButtonProperties *properties = nil;
        if (_buttonsPropertiesDictionary)
            properties = _buttonsPropertiesDictionary[[NSNumber numberWithInteger:(indexPath.row - (_destructiveButtonTitle.length ? 1 : 0))]];

        cell.titleColor                 = (properties.isUserTitleColor ? properties.titleColor : _buttonsTitleColor);
        cell.titleColorHighlighted      = (properties.isUserTitleColorHighlighted ? properties.titleColorHighlighted : _buttonsTitleColorHighlighted);
        cell.titleColorDisabled         = (properties.isUserTitleColorDisabled ? properties.titleColorDisabled : _buttonsTitleColorDisabled);
        cell.backgroundColorNormal      = (properties.isUserBackgroundColor ? properties.backgroundColor : _buttonsBackgroundColor);
        cell.backgroundColorHighlighted = (properties.isUserBackgroundColorHighlighted ? properties.backgroundColorHighlighted : _buttonsBackgroundColorHighlighted);
        cell.backgroundColorDisabled    = (properties.isUserBackgroundColorDisabled ? properties.backgroundColorDisabled : _buttonsBackgroundColorDisabled);
        cell.separatorVisible           = (indexPath.row != _buttonTitles.count-1);
        cell.separatorColor_            = _separatorsColor;
        cell.textAlignment              = (properties.isUserTextAlignment ? properties.textAlignment : _buttonsTextAlignment);
        cell.font                       = (properties.isUserFont ? properties.font : _buttonsFont);
        cell.numberOfLines              = (properties.isUserNumberOfLines ? properties.numberOfLines : _buttonsNumberOfLines);
        cell.lineBreakMode              = (properties.isUserLineBreakMode ? properties.lineBreakMode : _buttonsLineBreakMode);
        cell.adjustsFontSizeToFitWidth  = (properties.isUserAdjustsFontSizeTofitWidth ? properties.adjustsFontSizeToFitWidth : _buttonsAdjustsFontSizeToFitWidth);
        cell.minimumScaleFactor         = (properties.isUserMinimimScaleFactor ? properties.minimumScaleFactor : _buttonsMinimumScaleFactor);
        cell.enabled                    = [_buttonsEnabledArray[indexPath.row - (_destructiveButtonTitle.length ? 1 : 0)] boolValue];
    }

    return cell;
}

#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_destructiveButtonTitle.length && indexPath.row == 0 && _destructiveButtonNumberOfLines != 1)
    {
        NSString *title = _buttonTitles[indexPath.row];

        UILabel *label = [UILabel new];
        label.text = title;
        label.textAlignment             = _destructiveButtonTextAlignment;
        label.font                      = _destructiveButtonFont;
        label.numberOfLines             = _destructiveButtonNumberOfLines;
        label.lineBreakMode             = _destructiveButtonLineBreakMode;
        label.adjustsFontSizeToFitWidth = _destructiveButtonAdjustsFontSizeToFitWidth;
        label.minimumScaleFactor        = _destructiveButtonMinimumScaleFactor;

        CGSize size = [label sizeThatFits:CGSizeMake(tableView.frame.size.width-kLGAlertViewPaddingW*2, CGFLOAT_MAX)];
        size.height += kLGAlertViewButtonTitleMarginH*2;

        if (size.height < _buttonsHeight)
            size.height = _buttonsHeight;

        return size.height;
    }
    else if (_cancelButtonTitle.length && !kLGAlertViewIsCancelButtonSeparate(self) && indexPath.row == _buttonTitles.count-1 && _cancelButtonNumberOfLines != 1)
    {
        NSString *title = _buttonTitles[indexPath.row];

        UILabel *label = [UILabel new];
        label.text = title;
        label.textAlignment             = _cancelButtonTextAlignment;
        label.font                      = _cancelButtonFont;
        label.numberOfLines             = _cancelButtonNumberOfLines;
        label.lineBreakMode             = _cancelButtonLineBreakMode;
        label.adjustsFontSizeToFitWidth = _cancelButtonAdjustsFontSizeToFitWidth;
        label.minimumScaleFactor        = _cancelButtonMinimumScaleFactor;

        CGSize size = [label sizeThatFits:CGSizeMake(tableView.frame.size.width-kLGAlertViewPaddingW*2, CGFLOAT_MAX)];
        size.height += kLGAlertViewButtonTitleMarginH*2;

        if (size.height < _buttonsHeight)
            size.height = _buttonsHeight;

        return size.height;
    }
    else if (_buttonsNumberOfLines != 1)
    {
        NSString *title = _buttonTitles[indexPath.row];

        UILabel *label = [UILabel new];
        label.text = title;
        label.textAlignment             = _buttonsTextAlignment;
        label.font                      = _buttonsFont;
        label.numberOfLines             = _buttonsNumberOfLines;
        label.lineBreakMode             = _buttonsLineBreakMode;
        label.adjustsFontSizeToFitWidth = _buttonsAdjustsFontSizeToFitWidth;
        label.minimumScaleFactor        = _buttonsMinimumScaleFactor;

        CGSize size = [label sizeThatFits:CGSizeMake(tableView.frame.size.width-kLGAlertViewPaddingW*2, CGFLOAT_MAX)];
        size.height += kLGAlertViewButtonTitleMarginH*2;

        if (size.height < _buttonsHeight)
            size.height = _buttonsHeight;

        return size.height;
    }
    else return _buttonsHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_destructiveButtonTitle.length && indexPath.row == 0)
    {
        [self destructiveAction:nil];
    }
    else if (_cancelButtonTitle.length && indexPath.row == _buttonTitles.count-1 && !kLGAlertViewIsCancelButtonSeparate(self))
    {
        [self cancelAction:nil];
    }
    else
    {
        NSUInteger index = indexPath.row;
        if (_destructiveButtonTitle.length) index--;

        NSString *title = _buttonTitles[indexPath.row];

        // -----

        [self actionActionAtIndex:index title:title];
    }
}

#pragma mark -

- (void)showAnimated:(BOOL)animated completionHandler:(void(^)())completionHandler
{
    [self showAnimated:animated hidden:NO completionHandler:completionHandler];
}

- (void)showAnimated:(BOOL)animated hidden:(BOOL)hidden completionHandler:(void(^)())completionHandler
{
    if (self.isShowing) return;

    _window.windowLevel = UIWindowLevelStatusBar + (_windowLevel == LGAlertViewWindowLevelAboveStatusBar ? 1 : -1);
    _view.userInteractionEnabled = NO;

    CGSize size = _viewController.view.bounds.size;

    if ([UIDevice currentDevice].systemVersion.floatValue < 8.0)
    {
        if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation))
            size = CGSizeMake(MIN(size.width, size.height), MAX(size.width, size.height));
        else
            size = CGSizeMake(MAX(size.width, size.height), MIN(size.width, size.height));

        _viewController.view.frame = CGRectMake(0.f, 0.f, size.width, size.height);
    }

    [self subviewsInvalidateWithSize:size];
    [self layoutInvalidateWithSize:size];

    _showing = YES;

    if (![kLGAlertViewArray containsObject:self])
        [kLGAlertViewArray addObject:self];

    // -----

    [self addObservers];

    // -----

    UIWindow *windowApp = [UIApplication sharedApplication].delegate.window;
    NSAssert(windowApp != nil, @"Application needs to have at least one window");

    UIWindow *windowKey = [UIApplication sharedApplication].keyWindow;
    NSAssert(windowKey != nil, @"Application needs to have at least one key and visible window");

    if (!kLGAlertViewWindowsArray.count)
        [kLGAlertViewWindowsArray addObject:windowApp];

    if (![windowKey isEqual:windowApp])
        if (![kLGAlertViewWindowsArray containsObject:windowKey])
            [kLGAlertViewWindowsArray addObject:windowKey];

    if (![kLGAlertViewWindowsArray containsObject:_window])
        [kLGAlertViewWindowsArray addObject:_window];

    if (!hidden)
    {
        if (![windowKey isEqual:windowApp])
            windowKey.hidden = YES;
    }

    [_window makeKeyAndVisible];

    // -----

    if (_willShowHandler) _willShowHandler(self);

    if (_delegate && [_delegate respondsToSelector:@selector(alertViewWillShow:)])
        [_delegate alertViewWillShow:self];

    [[NSNotificationCenter defaultCenter] postNotificationName:kLGAlertViewWillShowNotification object:self userInfo:nil];

    // -----

    if (hidden)
    {
        _backgroundView.hidden = YES;
        _scrollView.hidden = YES;
        _styleView.hidden = YES;

        if (kLGAlertViewIsCancelButtonSeparate(self))
        {
            _cancelButton.hidden = YES;
            _styleCancelView.hidden = YES;
        }
    }

    // -----

    if (animated)
    {
        [LGAlertView animateStandardWithAnimations:^(void)
         {
             [self showAnimations];
         }
                                        completion:^(BOOL finished)
         {
             if (!hidden)
                 [self showComplete];

             if (completionHandler) completionHandler();
         }];
    }
    else
    {
        [self showAnimations];

        if (!hidden)
            [self showComplete];

        if (completionHandler) completionHandler();
    }
}

- (void)showAnimations
{
    _backgroundView.alpha = 1.f;

    if (_style == LGAlertViewStyleAlert || kLGAlertViewPadAndNotForce(self))
    {
        _scrollView.transform = CGAffineTransformIdentity;
        _scrollView.alpha = 1.f;

        _styleView.transform = CGAffineTransformIdentity;
        _styleView.alpha = 1.f;
    }
    else
    {
        _scrollView.center = _scrollViewCenterShowed;

        _styleView.center = _scrollViewCenterShowed;
    }

    if (kLGAlertViewIsCancelButtonSeparate(self) && _cancelButton)
    {
        _cancelButton.center = _cancelButtonCenterShowed;

        _styleCancelView.center = _cancelButtonCenterShowed;
    }
}

- (void)showComplete
{
    if (_type == LGAlertViewTypeTextFields && _textFieldsArray.count)
        [_textFieldsArray[0] becomeFirstResponder];

    // -----

    if (_didShowHandler) _didShowHandler(self);

    if (_delegate && [_delegate respondsToSelector:@selector(alertViewDidShow:)])
        [_delegate alertViewDidShow:self];

    [[NSNotificationCenter defaultCenter] postNotificationName:kLGAlertViewDidShowNotification object:self userInfo:nil];

    // -----

    _view.userInteractionEnabled = YES;
}

- (void)dismissAnimated:(BOOL)animated completionHandler:(void(^)())completionHandler
{
    if (!self.isShowing) return;

    _view.userInteractionEnabled = NO;

    _showing = NO;

    [self removeObservers];

    [_view endEditing:YES];

    // -----

    if (_willDismissHandler) _willDismissHandler(self);

    if (_delegate && [_delegate respondsToSelector:@selector(alertViewWillDismiss:)])
        [_delegate alertViewWillDismiss:self];

    [[NSNotificationCenter defaultCenter] postNotificationName:kLGAlertViewWillDismissNotification object:self userInfo:nil];

    // -----

    if (animated)
    {
        [LGAlertView animateStandardWithAnimations:^(void)
         {
             [self dismissAnimations];
         }
                                        completion:^(BOOL finished)
         {
             [self dismissComplete];

             if (completionHandler) completionHandler();
         }];
    }
    else
    {
        [self dismissAnimations];

        [self dismissComplete];

        if (completionHandler) completionHandler();
    }
}

- (void)dismissAnimations
{
    _backgroundView.alpha = 0.f;

    if (_style == LGAlertViewStyleAlert || kLGAlertViewPadAndNotForce(self))
    {
        _scrollView.transform = CGAffineTransformMakeScale(0.95, 0.95);
        _scrollView.alpha = 0.f;

        _styleView.transform = CGAffineTransformMakeScale(0.95, 0.95);
        _styleView.alpha = 0.f;
    }
    else
    {
        _scrollView.center = _scrollViewCenterHidden;

        _styleView.center = _scrollViewCenterHidden;
    }

    if (kLGAlertViewIsCancelButtonSeparate(self) && _cancelButton)
    {
        _cancelButton.center = _cancelButtonCenterHidden;

        _styleCancelView.center = _cancelButtonCenterHidden;
    }
}

- (void)dismissComplete
{
    _window.hidden = YES;

    if ([kLGAlertViewWindowsArray.lastObject isEqual:_window])
    {
        NSUInteger windowIndex = [kLGAlertViewWindowsArray indexOfObject:_window];

        [kLGAlertViewWindowPrevious(windowIndex) makeKeyAndVisible];
    }

    // -----

    if (_didDismissHandler) _didDismissHandler(self);

    if (_delegate && [_delegate respondsToSelector:@selector(alertViewDidDismiss:)])
        [_delegate alertViewDidDismiss:self];

    [[NSNotificationCenter defaultCenter] postNotificationName:kLGAlertViewDidDismissNotification object:self userInfo:nil];

    // -----

    if ([kLGAlertViewWindowsArray containsObject:_window])
        [kLGAlertViewWindowsArray removeObject:_window];

    if ([kLGAlertViewArray containsObject:self])
        [kLGAlertViewArray removeObject:self];

    _view = nil;
    _viewController = nil;
    _window = nil;
    _delegate = nil;
}

- (void)transitionToAlertView:(LGAlertView *)alertView completionHandler:(void(^)())completionHandler
{
    _view.userInteractionEnabled = NO;

    [alertView showAnimated:NO hidden:YES completionHandler:^(void)
     {
         NSTimeInterval duration = 0.3;

         BOOL cancelButtonSelf = kLGAlertViewIsCancelButtonSeparate(self) && _cancelButtonTitle.length;
         BOOL cancelButtonNext = kLGAlertViewIsCancelButtonSeparate(alertView) && alertView.cancelButtonTitle.length;

         // -----

         [UIView animateWithDuration:duration
                          animations:^(void)
          {
              _scrollView.alpha = 0.f;

              if (cancelButtonSelf)
              {
                  _cancelButton.alpha = 0.f;

                  if (!cancelButtonNext)
                      _styleCancelView.alpha = 0.f;
              }
          }
                          completion:^(BOOL finished)
          {
              alertView.backgroundView.alpha = 0.f;
              alertView.backgroundView.hidden = NO;

              [UIView animateWithDuration:duration*2.f
                               animations:^(void)
               {
                   _backgroundView.alpha = 0.f;
                   alertView.backgroundView.alpha = 1.f;
               }];

              // -----

              CGRect styleViewFrame = alertView.styleView.frame;

              alertView.styleView.frame = _styleView.frame;

              alertView.styleView.hidden = NO;
              _styleView.hidden = YES;

              // -----

              if (cancelButtonNext)
              {
                  alertView.styleCancelView.hidden = NO;

                  if (!cancelButtonSelf)
                      alertView.styleCancelView.alpha = 0.f;
              }

              // -----

              if (cancelButtonSelf && cancelButtonNext)
                  _styleCancelView.hidden = YES;

              // -----

              [UIView animateWithDuration:duration
                               animations:^(void)
               {
                   alertView.styleView.frame = styleViewFrame;
               }
                               completion:^(BOOL finished)
               {
                   alertView.scrollView.alpha = 0.f;
                   alertView.scrollView.hidden = NO;

                   if (cancelButtonNext)
                   {
                       alertView.cancelButton.alpha = 0.f;
                       alertView.cancelButton.hidden = NO;
                   }

                   [UIView animateWithDuration:duration
                                    animations:^(void)
                    {
                        _scrollView.alpha = 0.f;
                        alertView.scrollView.alpha = 1.f;

                        if (cancelButtonNext)
                        {
                            alertView.cancelButton.alpha = 1.f;

                            if (!cancelButtonSelf)
                                alertView.styleCancelView.alpha = 1.f;
                        }
                    }
                                    completion:^(BOOL finished)
                    {
                        [self dismissAnimated:NO completionHandler:^(void)
                        {
                            [alertView showComplete];

                            if (completionHandler) completionHandler();
                        }];
                    }];
               }];
          }];
     }];
}

#pragma mark -

- (void)subviewsInvalidateWithSize:(CGSize)size
{
    CGFloat width = 0.f;

    if (_width > 0.f)
    {
        width = MIN(size.width, size.height);

        if (_width < width) width = _width;
    }
    else
    {
        if (_style == LGAlertViewStyleAlert)
            width = kLGAlertViewWidthStyleAlert;
        else
        {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                width = kLGAlertViewWidthStyleActionSheet;
            else
                width = MIN(size.width, size.height)-kLGAlertViewOffsetHorizontal*2;
        }
    }

    // -----

    if (!self.isExists)
    {
        _exists = YES;

        _backgroundView.backgroundColor = _coverColor;

        _styleView = [UIView new];
        _styleView.backgroundColor = _backgroundColor;
        _styleView.layer.masksToBounds = NO;
        _styleView.layer.cornerRadius = _layerCornerRadius+(_layerCornerRadius == 0.f ? 0.f : _layerBorderWidth+1.f);
        _styleView.layer.borderColor = _layerBorderColor.CGColor;
        _styleView.layer.borderWidth = _layerBorderWidth;
        _styleView.layer.shadowColor = _layerShadowColor.CGColor;
        _styleView.layer.shadowRadius = _layerShadowRadius;
        _styleView.layer.shadowOpacity = _layerShadowOpacity;
        _styleView.layer.shadowOffset = _layerShadowOffset;
        [_view addSubview:_styleView];

        _scrollView = [UIScrollView new];
        _scrollView.backgroundColor = [UIColor clearColor];
        _scrollView.indicatorStyle = _indicatorStyle;
        _scrollView.showsVerticalScrollIndicator = _showsVerticalScrollIndicator;
        _scrollView.alwaysBounceVertical = NO;
        _scrollView.layer.masksToBounds = YES;
        _scrollView.layer.cornerRadius = _layerCornerRadius;
        [_view addSubview:_scrollView];

        CGFloat offsetY = 0.f;

        if (_title.length)
        {
            _titleLabel = [UILabel new];
            _titleLabel.text = _title;
            _titleLabel.textColor = _titleTextColor;
            _titleLabel.textAlignment = _titleTextAlignment;
            _titleLabel.numberOfLines = 0;
            _titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
            _titleLabel.backgroundColor = [UIColor clearColor];
            _titleLabel.font = _titleFont;

            CGSize titleLabelSize = [_titleLabel sizeThatFits:CGSizeMake(width-kLGAlertViewPaddingW*2, CGFLOAT_MAX)];
            CGRect titleLabelFrame = CGRectMake(kLGAlertViewPaddingW, kLGAlertViewInnerMarginH, width-kLGAlertViewPaddingW*2, titleLabelSize.height);
            if ([UIScreen mainScreen].scale == 1.f)
                titleLabelFrame = CGRectIntegral(titleLabelFrame);

            _titleLabel.frame = titleLabelFrame;
            [_scrollView addSubview:_titleLabel];

            offsetY = _titleLabel.frame.origin.y+_titleLabel.frame.size.height;
        }

        if (_message.length)
        {
            _messageLabel = [UILabel new];
            _messageLabel.text = _message;
            _messageLabel.textColor = _messageTextColor;
            _messageLabel.textAlignment = _messageTextAlignment;
            _messageLabel.numberOfLines = 0;
            _messageLabel.lineBreakMode = NSLineBreakByWordWrapping;
            _messageLabel.backgroundColor = [UIColor clearColor];
            _messageLabel.font = _messageFont;

            if (!offsetY) offsetY = kLGAlertViewInnerMarginH/2;
            else if (_style == LGAlertViewStyleActionSheet) offsetY -= kLGAlertViewInnerMarginH/3;

            CGSize messageLabelSize = [_messageLabel sizeThatFits:CGSizeMake(width-kLGAlertViewPaddingW*2, CGFLOAT_MAX)];
            CGRect messageLabelFrame = CGRectMake(kLGAlertViewPaddingW, offsetY+kLGAlertViewInnerMarginH/2, width-kLGAlertViewPaddingW*2, messageLabelSize.height);
            if ([UIScreen mainScreen].scale == 1.f)
                messageLabelFrame = CGRectIntegral(messageLabelFrame);

            _messageLabel.frame = messageLabelFrame;
            [_scrollView addSubview:_messageLabel];

            offsetY = _messageLabel.frame.origin.y+_messageLabel.frame.size.height;
        }

        if (_innerView)
        {
            CGRect innerViewFrame = CGRectMake(width/2-_innerView.frame.size.width/2, offsetY+kLGAlertViewInnerMarginH, _innerView.frame.size.width, _innerView.frame.size.height);
            if ([UIScreen mainScreen].scale == 1.f)
                innerViewFrame = CGRectIntegral(innerViewFrame);

            _innerView.frame = innerViewFrame;
            [_scrollView addSubview:_innerView];

            offsetY = _innerView.frame.origin.y+_innerView.frame.size.height;
        }
        else if (_type == LGAlertViewTypeActivityIndicator)
        {
            _activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:_activityIndicatorViewStyle];
            _activityIndicator.color = _activityIndicatorViewColor;
            _activityIndicator.backgroundColor = [UIColor clearColor];
            [_activityIndicator startAnimating];

            CGRect activityIndicatorFrame = CGRectMake(width/2-_activityIndicator.frame.size.width/2, offsetY+kLGAlertViewInnerMarginH, _activityIndicator.frame.size.width, _activityIndicator.frame.size.height);
            if ([UIScreen mainScreen].scale == 1.f)
                activityIndicatorFrame = CGRectIntegral(activityIndicatorFrame);

            _activityIndicator.frame = activityIndicatorFrame;
            [_scrollView addSubview:_activityIndicator];

            offsetY = _activityIndicator.frame.origin.y+_activityIndicator.frame.size.height;
        }
        else if (_type == LGAlertViewTypeProgressView)
        {
            _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
            _progressView.backgroundColor = [UIColor clearColor];
            _progressView.progressTintColor = _progressViewProgressTintColor;
            _progressView.trackTintColor = _progressViewTrackTintColor;
            if (_progressViewProgressImage)
                _progressView.progressImage = _progressViewProgressImage;
            if (_progressViewTrackImage)
                _progressView.trackImage = _progressViewTrackImage;

            CGRect progressViewFrame = CGRectMake(kLGAlertViewPaddingW, offsetY+kLGAlertViewInnerMarginH, width-kLGAlertViewPaddingW*2, _progressView.frame.size.height);
            if ([UIScreen mainScreen].scale == 1.f)
                progressViewFrame = CGRectIntegral(progressViewFrame);

            _progressView.frame = progressViewFrame;
            [_scrollView addSubview:_progressView];

            offsetY = _progressView.frame.origin.y+_progressView.frame.size.height;

            _progressLabel = [UILabel new];
            _progressLabel.text = _progressLabelText;
            _progressLabel.textColor = _progressLabelTextColor;
            _progressLabel.textAlignment = _progressLabelTextAlignment;
            _progressLabel.numberOfLines = 1;
            _progressLabel.backgroundColor = [UIColor clearColor];
            _progressLabel.font = _progressLabelFont;

            CGSize progressLabelSize = [_progressLabel sizeThatFits:CGSizeMake(width-kLGAlertViewPaddingW*2, CGFLOAT_MAX)];
            CGRect progressLabelFrame = CGRectMake(kLGAlertViewPaddingW, offsetY+kLGAlertViewInnerMarginH/2, width-kLGAlertViewPaddingW*2, progressLabelSize.height);
            if ([UIScreen mainScreen].scale == 1.f)
                progressLabelFrame = CGRectIntegral(progressLabelFrame);

            _progressLabel.frame = progressLabelFrame;
            [_scrollView addSubview:_progressLabel];

            offsetY = _progressLabel.frame.origin.y+_progressLabel.frame.size.height;
        }
        else if (_type == LGAlertViewTypeTextFields)
        {
            for (NSUInteger i=0; i<_textFieldsArray.count; i++)
            {
                UIView *separatorView = _textFieldSeparatorsArray[i];
                separatorView.backgroundColor = _separatorsColor;

                CGRect separatorViewFrame = CGRectMake(0.f, offsetY+(i == 0 ? kLGAlertViewInnerMarginH : 0.f), width, kLGAlertViewSeparatorHeight);
                if ([UIScreen mainScreen].scale == 1.f)
                    separatorViewFrame = CGRectIntegral(separatorViewFrame);

                separatorView.frame = separatorViewFrame;
                [_scrollView addSubview:separatorView];

                offsetY = separatorView.frame.origin.y+separatorView.frame.size.height;

                // -----

                LGAlertViewTextField *textField = _textFieldsArray[i];

                CGRect textFieldFrame = CGRectMake(0.f, offsetY, width, _textFieldsHeight);
                if ([UIScreen mainScreen].scale == 1.f)
                    textFieldFrame = CGRectIntegral(textFieldFrame);

                textField.frame = textFieldFrame;
                [_scrollView addSubview:textField];

                offsetY = textField.frame.origin.y+textField.frame.size.height;
            }

            offsetY -= kLGAlertViewInnerMarginH;
        }

        // -----

        if (kLGAlertViewIsCancelButtonSeparate(self) && _cancelButtonTitle)
        {
            _styleCancelView = [UIView new];
            _styleCancelView.backgroundColor = _backgroundColor;
            _styleCancelView.layer.masksToBounds = NO;
            _styleCancelView.layer.cornerRadius = _layerCornerRadius+(_layerCornerRadius == 0.f ? 0.f : _layerBorderWidth+1.f);;
            _styleCancelView.layer.borderColor = _layerBorderColor.CGColor;
            _styleCancelView.layer.borderWidth = _layerBorderWidth;
            _styleCancelView.layer.shadowColor = _layerShadowColor.CGColor;
            _styleCancelView.layer.shadowRadius = _layerShadowRadius;
            _styleCancelView.layer.shadowOpacity = _layerShadowOpacity;
            _styleCancelView.layer.shadowOffset = _layerShadowOffset;
            [_view insertSubview:_styleCancelView belowSubview:_scrollView];

            [self cancelButtonInit];
            _cancelButton.layer.masksToBounds = YES;
            _cancelButton.layer.cornerRadius = _layerCornerRadius;
            [_view insertSubview:_cancelButton aboveSubview:_styleCancelView];
        }

        // -----

        NSUInteger numberOfButtons = _buttonTitles.count;

        if (_destructiveButtonTitle.length)
            numberOfButtons++;
        if (_cancelButtonTitle.length && !kLGAlertViewIsCancelButtonSeparate(self))
            numberOfButtons++;

        BOOL showTable = NO;

        if (numberOfButtons)
        {
            if (!self.isOneRowOneButton &&
                ((_style == LGAlertViewStyleAlert && numberOfButtons < 4) ||
                 (_style == LGAlertViewStyleActionSheet && numberOfButtons == 1)))
            {
                CGFloat buttonWidth = width/numberOfButtons;
                if (buttonWidth < kLGAlertViewButtonWidthMin)
                    showTable = YES;

                if (_destructiveButtonTitle.length && !showTable)
                {
                    _destructiveButton = [UIButton new];
                    _destructiveButton.backgroundColor = [UIColor clearColor];
                    _destructiveButton.titleLabel.numberOfLines = _destructiveButtonNumberOfLines;
                    _destructiveButton.titleLabel.lineBreakMode = _destructiveButtonLineBreakMode;
                    _destructiveButton.titleLabel.adjustsFontSizeToFitWidth = _destructiveButtonAdjustsFontSizeToFitWidth;
                    _destructiveButton.titleLabel.minimumScaleFactor = _destructiveButtonMinimumScaleFactor;
                    _destructiveButton.titleLabel.font = _destructiveButtonFont;
                    [_destructiveButton setTitle:_destructiveButtonTitle forState:UIControlStateNormal];
                    [_destructiveButton setTitleColor:_destructiveButtonTitleColor forState:UIControlStateNormal];
                    [_destructiveButton setTitleColor:_destructiveButtonTitleColorHighlighted forState:UIControlStateHighlighted];
                    [_destructiveButton setTitleColor:_destructiveButtonTitleColorHighlighted forState:UIControlStateSelected];
                    [_destructiveButton setTitleColor:_destructiveButtonTitleColorDisabled forState:UIControlStateDisabled];
                    [_destructiveButton setBackgroundImage:[LGAlertView image1x1WithColor:_destructiveButtonBackgroundColor] forState:UIControlStateNormal];
                    [_destructiveButton setBackgroundImage:[LGAlertView image1x1WithColor:_destructiveButtonBackgroundColorHighlighted] forState:UIControlStateHighlighted];
                    [_destructiveButton setBackgroundImage:[LGAlertView image1x1WithColor:_destructiveButtonBackgroundColorHighlighted] forState:UIControlStateSelected];
                    [_destructiveButton setBackgroundImage:[LGAlertView image1x1WithColor:_destructiveButtonBackgroundColorDisabled] forState:UIControlStateDisabled];
                    _destructiveButton.contentEdgeInsets = UIEdgeInsetsMake(kLGAlertViewButtonTitleMarginH, kLGAlertViewPaddingW, kLGAlertViewButtonTitleMarginH, kLGAlertViewPaddingW);
                    _destructiveButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
                    if (_destructiveButtonTextAlignment == NSTextAlignmentCenter)
                        _destructiveButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
                    else if (_destructiveButtonTextAlignment == NSTextAlignmentLeft)
                        _destructiveButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
                    else if (_destructiveButtonTextAlignment == NSTextAlignmentRight)
                        _destructiveButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
                    _destructiveButton.enabled = _destructiveButtonEnabled;
                    [_destructiveButton addTarget:self action:@selector(destructiveAction:) forControlEvents:UIControlEventTouchUpInside];

                    CGSize size = [_destructiveButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];

                    if (size.width > buttonWidth)
                        showTable = YES;
                }

                if (_cancelButtonTitle.length && !kLGAlertViewIsCancelButtonSeparate(self) && !showTable)
                {
                    [self cancelButtonInit];

                    CGSize size = [_cancelButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];

                    if (size.width > buttonWidth)
                        showTable = YES;
                }

                if (_buttonTitles.count > 0 && !showTable)
                {
                    LGAlertViewButtonProperties *properties = nil;
                    if (_buttonsPropertiesDictionary)
                        properties = _buttonsPropertiesDictionary[[NSNumber numberWithInteger:0]];

                    _firstButton = [UIButton new];
                    _firstButton.backgroundColor = [UIColor clearColor];
                    _firstButton.titleLabel.numberOfLines = (properties.isUserNumberOfLines ? properties.numberOfLines : _buttonsNumberOfLines);
                    _firstButton.titleLabel.lineBreakMode = (properties.isUserLineBreakMode ? properties.lineBreakMode : _buttonsLineBreakMode);
                    _firstButton.titleLabel.adjustsFontSizeToFitWidth = (properties.isAdjustsFontSizeToFitWidth ? properties.adjustsFontSizeToFitWidth : _buttonsAdjustsFontSizeToFitWidth);
                    _firstButton.titleLabel.minimumScaleFactor = (properties.isUserMinimimScaleFactor ? properties.minimumScaleFactor : _buttonsMinimumScaleFactor);
                    _firstButton.titleLabel.font = (properties.isUserFont ? properties.font : _buttonsFont);
                    [_firstButton setTitle:_buttonTitles[0] forState:UIControlStateNormal];
                    [_firstButton setTitleColor:(properties.isUserTitleColor ? properties.titleColor : _buttonsTitleColor) forState:UIControlStateNormal];
                    [_firstButton setTitleColor:(properties.isUserTitleColorHighlighted ? properties.titleColorHighlighted : _buttonsTitleColorHighlighted) forState:UIControlStateHighlighted];
                    [_firstButton setTitleColor:(properties.isUserTitleColorHighlighted ? properties.titleColorHighlighted : _buttonsTitleColorHighlighted) forState:UIControlStateSelected];
                    [_firstButton setTitleColor:(properties.isUserTitleColorDisabled ? properties.titleColorDisabled : _buttonsTitleColorDisabled) forState:UIControlStateDisabled];
                    [_firstButton setBackgroundImage:[LGAlertView image1x1WithColor:(properties.isUserBackgroundColor ? properties.backgroundColor : _buttonsBackgroundColor)] forState:UIControlStateNormal];
                    [_firstButton setBackgroundImage:[LGAlertView image1x1WithColor:(properties.isUserBackgroundColorHighlighted ? properties.backgroundColorHighlighted : _buttonsBackgroundColorHighlighted)] forState:UIControlStateHighlighted];
                    [_firstButton setBackgroundImage:[LGAlertView image1x1WithColor:(properties.isUserBackgroundColorHighlighted ? properties.backgroundColorHighlighted : _buttonsBackgroundColorHighlighted)] forState:UIControlStateSelected];
                    [_firstButton setBackgroundImage:[LGAlertView image1x1WithColor:(properties.isUserBackgroundColorDisabled ? properties.backgroundColorDisabled : _buttonsBackgroundColorDisabled)] forState:UIControlStateDisabled];
                    _firstButton.contentEdgeInsets = UIEdgeInsetsMake(kLGAlertViewButtonTitleMarginH, kLGAlertViewPaddingW, kLGAlertViewButtonTitleMarginH, kLGAlertViewPaddingW);
                    _firstButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
                    NSTextAlignment textAlignment = (properties.isUserTextAlignment ? properties.textAlignment : _buttonsTextAlignment);
                    if (textAlignment == NSTextAlignmentCenter)
                        _firstButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
                    else if (textAlignment == NSTextAlignmentLeft)
                        _firstButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
                    else if (textAlignment == NSTextAlignmentRight)
                        _firstButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
                    _firstButton.enabled = [_buttonsEnabledArray[0] boolValue];
                    [_firstButton addTarget:self action:@selector(firstButtonAction:) forControlEvents:UIControlEventTouchUpInside];

                    CGSize size = [_firstButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];

                    if (size.width > buttonWidth)
                        showTable = YES;

                    if (_buttonTitles.count > 1 && !showTable)
                    {
                        LGAlertViewButtonProperties *properties = nil;
                        if (_buttonsPropertiesDictionary)
                            properties = _buttonsPropertiesDictionary[[NSNumber numberWithInteger:1]];

                        _secondButton = [UIButton new];
                        _secondButton.backgroundColor = [UIColor clearColor];
                        _secondButton.titleLabel.numberOfLines = (properties.isUserNumberOfLines ? properties.numberOfLines : _buttonsNumberOfLines);
                        _secondButton.titleLabel.lineBreakMode = (properties.isUserLineBreakMode ? properties.lineBreakMode : _buttonsLineBreakMode);
                        _secondButton.titleLabel.adjustsFontSizeToFitWidth = (properties.isAdjustsFontSizeToFitWidth ? properties.adjustsFontSizeToFitWidth : _buttonsAdjustsFontSizeToFitWidth);
                        _secondButton.titleLabel.minimumScaleFactor = (properties.isUserMinimimScaleFactor ? properties.minimumScaleFactor : _buttonsMinimumScaleFactor);
                        _secondButton.titleLabel.font = (properties.isUserFont ? properties.font : _buttonsFont);
                        [_secondButton setTitle:_buttonTitles[1] forState:UIControlStateNormal];
                        [_secondButton setTitleColor:(properties.isUserTitleColor ? properties.titleColor : _buttonsTitleColor) forState:UIControlStateNormal];
                        [_secondButton setTitleColor:(properties.isUserTitleColorHighlighted ? properties.titleColorHighlighted : _buttonsTitleColorHighlighted) forState:UIControlStateHighlighted];
                        [_secondButton setTitleColor:(properties.isUserTitleColorHighlighted ? properties.titleColorHighlighted : _buttonsTitleColorHighlighted) forState:UIControlStateSelected];
                        [_secondButton setTitleColor:(properties.isUserTitleColorDisabled ? properties.titleColorDisabled : _buttonsTitleColorDisabled) forState:UIControlStateDisabled];
                        [_secondButton setBackgroundImage:[LGAlertView image1x1WithColor:(properties.isUserBackgroundColor ? properties.backgroundColor : _buttonsBackgroundColor)] forState:UIControlStateNormal];
                        [_secondButton setBackgroundImage:[LGAlertView image1x1WithColor:(properties.isUserBackgroundColorHighlighted ? properties.backgroundColorHighlighted : _buttonsBackgroundColorHighlighted)] forState:UIControlStateHighlighted];
                        [_secondButton setBackgroundImage:[LGAlertView image1x1WithColor:(properties.isUserBackgroundColorHighlighted ? properties.backgroundColorHighlighted : _buttonsBackgroundColorHighlighted)] forState:UIControlStateSelected];
                        [_secondButton setBackgroundImage:[LGAlertView image1x1WithColor:(properties.isUserBackgroundColorDisabled ? properties.backgroundColorDisabled : _buttonsBackgroundColorDisabled)] forState:UIControlStateDisabled];
                        _secondButton.contentEdgeInsets = UIEdgeInsetsMake(kLGAlertViewButtonTitleMarginH, kLGAlertViewPaddingW, kLGAlertViewButtonTitleMarginH, kLGAlertViewPaddingW);
                        _secondButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
                        NSTextAlignment textAlignment = (properties.isUserTextAlignment ? properties.textAlignment : _buttonsTextAlignment);
                        if (textAlignment == NSTextAlignmentCenter)
                            _secondButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
                        else if (textAlignment == NSTextAlignmentLeft)
                            _secondButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
                        else if (textAlignment == NSTextAlignmentRight)
                            _secondButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
                        _secondButton.enabled = [_buttonsEnabledArray[1] boolValue];
                        [_secondButton addTarget:self action:@selector(secondButtonAction:) forControlEvents:UIControlEventTouchUpInside];

                        CGSize size = [_secondButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];

                        if (size.width > buttonWidth)
                            showTable = YES;

                        if (_buttonTitles.count > 2 && !showTable)
                        {
                            LGAlertViewButtonProperties *properties = nil;
                            if (_buttonsPropertiesDictionary)
                                properties = _buttonsPropertiesDictionary[[NSNumber numberWithInteger:2]];

                            _thirdButton = [UIButton new];
                            _thirdButton.backgroundColor = [UIColor clearColor];
                            _thirdButton.titleLabel.numberOfLines = (properties.isUserNumberOfLines ? properties.numberOfLines : _buttonsNumberOfLines);
                            _thirdButton.titleLabel.lineBreakMode = (properties.isUserLineBreakMode ? properties.lineBreakMode : _buttonsLineBreakMode);
                            _thirdButton.titleLabel.adjustsFontSizeToFitWidth = (properties.isAdjustsFontSizeToFitWidth ? properties.adjustsFontSizeToFitWidth : _buttonsAdjustsFontSizeToFitWidth);
                            _thirdButton.titleLabel.minimumScaleFactor = (properties.isUserMinimimScaleFactor ? properties.minimumScaleFactor : _buttonsMinimumScaleFactor);
                            _thirdButton.titleLabel.font = (properties.isUserFont ? properties.font : _buttonsFont);
                            [_thirdButton setTitle:_buttonTitles[2] forState:UIControlStateNormal];
                            [_thirdButton setTitleColor:(properties.isUserTitleColor ? properties.titleColor : _buttonsTitleColor) forState:UIControlStateNormal];
                            [_thirdButton setTitleColor:(properties.isUserTitleColorHighlighted ? properties.titleColorHighlighted : _buttonsTitleColorHighlighted) forState:UIControlStateHighlighted];
                            [_thirdButton setTitleColor:(properties.isUserTitleColorHighlighted ? properties.titleColorHighlighted : _buttonsTitleColorHighlighted) forState:UIControlStateSelected];
                            [_thirdButton setTitleColor:(properties.isUserTitleColorDisabled ? properties.titleColorDisabled : _buttonsTitleColorDisabled) forState:UIControlStateDisabled];
                            [_thirdButton setBackgroundImage:[LGAlertView image1x1WithColor:(properties.isUserBackgroundColor ? properties.backgroundColor : _buttonsBackgroundColor)] forState:UIControlStateNormal];
                            [_thirdButton setBackgroundImage:[LGAlertView image1x1WithColor:(properties.isUserBackgroundColorHighlighted ? properties.backgroundColorHighlighted : _buttonsBackgroundColorHighlighted)] forState:UIControlStateHighlighted];
                            [_thirdButton setBackgroundImage:[LGAlertView image1x1WithColor:(properties.isUserBackgroundColorHighlighted ? properties.backgroundColorHighlighted : _buttonsBackgroundColorHighlighted)] forState:UIControlStateSelected];
                            [_thirdButton setBackgroundImage:[LGAlertView image1x1WithColor:(properties.isUserBackgroundColorDisabled ? properties.backgroundColorDisabled : _buttonsBackgroundColorDisabled)] forState:UIControlStateDisabled];
                            _thirdButton.contentEdgeInsets = UIEdgeInsetsMake(kLGAlertViewButtonTitleMarginH, kLGAlertViewPaddingW, kLGAlertViewButtonTitleMarginH, kLGAlertViewPaddingW);
                            _thirdButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
                            NSTextAlignment textAlignment = (properties.isUserTextAlignment ? properties.textAlignment : _buttonsTextAlignment);
                            if (textAlignment == NSTextAlignmentCenter)
                                _thirdButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
                            else if (textAlignment == NSTextAlignmentLeft)
                                _thirdButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
                            else if (textAlignment == NSTextAlignmentRight)
                                _thirdButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
                            _thirdButton.enabled = [_buttonsEnabledArray[2] boolValue];
                            [_thirdButton addTarget:self action:@selector(thirdButtonAction:) forControlEvents:UIControlEventTouchUpInside];

                            CGSize size = [_thirdButton sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];

                            if (size.width > buttonWidth)
                                showTable = YES;
                        }
                    }
                }

                if (!showTable)
                {
                    UIButton *firstButton = nil;
                    UIButton *secondButton = nil;
                    UIButton *thirdButton = nil;

                    if (_cancelButton && !kLGAlertViewIsCancelButtonSeparate(self))
                    {
                        [_scrollView addSubview:_cancelButton];

                        firstButton = _cancelButton;
                    }

                    if (_destructiveButton)
                    {
                        [_scrollView addSubview:_destructiveButton];

                        if (!firstButton) firstButton = _destructiveButton;
                        else secondButton = _destructiveButton;
                    }

                    if (_firstButton)
                    {
                        [_scrollView addSubview:_firstButton];

                        if (!firstButton) firstButton = _firstButton;
                        else if (!secondButton) secondButton = _firstButton;
                        else thirdButton = _firstButton;

                        if (_secondButton)
                        {
                            [_scrollView addSubview:_secondButton];

                            if (!secondButton) secondButton = _secondButton;
                            else thirdButton = _secondButton;

                            if (_thirdButton)
                            {
                                [_scrollView addSubview:_thirdButton];

                                thirdButton = _thirdButton;
                            }
                        }
                    }

                    // -----

                    if (offsetY)
                    {
                        _separatorHorizontalView = [UIView new];
                        _separatorHorizontalView.backgroundColor = _separatorsColor;

                        CGRect separatorHorizontalViewFrame = CGRectMake(0.f, offsetY+kLGAlertViewInnerMarginH, width, kLGAlertViewSeparatorHeight);
                        if ([UIScreen mainScreen].scale == 1.f)
                            separatorHorizontalViewFrame = CGRectIntegral(separatorHorizontalViewFrame);

                        _separatorHorizontalView.frame = separatorHorizontalViewFrame;
                        [_scrollView addSubview:_separatorHorizontalView];

                        offsetY = _separatorHorizontalView.frame.origin.y+_separatorHorizontalView.frame.size.height;
                    }

                    // -----

                    CGRect firstButtonFrame = CGRectMake(0.f, offsetY, width/numberOfButtons, _buttonsHeight);
                    if ([UIScreen mainScreen].scale == 1.f)
                        firstButtonFrame = CGRectIntegral(firstButtonFrame);
                    firstButton.frame = firstButtonFrame;

                    CGRect secondButtonFrame = CGRectZero;
                    CGRect thirdButtonFrame = CGRectZero;
                    if (secondButton)
                    {
                        secondButtonFrame = CGRectMake(firstButtonFrame.origin.x+firstButtonFrame.size.width+kLGAlertViewSeparatorHeight, offsetY, width/numberOfButtons-kLGAlertViewSeparatorHeight, _buttonsHeight);
                        if ([UIScreen mainScreen].scale == 1.f)
                            secondButtonFrame = CGRectIntegral(secondButtonFrame);
                        secondButton.frame = secondButtonFrame;

                        if (thirdButton)
                        {
                            thirdButtonFrame = CGRectMake(secondButtonFrame.origin.x+secondButtonFrame.size.width+kLGAlertViewSeparatorHeight, offsetY, width/numberOfButtons-kLGAlertViewSeparatorHeight, _buttonsHeight);
                            if ([UIScreen mainScreen].scale == 1.f)
                                thirdButtonFrame = CGRectIntegral(thirdButtonFrame);
                            thirdButton.frame = thirdButtonFrame;
                        }
                    }

                    // -----

                    if (secondButton)
                    {
                        _separatorVerticalView1 = [UIView new];
                        _separatorVerticalView1.backgroundColor = _separatorsColor;

                        CGRect separatorVerticalView1Frame = CGRectMake(firstButtonFrame.origin.x+firstButtonFrame.size.width, offsetY, kLGAlertViewSeparatorHeight, MAX(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height));
                        if ([UIScreen mainScreen].scale == 1.f)
                            separatorVerticalView1Frame = CGRectIntegral(separatorVerticalView1Frame);

                        _separatorVerticalView1.frame = separatorVerticalView1Frame;
                        [_scrollView addSubview:_separatorVerticalView1];

                        if (thirdButton)
                        {
                            _separatorVerticalView2 = [UIView new];
                            _separatorVerticalView2.backgroundColor = _separatorsColor;

                            CGRect separatorVerticalView2Frame = CGRectMake(secondButtonFrame.origin.x+secondButtonFrame.size.width, offsetY, kLGAlertViewSeparatorHeight, MAX(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height));
                            if ([UIScreen mainScreen].scale == 1.f)
                                separatorVerticalView2Frame = CGRectIntegral(separatorVerticalView2Frame);

                            _separatorVerticalView2.frame = separatorVerticalView2Frame;
                            [_scrollView addSubview:_separatorVerticalView2];
                        }
                    }

                    // -----

                    offsetY += _buttonsHeight;
                }
            }
            else showTable = YES;

            if (showTable)
            {
                if (!kLGAlertViewIsCancelButtonSeparate(self))
                    _cancelButton = nil;
                _destructiveButton = nil;
                _firstButton = nil;
                _secondButton = nil;
                _thirdButton = nil;

                if (!_buttonTitles)
                    _buttonTitles = [NSMutableArray new];

                if (_destructiveButtonTitle.length)
                    [_buttonTitles insertObject:_destructiveButtonTitle atIndex:0];

                if (_cancelButtonTitle.length && !kLGAlertViewIsCancelButtonSeparate(self))
                    [_buttonTitles addObject:_cancelButtonTitle];

                _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
                _tableView.clipsToBounds = NO;
                _tableView.backgroundColor = [UIColor clearColor];
                _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
                _tableView.dataSource = self;
                _tableView.delegate = self;
                _tableView.scrollEnabled = NO;
                [_tableView registerClass:[LGAlertViewCell class] forCellReuseIdentifier:@"cell"];
                _tableView.frame = CGRectMake(0.f, 0.f, width, CGFLOAT_MAX);
                [_tableView reloadData];

                if (!offsetY) offsetY = -kLGAlertViewInnerMarginH;
                else
                {
                    _separatorHorizontalView = [UIView new];
                    _separatorHorizontalView.backgroundColor = _separatorsColor;

                    CGRect separatorTitleViewFrame = CGRectMake(0.f, 0.f, width, kLGAlertViewSeparatorHeight);
                    if ([UIScreen mainScreen].scale == 1.f)
                        separatorTitleViewFrame = CGRectIntegral(separatorTitleViewFrame);

                    _separatorHorizontalView.frame = separatorTitleViewFrame;
                    _tableView.tableHeaderView = _separatorHorizontalView;
                }

                CGRect tableViewFrame = CGRectMake(0.f, offsetY+kLGAlertViewInnerMarginH, width, _tableView.contentSize.height);
                if ([UIScreen mainScreen].scale == 1.f)
                    tableViewFrame = CGRectIntegral(tableViewFrame);
                _tableView.frame = tableViewFrame;

                [_scrollView addSubview:_tableView];

                offsetY = _tableView.frame.origin.y+_tableView.frame.size.height;
            }
        }
        else offsetY += kLGAlertViewInnerMarginH;

        // -----

        _scrollView.contentSize = CGSizeMake(width, offsetY);
    }
}

- (void)layoutInvalidateWithSize:(CGSize)size
{
    _view.frame = CGRectMake(0.f, 0.f, size.width, size.height);

    _backgroundView.frame = CGRectMake(0.f, 0.f, size.width, size.height);

    // -----

    CGFloat width = 0.f;

    if (_width > 0.f)
    {
        width = MIN(size.width, size.height);

        if (_width < width) width = _width;
    }
    else
    {
        if (_style == LGAlertViewStyleAlert)
            width = kLGAlertViewWidthStyleAlert;
        else
        {
            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
                width = kLGAlertViewWidthStyleActionSheet;
            else
                width = MIN(size.width, size.height)-kLGAlertViewOffsetHorizontal*2;
        }
    }

    // -----

    CGFloat heightMax = size.height-_keyboardHeight-kLGAlertViewOffsetVertical*2;

    if (_windowLevel == LGAlertViewWindowLevelBelowStatusBar)
        heightMax -= kLGAlertViewStatusBarHeight;

    if (_heightMax > 0.f && _heightMax < heightMax)
        heightMax = _heightMax;

    if (kLGAlertViewIsCancelButtonSeparate(self) && _cancelButton)
        heightMax -= (_buttonsHeight+_cancelButtonOffsetY);
    else if (_cancelOnTouch &&
             !_cancelButtonTitle.length &&
             size.width < width+_buttonsHeight*2)
        heightMax -= _buttonsHeight*2;

    if (_scrollView.contentSize.height < heightMax)
        heightMax = _scrollView.contentSize.height;

    // -----

    CGRect scrollViewFrame = CGRectZero;
    CGAffineTransform scrollViewTransform = CGAffineTransformIdentity;
    CGFloat scrollViewAlpha = 1.f;

    if (_style == LGAlertViewStyleAlert || kLGAlertViewPadAndNotForce(self))
    {
        scrollViewFrame = CGRectMake(size.width/2-width/2, size.height/2-_keyboardHeight/2-heightMax/2, width, heightMax);

        if (_windowLevel == LGAlertViewWindowLevelBelowStatusBar)
            scrollViewFrame.origin.y += kLGAlertViewStatusBarHeight/2;

        if (!self.isShowing)
        {
            scrollViewTransform = CGAffineTransformMakeScale(1.2, 1.2);

            scrollViewAlpha = 0.f;
        }
    }
    else
    {
        CGFloat bottomShift = kLGAlertViewOffsetVertical;
        if (kLGAlertViewIsCancelButtonSeparate(self) && _cancelButton)
            bottomShift += _buttonsHeight+_cancelButtonOffsetY;

        scrollViewFrame = CGRectMake(size.width/2-width/2, size.height-bottomShift-heightMax, width, heightMax);
    }

    // -----

    if (_style == LGAlertViewStyleActionSheet && !kLGAlertViewPadAndNotForce(self))
    {
        CGRect cancelButtonFrame = CGRectZero;
        if (kLGAlertViewIsCancelButtonSeparate(self) && _cancelButton)
            cancelButtonFrame = CGRectMake(size.width/2-width/2, size.height-_cancelButtonOffsetY-_buttonsHeight, width, _buttonsHeight);

        _scrollViewCenterShowed = CGPointMake(scrollViewFrame.origin.x+scrollViewFrame.size.width/2, scrollViewFrame.origin.y+scrollViewFrame.size.height/2);
        _cancelButtonCenterShowed = CGPointMake(cancelButtonFrame.origin.x+cancelButtonFrame.size.width/2, cancelButtonFrame.origin.y+cancelButtonFrame.size.height/2);

        // -----

        CGFloat commonHeight = scrollViewFrame.size.height+kLGAlertViewOffsetVertical;
        if (kLGAlertViewIsCancelButtonSeparate(self) && _cancelButton)
            commonHeight += _buttonsHeight+_cancelButtonOffsetY;

        _scrollViewCenterHidden = CGPointMake(scrollViewFrame.origin.x+scrollViewFrame.size.width/2, scrollViewFrame.origin.y+scrollViewFrame.size.height/2+commonHeight+_layerBorderWidth+_layerShadowRadius);
        _cancelButtonCenterHidden = CGPointMake(cancelButtonFrame.origin.x+cancelButtonFrame.size.width/2, cancelButtonFrame.origin.y+cancelButtonFrame.size.height/2+commonHeight);

        if (!self.isShowing)
        {
            scrollViewFrame.origin.y += commonHeight;

            if (kLGAlertViewIsCancelButtonSeparate(self) && _cancelButton)
                cancelButtonFrame.origin.y += commonHeight;
        }

        // -----

        if (kLGAlertViewIsCancelButtonSeparate(self) && _cancelButton)
        {
            if ([UIScreen mainScreen].scale == 1.f)
                cancelButtonFrame = CGRectIntegral(cancelButtonFrame);

            _cancelButton.frame = cancelButtonFrame;

            CGFloat borderWidth = _layerBorderWidth;
            _styleCancelView.frame = CGRectMake(cancelButtonFrame.origin.x-borderWidth, cancelButtonFrame.origin.y-borderWidth, cancelButtonFrame.size.width+borderWidth*2, cancelButtonFrame.size.height+borderWidth*2);
        }
    }

    // -----

    if ([UIScreen mainScreen].scale == 1.f)
    {
        scrollViewFrame = CGRectIntegral(scrollViewFrame);

        if (scrollViewFrame.size.height - _scrollView.contentSize.height == 1.f)
            scrollViewFrame.size.height -= 2.f;
    }

    // -----

    _scrollView.frame = scrollViewFrame;
    _scrollView.transform = scrollViewTransform;
    _scrollView.alpha = scrollViewAlpha;

    CGFloat borderWidth = _layerBorderWidth;
    _styleView.frame = CGRectMake(scrollViewFrame.origin.x-borderWidth, scrollViewFrame.origin.y-borderWidth, scrollViewFrame.size.width+borderWidth*2, scrollViewFrame.size.height+borderWidth*2);
    _styleView.transform = scrollViewTransform;
    _styleView.alpha = scrollViewAlpha;
}

- (void)cancelButtonInit
{
    _cancelButton = [UIButton new];
    _cancelButton.backgroundColor = [UIColor clearColor];
    _cancelButton.titleLabel.numberOfLines = _cancelButtonNumberOfLines;
    _cancelButton.titleLabel.lineBreakMode = _cancelButtonLineBreakMode;
    _cancelButton.titleLabel.adjustsFontSizeToFitWidth = _cancelButtonAdjustsFontSizeToFitWidth;
    _cancelButton.titleLabel.minimumScaleFactor = _cancelButtonMinimumScaleFactor;
    _cancelButton.titleLabel.font = _cancelButtonFont;
    [_cancelButton setTitle:_cancelButtonTitle forState:UIControlStateNormal];
    [_cancelButton setTitleColor:_cancelButtonTitleColor forState:UIControlStateNormal];
    [_cancelButton setTitleColor:_cancelButtonTitleColorHighlighted forState:UIControlStateHighlighted];
    [_cancelButton setTitleColor:_cancelButtonTitleColorHighlighted forState:UIControlStateSelected];
    [_cancelButton setTitleColor:_cancelButtonTitleColorDisabled forState:UIControlStateDisabled];
    [_cancelButton setBackgroundImage:[LGAlertView image1x1WithColor:_cancelButtonBackgroundColor] forState:UIControlStateNormal];
    [_cancelButton setBackgroundImage:[LGAlertView image1x1WithColor:_cancelButtonBackgroundColorHighlighted] forState:UIControlStateHighlighted];
    [_cancelButton setBackgroundImage:[LGAlertView image1x1WithColor:_cancelButtonBackgroundColorHighlighted] forState:UIControlStateSelected];
    [_cancelButton setBackgroundImage:[LGAlertView image1x1WithColor:_cancelButtonBackgroundColorDisabled] forState:UIControlStateDisabled];
    _cancelButton.contentEdgeInsets = UIEdgeInsetsMake(kLGAlertViewButtonTitleMarginH, kLGAlertViewPaddingW, kLGAlertViewButtonTitleMarginH, kLGAlertViewPaddingW);
    _cancelButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    if (_cancelButtonTextAlignment == NSTextAlignmentCenter)
        _cancelButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    else if (_cancelButtonTextAlignment == NSTextAlignmentLeft)
        _cancelButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    else if (_cancelButtonTextAlignment == NSTextAlignmentRight)
        _cancelButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    _cancelButton.enabled = _cancelButtonEnabled;
    [_cancelButton addTarget:self action:@selector(cancelAction:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark -

- (void)cancelAction:(id)sender
{
    if (sender && [sender isKindOfClass:[UIButton class]])
        [(UIButton *)sender setSelected:YES];

    // -----

    if (_cancelHandler) _cancelHandler(self);

    if (_delegate && [_delegate respondsToSelector:@selector(alertViewCancelled:)])
        [_delegate alertViewCancelled:self];

    [[NSNotificationCenter defaultCenter] postNotificationName:kLGAlertViewCancelNotification object:self userInfo:nil];

    // -----

    [self dismissAnimated:YES completionHandler:nil];
}

- (void)destructiveAction:(id)sender
{
    if (sender && [sender isKindOfClass:[UIButton class]])
        [(UIButton *)sender setSelected:YES];

    // -----

    if (_destructiveHandler) _destructiveHandler(self);

    if (_delegate && [_delegate respondsToSelector:@selector(alertViewDestructiveButtonPressed:)])
        [_delegate alertViewDestructiveButtonPressed:self];

    [[NSNotificationCenter defaultCenter] postNotificationName:kLGAlertViewDestructiveNotification object:self userInfo:nil];

    // -----

    [self dismissAnimated:YES completionHandler:nil];
}

- (void)actionActionAtIndex:(NSUInteger)index title:(NSString *)title
{
    if (_actionHandler) _actionHandler(self, title, index);

    if (_delegate && [_delegate respondsToSelector:@selector(alertView:buttonPressedWithTitle:index:)])
        [_delegate alertView:self buttonPressedWithTitle:title index:index];

    [[NSNotificationCenter defaultCenter] postNotificationName:kLGAlertViewActionNotification
                                                        object:self
                                                      userInfo:@{@"title" : title,
                                                                 @"index" : [NSNumber numberWithInteger:index]}];

    // -----

    [self dismissAnimated:YES completionHandler:nil];
}

- (void)firstButtonAction:(id)sender
{
    if (sender && [sender isKindOfClass:[UIButton class]])
        [(UIButton *)sender setSelected:YES];
    
    // -----
    
    NSUInteger index = 0;
    
    NSString *title = _buttonTitles[0];
    
    // -----
    
    [self actionActionAtIndex:index title:title];
}

- (void)secondButtonAction:(id)sender
{
    if (sender && [sender isKindOfClass:[UIButton class]])
        [(UIButton *)sender setSelected:YES];
    
    // -----
    
    NSUInteger index = 1;
    
    NSString *title = _buttonTitles[1];
    
    // -----
    
    [self actionActionAtIndex:index title:title];
}

- (void)thirdButtonAction:(id)sender
{
    if (sender && [sender isKindOfClass:[UIButton class]])
        [(UIButton *)sender setSelected:YES];
    
    // -----
    
    NSUInteger index = 2;
    
    NSString *title = _buttonTitles[2];
    
    // -----
    
    [self actionActionAtIndex:index title:title];
}

#pragma mark - Support

+ (void)animateStandardWithAnimations:(void(^)())animations completion:(void(^)(BOOL finished))completion
{
    if ([UIDevice currentDevice].systemVersion.floatValue >= 7.0)
    {
        [UIView animateWithDuration:0.5
                              delay:0.0
             usingSpringWithDamping:1.f
              initialSpringVelocity:0.5
                            options:0
                         animations:animations
                         completion:completion];
    }
    else
    {
        [UIView animateWithDuration:0.5*0.66
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:animations
                         completion:completion];
    }
}

+ (UIImage *)image1x1WithColor:(UIColor *)color
{
    if (!color) return nil;
    
    CGRect rect = CGRectMake(0.f, 0.f, 1.f, 1.f);
    
    UIGraphicsBeginImageContext(rect.size);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

+ (void)keyboardAnimateWithNotificationUserInfo:(NSDictionary *)notificationUserInfo animations:(void(^)(CGFloat keyboardHeight))animations
{
    CGFloat keyboardHeight = (notificationUserInfo[UIKeyboardFrameEndUserInfoKey] ? [notificationUserInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue].size.height : 0.f);
    
    if (!keyboardHeight) return;
    
    NSTimeInterval animationDuration = [notificationUserInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    int animationCurve = [notificationUserInfo[UIKeyboardAnimationCurveUserInfoKey] intValue];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];
    
    if (animations) animations(keyboardHeight);
    
    [UIView commitAnimations];
}

@end
