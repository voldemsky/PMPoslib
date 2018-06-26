//
//  CreditCardListViewController.h
//  PMPos
//
//  Created by lyg on 16/7/26.
//  Copyright © 2016年 Vbill Payment Co., Ltd. All rights reserved.
//

#import "BaseViewController.h"
/** 信用卡列表页面 */
#import "JGPopView.h"
#import "BindCreditModel.h"
@interface CreditCardListViewController : BaseViewController<selectIndexPathDelegate,UIAlertViewDelegate>

@property(nonatomic,retain)UIImageView *errorShowView;
@property(nonatomic,retain)UILabel *errorTitle;
@property(nonatomic,retain)UILabel *errorString;

/**交易失败进入绑定信用卡后，返回到刷卡的输入金额页面*/
@property(nonatomic,copy)void(^gotoSwipeCardBlock)(BOOL gotoSwipeCard);

#pragma mark 刷新数据
- (void)CreditCardShouldReloadViewWithIndex:(BindCreditModel *)cellModel;
#pragma mark 上传服务器删除某一条数据
- (void)userCancellCreditCardWith:(BindCreditModel *)cellModel;

@end
