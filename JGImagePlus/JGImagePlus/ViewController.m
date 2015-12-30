//
//  ViewController.m
//  JGImagePlus
//
//  Created by Ji Fu on 12/29/15.
//  Copyright © 2015 Ji Fu. All rights reserved.
//

#import "ViewController.h"

#import <SDWebImage+ExtensionSupport/SDImageCache.h>

@interface ViewController ()

// *********************************************************************************************************************
#pragma mark - Property
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UITextField *urlTextField;
@property (weak, nonatomic) IBOutlet UIButton *getSizeBtn;
@property (weak, nonatomic) IBOutlet UIButton *downImageBtn;

@end

@implementation ViewController

// *********************************************************************************************************************
#pragma mark - life Cycle
- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self setupUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

// *********************************************************************************************************************
#pragma mark - Private
- (void)setupUI {
    
    // 
    // getSizeBtn
    [self.getSizeBtn setTitle:@"通过url获取图片大小" forState:UIControlStateNormal];
    [self.getSizeBtn addTarget:self action:@selector(getSizeBtnTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    // downImageBtn
    [self.downImageBtn setTitle:@"下载图片" forState:UIControlStateNormal];
    [self.downImageBtn addTarget:self action:@selector(downImageBtnTapped:) forControlEvents:UIControlEventTouchUpInside];
    
}

// *********************************************************************************************************************
#pragma mark - Actions
- (void)getSizeBtnTapped:(id)sender {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"alert"
                                                    message:@""
                                                   delegate:self
                                          cancelButtonTitle:@"canncel"
                                          otherButtonTitles:@"OK", nil];
    
    [alert show];
}

- (void)downImageBtnTapped:(id)sender {
    
}


@end
