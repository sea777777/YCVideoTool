//
//  ViewController.h
//  YCMediaDemo
//
//  Created by lyc on 2018/1/7.
//  Copyright © 2018年 lyc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *recordBtn;
@property (weak, nonatomic) IBOutlet UIButton *OKBtn;
@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet UILabel *tipLabel;
@property (weak, nonatomic) IBOutlet UIView *recordBtnBackgroundView;

@end

