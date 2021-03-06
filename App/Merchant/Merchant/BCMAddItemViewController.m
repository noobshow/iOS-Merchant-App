//
//  BCMAddItemViewController.m
//  Merchant
//
//  Created by User on 4/1/15.
//  Copyright (c) 2015 com. All rights reserved.
//

#import "BCMAddItemViewController.h"

#import "BCMTextField.h"

#import "Item.h"
#import "Merchant.h"
#import "BCMMerchantManager.h"

#import "UIColor+Utilities.h"
#import "Foundation-Utility.h"

#import "BCMMerchantManager.h"

@interface BCMAddItemViewController ()

@property (weak, nonatomic) IBOutlet BCMTextField *itemNameTextField;
@property (weak, nonatomic) IBOutlet BCMTextField *itemPriceTextField;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@property (strong, nonatomic) UIView *inputAccessoryView;

@end

@implementation BCMAddItemViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.itemNameTextField.textEditingInset = UIEdgeInsetsMake(0.0f, 20.0f, 0.0f, 0.0f);
    self.itemPriceTextField.textEditingInset = UIEdgeInsetsMake(0.0f, 20.0f, 0.0f, 0.0f);
    
    self.itemNameTextField.textInset = UIEdgeInsetsMake(0.0f, 20.0f, 0.0f, 0.0f);
    self.itemPriceTextField.textInset = UIEdgeInsetsMake(0.0f, 20.0f, 0.0f, 0.0f);
    
    [self.saveButton setBackgroundColor:[UIColor colorWithHexValue:BLOCK_CHAIN_SEND_GREEN]];
    [self.doneButton setBackgroundColor:[UIColor colorWithHexValue:BLOCK_CHAIN_SECONDARY_GRAY]];
    
    NSString *cancelString = NSLocalizedString(@"action.cancel", nil);
    [self.doneButton setTitle:[cancelString capitalizedString]  forState:UIControlStateNormal];
    
    NSString *saveString = NSLocalizedString(@"action.save", nil);
    [self.saveButton setTitle:[saveString capitalizedString]  forState:UIControlStateNormal];
    
    [self clearTitleView];
    if (self.item) {
        self.navigationItem.title = @"Edit Item";
    } else {
        self.navigationItem.title = @"Add Item";
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.item) {
        [self updateViewForCurrentItem];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [self unregisterObservers];
}

- (void)registerObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:) name:@"UIKeyboardWillShowNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:) name:@"UIKeyboardWillHideNotification" object:nil];
}

- (void)unregisterObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"UIKeyboardWillShowNotification" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"UIKeyboardWillHideNotification" object:nil];
}

@synthesize item = _item;

- (void)setItem:(Item *)item
{
    _item = item;
    
    [self updateViewForCurrentItem];
}

- (void)updateViewForCurrentItem
{
    NSString *itemName = _item.name;
    if ([itemName length] > 0) {
        self.itemNameTextField.text = _item.name;
    }
    
    if ([_item.price floatValue] > 0) {
        NSString *price = @"";
        if ([[BCMMerchantManager sharedInstance].activeMerchant.currency isEqualToString:BITCOIN_CURRENCY]) {
            price = [NSString stringWithFormat:@"%.4f", [_item.price floatValue]];
        } else {
            price = [NSString stringWithFormat:@"%.2f", [_item.price floatValue]];
        }
        self.itemPriceTextField.text = price;
    }
}

#pragma mark - Actions

- (IBAction)cancelAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveAction:(id)sender
{
    NSString *itemName = [self.itemNameTextField text];
    NSString *itemPrice = [self.itemPriceTextField text];
    if ([itemName length] == 0) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"addItem.error.missing.name", nil) message:NSLocalizedString(@"addItem.error.missing.name.detail", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"alert.ok", nil) otherButtonTitles:nil] show];
    } else if ([itemPrice length] == 0) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"addItem.error.missing.price", nil) message:NSLocalizedString(@"addItem.error.missing.price.detail", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"alert.ok", nil) otherButtonTitles:nil] show];
    } else if ([itemPrice floatValue] == 0) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"addItem.error.zero.price", nil) message:NSLocalizedString(@"addItem.error.zero.price.detail", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"alert.ok", nil) otherButtonTitles:nil] show];
    } else {
        
        if (self.item) {
            NSString *itemName = [self.itemNameTextField text];
            NSString *itemPrice = [self.itemPriceTextField text];
            self.item.name = itemName;
            self.item.priceValue = [itemPrice floatValue];
            if ([self.delegate respondsToSelector:@selector(addItemViewController:didSaveItem:)]) {
                [self.delegate addItemViewController:self didSaveItem:self.item];
            }
        } else {
            Item *item = [Item MR_createEntity];
            item.name = itemName;
            CGFloat floatPrice = [itemPrice floatValue];
            item.price = [NSNumber numberWithFloat:floatPrice];
            if ([self.delegate respondsToSelector:@selector(addItemViewController:didSaveItem:)]) {
                [self.delegate addItemViewController:self didSaveItem:item];
            }
        }
    }
}

- (void)accessoryDoneAction:(id)sender
{
    [self.view endEditing:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    textField.inputAccessoryView = [self inputAccessoryView];
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

- (UIView *)inputAccessoryView {
    if (!_inputAccessoryView) {
        UIView *parentView = self.view;
        CGRect accessFrame = CGRectMake(0.0, 0.0, CGRectGetWidth(parentView.frame), 54.0f);
        self.inputAccessoryView = [[UIView alloc] initWithFrame:accessFrame];
        self.inputAccessoryView.backgroundColor = [UIColor colorWithHexValue:BCM_BLUE];
        UIButton *compButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        compButton.frame = CGRectMake(CGRectGetWidth(parentView.frame) - 80.0f, 10.0, 80.0f, 40.0f);
        [compButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:20.0f]];
        [compButton setTitle:NSLocalizedString(@"general.done", nil) forState:UIControlStateNormal];
        [compButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [compButton addTarget:self action:@selector(accessoryDoneAction:)
             forControlEvents:UIControlEventTouchUpInside];
        [self.inputAccessoryView addSubview:compButton];
    }
    return _inputAccessoryView;
}

#pragma mark - Keyboard Notifications

- (void)keyboardWillShow:(NSNotification *)notification
{
    if ([self.itemPriceTextField isFirstResponder]) {
        NSDictionary *dict = notification.userInfo;
        NSValue *endRectValue = [dict safeObjectForKey:UIKeyboardFrameEndUserInfoKey];
        CGRect endKeyboardFrame = [endRectValue CGRectValue];
        CGRect convertedEndKeyboardFrame = [self.view convertRect:endKeyboardFrame fromView:nil];
        CGRect convertedWalletFrame = [self.view convertRect:self.itemPriceTextField.frame fromView:self.scrollView];
        CGFloat lowestPoint = CGRectGetMaxY(convertedWalletFrame);
        
        // If the ending keyboard frame overlaps our textfield
        if (lowestPoint > CGRectGetMinY(convertedEndKeyboardFrame)) {
            self.scrollView.scrollEnabled = YES;
            self.scrollView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, lowestPoint - CGRectGetMinY(convertedEndKeyboardFrame), 0.0f);
            [self.scrollView setContentOffset:CGPointMake(0.0f, lowestPoint - CGRectGetMinY(convertedEndKeyboardFrame)) animated:YES];
        }
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    if (self.scrollView.scrollEnabled) {
        self.scrollView.scrollEnabled = NO;
        
        NSDictionary *dict = notification.userInfo;
        NSTimeInterval duration = [[dict safeObjectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        UIViewAnimationCurve curve = [[dict safeObjectForKey:UIKeyboardAnimationCurveUserInfoKey] unsignedIntegerValue];
        
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:duration];
        [UIView setAnimationCurve:curve];
        self.scrollView.contentInset = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
        [UIView commitAnimations];
    }
}

@end
