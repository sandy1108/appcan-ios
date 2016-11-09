/*
 *  Copyright (C) 2014 The AppCan Open Source Project.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#import "EUExBase.h"
#import "EBrowserView.h"
#import "JSON.h"
#import "EBrowserController.h"
#import "EBrowserWindowContainer.h"
#import "WWidgetMgr.h"
#import "BUtility.h"
#import "WWidget.h"
#import "EBrowserWindow.h"
#import "WidgetOneDelegate.h"
#import "EUtility.h"
@implementation EUExBase

@synthesize meBrwView;

- (instancetype)init{
    return [self initWithBrwView:nil];
}

- (instancetype)initWithBrwView:(EBrowserView *) eInBrwView{
    self = [super init];
    if (self) {
        meBrwView = eInBrwView;
    }
    return self;
}


- (void)dealloc{
    //ACENSLog(@"EUExBase retain count is %d",[self retainCount]);
    //ACENSLog(@"EUExBase dealloc is %x", self);
    
    if (self.meBrwView) {
        self.meBrwView = nil;
    }
    
}


- (void)clean{
}

-(NSString*)absPath:(NSString*)inPath{
    ACENSLog(@"inpath start=%@",inPath);
    NSLog(@"appcan-->EUExBase.m-->absPath-->inpath start=%@",inPath);

    inPath = [inPath stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if ([inPath hasPrefix:@"file://"]) {
        inPath = [inPath substringFromIndex:[@"file://" length]];
        return inPath;
    }
    if ([inPath hasPrefix:@"/var/mobile"]||[inPath hasPrefix:@"assets-library"]||[inPath hasPrefix:@"/private/var/mobile"]||[inPath hasPrefix:@"/Users"]||[inPath hasPrefix:@"file://"]) {
        return inPath;
    }
    NSURL *curURL = [self.meBrwView curUrl];
    
    NSString *scheme = [[NSURL URLWithString:inPath] scheme];
    
    inPath = [BUtility makeUrl:[curURL absoluteString] url:inPath];
    
    //box://
    NSLog(@"appcan-->EUExBase.m-->absPath-->%@",inPath);

   if ([inPath hasPrefix:F_BOX_PATH] || [inPath hasPrefix:F_EXTERBOX_PATH]) {
        NSString * str = [BUtility getDocumentsPath:@"box"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:str]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:str withIntermediateDirectories:YES attributes:nil error:nil];
        }
       
         NSString *resultStr = [NSString stringWithFormat:@"%@/%@",str,[inPath substringFromIndex:scheme.length+3]];;
       
        //NSLog(@"str=%@",resultStr);
        return resultStr;
    }
    if ([inPath hasPrefix:F_WGTS_PATH]||[inPath hasPrefix:F_APP_PATH]||[inPath hasPrefix:F_RES_PATH]) {
        //		EBrowserWindowContainer *eBrwWndContainer = (EBrowserWindowContainer*)meBrwView.meBrwWnd.superview;
        
        EBrowserWindowContainer *eBrwWndContainer = [EBrowserWindowContainer getBrowserWindowContaier:self.meBrwView];
        NSString *absPath =nil;
        absPath=[self.meBrwView.meBrwCtrler.mwWgtMgr curWidgetPath:eBrwWndContainer.mwWgt];
        ACENSLog(@"abspath=%@",absPath);
        NSString *relativePath=nil;
        if ([inPath hasPrefix:F_APP_PATH]) {
            relativePath =[inPath substringFromIndex:6];
        }
        if ([inPath hasPrefix:F_RES_PATH]) {
            relativePath =[inPath substringFromIndex:6];
            if (eBrwWndContainer.mwWgt.wgtType==F_WWIDGET_MAINWIDGET) {
                BOOL isCopyFinish = [[[NSUserDefaults standardUserDefaults]objectForKey:F_UD_WgtCopyFinish] boolValue];
                if (theApp.useUpdateWgtHtmlControl && isCopyFinish) {
                    if ([BUtility getSDKVersion]<5.0) {
                        absPath =[BUtility getCachePath:@"widget/wgtRes"];
                    }else {
                        absPath =[BUtility getDocumentsPath:@"widget/wgtRes"];
                    }
                }else {
                    absPath =[BUtility getResPath:@"widget/wgtRes"];
                }
            }else {
                absPath = [NSString stringWithFormat:@"%@/wgtRes",absPath];
            }
            ACENSLog(@"absPath middle=%@",absPath);
            
        }
        if ([inPath hasPrefix:F_WGTS_PATH]) {
            absPath = [BUtility getDocumentsPath:@"widgets"];
            relativePath =[inPath substringFromIndex:7]; 
        }
        inPath = [NSString stringWithFormat:@"%@/%@",absPath,relativePath];
        ACENSLog(@"inPath end=%@",inPath);
    }
    if ([inPath hasPrefix:@"file://"]) {
        inPath = [inPath substringFromIndex:[@"file://" length]];
    }
    return inPath;
}
@end


@implementation EUExBase (Deprecated)

- (void)jsSuccessWithName:(NSString *)inCallbackName opId:(int)inOpId dataType:(int)inDataType strData:(NSString*)inData {
    //inData = [inData stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *jsSuccessStr = [NSString stringWithFormat:@"if(%@){%@(%d,%d,\'%@\');}",inCallbackName,inCallbackName,inOpId,inDataType,inData];
    ACENSLog(@"jsSuccessStr=%@",jsSuccessStr);
    [EUtility brwView:self.meBrwView evaluateScript:jsSuccessStr];
    
}

- (void)jsSuccessWithName:(NSString *)inCallbackName opId:(int)inOpId dataType:(int)inDataType intData:(int)inData {
    NSString *jsSuccessStr = [NSString stringWithFormat:@"if(%@){%@(%d,%d,%d);}",inCallbackName,inCallbackName,inOpId,inDataType,inData];
    ACENSLog(@"jsSuccessStr=%@",jsSuccessStr);
    [EUtility brwView:self.meBrwView evaluateScript:jsSuccessStr];
    
}

- (void)jsFailedWithOpId:(int)inOpId errorCode:(int)inErrorCode errorDes:(NSString*)inErrorDes {
    inErrorDes =[inErrorDes stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *jsFailedStr = [NSString stringWithFormat:@"if(uexWidgetOne.cbError){uexWidgetOne.cbError(%d,%d,\'%@\');}",inOpId,inErrorCode,inErrorDes];
    ACENSLog(@"jsFailedStr=%@",jsFailedStr);
    [EUtility brwView:self.meBrwView evaluateScript:jsFailedStr];
    
}
- (void)stopNetService {
}


@end
