//
//  ViewController.h
//  GenerateModelFile
//
//  Created by Chiang on 2020/1/9.
//  Copyright © 2020 Chiang. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

@property (unsafe_unretained) IBOutlet NSTextView *jsonTextView;
@property (weak) IBOutlet NSButton *button;
@property (weak) IBOutlet NSTextField *className;
@property (weak) IBOutlet NSTextField *prefixLabel;
@property (weak) IBOutlet NSButton *validateButton;

@end

