//
//  ViewController.m
//  GenerateModelFile
//
//  Created by Chiang on 2020/1/9.
//  Copyright © 2020 Chiang. All rights reserved.
//

#import "ViewController.h"

@interface ViewController(){
    NSString *jsonStr;//待转化的json字符串
    NSDictionary *parsedJsonData;
    NSString *headerFileContent;//.h文件
    NSString *impFileContent;//.m文件
    NSString *prefix;
    NSString *rootName;
    NSMutableArray *interfaceArray;
    NSMutableArray *implementationArray;
    BOOL isAddComment;//是否添加注释
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    headerFileContent = @"";
    impFileContent = @"";
    isAddComment = YES;
    self.prefixLabel.stringValue = @"SEG";
    self.className.stringValue = @"ModelName";
    interfaceArray = [NSMutableArray array];
    implementationArray = [NSMutableArray array];
    
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

- (IBAction)addComments:(id)sender {
    isAddComment = !isAddComment;
}

//校验json
- (IBAction)validateClicked:(id)sender {
    jsonStr = self.jsonTextView.string;
    if([self isJsonString:jsonStr]) {//如果合法，则格式化
        NSDictionary *dict = [self dataWithJsonString:jsonStr];
        self.jsonTextView.string = [self dictionaryToJson:dict];
        jsonStr = self.jsonTextView.string;
    } else if ([jsonStr containsString:@"//"]){//如果是doclever预览json串，则过滤校验生成合法字符串
        if ([jsonStr hasPrefix:@"- "]) {
            jsonStr = [jsonStr substringFromIndex:2];
        }
        jsonStr = [jsonStr stringByReplacingOccurrencesOfString:@" - " withString:@""];
        NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"{}[]\""];
        NSString *subStr = jsonStr;//后面剩余的字符串
        NSMutableString *appendStr = @"".mutableCopy;//前面拼接的字符串
        NSMutableString *appendCommentStr = @"".mutableCopy;//前面拼接的字符串,带有注释
        
        while (subStr.length > 1) {
            NSRange range = [subStr rangeOfString:@"//"];
            NSMutableString *beforeSlashStr = [subStr substringToIndex:range.location].mutableCopy;//截取到双斜杠所在的位置
            [appendStr appendString:beforeSlashStr];
            subStr = [subStr substringFromIndex:range.location];//双斜杠以后的字符串
            
            NSRange characterRange = [subStr rangeOfCharacterFromSet:set];//查找{["等字符
            NSString *comment = [subStr substringToIndex:characterRange.location];//注释内容。//以后，特殊字符以前
            
            if ([beforeSlashStr containsString:@":"]) {//有属性名h才会有：，才会有注释
                NSRange range = [beforeSlashStr rangeOfString:@"\""];
                NSMutableString *property = [beforeSlashStr substringFromIndex:range.location+1].mutableCopy;
                [appendCommentStr appendString:[beforeSlashStr substringToIndex:range.location+1]];
                NSRange range2 = [property rangeOfString:@"\""];//key的第二个"的位置
                [property insertString:comment atIndex:range2.location];
                [appendCommentStr appendString:property];
            } else {
                [appendCommentStr appendString:beforeSlashStr];
            }
            subStr = [subStr substringFromIndex:characterRange.location];//特殊字符以后的字符串
        }
        [appendStr appendString:subStr];
        [appendCommentStr appendString:subStr];
        [appendCommentStr replaceOccurrencesOfString:@"\n" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, appendCommentStr.length)];
        jsonStr = isAddComment ? appendCommentStr : appendStr;
        NSDictionary *dict = [self dataWithJsonString:appendStr];
        self.jsonTextView.string = [self dictionaryToJson:dict];
    } else {
        if (![self dataWithJsonString:jsonStr]) return;//json解析失败
    }
}

//点击保存文件
- (IBAction)testClicked:(id)sender {
    if(!jsonStr) {
        [self validateClicked:nil];
    } else {
        if (!isAddComment) {
            jsonStr = self.jsonTextView.string;
        }
    }
    if (self.prefixLabel.stringValue.length == 0 || self.className.stringValue.length == 0) {
        return;
    }
    prefix = self.prefixLabel.stringValue;
    rootName = [NSString stringWithFormat:@"%@%@",prefix,self.className.stringValue];
    parsedJsonData = [self dataWithJsonString:jsonStr];
    if (!parsedJsonData) return;//json解析失败
    
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.title = @"保存Model文件";
    panel.message = @"选择存储位置";
    panel.prompt = @"Choose";
    panel.canCreateDirectories = YES;
    panel.canChooseDirectories = YES;
    panel.canChooseFiles = NO;
    panel.extensionHidden = NO;
    panel.allowsOtherFileTypes = NO;
    panel.treatsFilePackagesAsDirectories = NO;
    [panel beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse result) {
        if (result == NSModalResponseOK) {
            NSError *error1,*error2;
            NSString *headerPath = [NSString stringWithFormat:@"%@/%@.h",[[panel URL] path],self->rootName];
            NSString *impPath = [NSString stringWithFormat:@"%@/%@.m",[[panel URL] path],self->rootName];
            [self generateModelHeaderFileContent];
            [self generateModelImpFileContent];
            
            [self->headerFileContent writeToFile:headerPath atomically:YES encoding:NSUTF8StringEncoding error:&error1];
            [self->impFileContent writeToFile:impPath atomically:YES encoding:NSUTF8StringEncoding error:&error2];
        }
    }];
}

//生成.h文件
- (void)generateModelHeaderFileContent {
    headerFileContent = @"";
    impFileContent = @"";
    
    [interfaceArray removeAllObjects];
    [implementationArray removeAllObjects];
    
    headerFileContent = [headerFileContent stringByAppendingString:[self appendCopyright:@".h"]];
    [self appendInterface:parsedJsonData className:rootName];
    headerFileContent = [headerFileContent stringByAppendingString:[interfaceArray componentsJoinedByString:@"\n"]];
}

//生成.m文件
- (void)generateModelImpFileContent {
    impFileContent = [impFileContent stringByAppendingString:[self appendCopyright:@".m"]];
    impFileContent = [impFileContent stringByAppendingString:[NSString stringWithFormat:@"\n#import \"%@.h\"\n\n",rootName]];
    impFileContent = [impFileContent stringByAppendingString:[implementationArray componentsJoinedByString:@"\n"]];
    
    NSLog(@"%@",impFileContent);
}

//生成头部copyright
- (NSString *)appendCopyright:(NSString *)suffix {
    NSString *content = @"";
    content = [content stringByAppendingString: [NSString stringWithFormat:@"\n//\n//\t%@%@\n",rootName,suffix]];
    content = [content stringByAppendingString: @"//\tAll rights reserved.\n\n"];
    return content;
}

//生成类名和属性
- (void)appendInterface:(NSDictionary *)dict className:(NSString *)className{
    
    NSString *interface = [NSString stringWithFormat:@"\n@interface %@ : NSObject\n\n",className];
    NSString *implementation = [NSString stringWithFormat:@"\n@implementation %@\n\n",className];
    NSMutableDictionary *mapDict = [NSMutableDictionary dictionary];
    
    for (NSString * propertyName in dict.allKeys) {
        id propertyValue = dict[propertyName];
        NSArray *commentArr = [propertyName componentsSeparatedByString:@"//"];
        NSString *property = commentArr[0];
        NSString *comment = commentArr.count > 1 ? [NSString stringWithFormat:@"//%@",commentArr[1]] : @"";
        if ([propertyValue isKindOfClass:[NSDictionary class]]) {
            interface = [interface stringByAppendingFormat:@"@property (nonatomic, strong) %@ *%@; %@\n",
                         [NSString stringWithFormat:@"%@_%@",className,property],
                         property,comment];
            [mapDict setValue:[NSString stringWithFormat:@"%@_%@.class",className,property] forKey:property];
            [self appendInterface:propertyValue className:[NSString stringWithFormat:@"%@_%@",className,property]];
            
        } else if ([propertyValue isKindOfClass:[NSArray class]]) {
            interface = [interface stringByAppendingFormat:@"@property (nonatomic, strong) NSArray <%@*> *%@; %@\n",
                         [NSString stringWithFormat:@"%@_%@",className,property],
                         property,comment];
            [mapDict setValue:[NSString stringWithFormat:@"%@_%@.class",className,property] forKey:property];
            [self appendInterface:propertyValue[0] className:[NSString stringWithFormat:@"%@_%@",className,property]];
            
        }  else if ([propertyValue isKindOfClass:[NSString class]]){
            interface = [interface stringByAppendingFormat:@"@property (nonatomic, copy) NSString *%@; %@\n",property,comment];
            
        }
    }
    interface = [interface stringByAppendingFormat:@"\n\n@end\n"];
    
    if (mapDict.allValues.count > 0) {
        NSString *dictStr = @"";
        for (NSString *key in mapDict) {
            dictStr = [dictStr stringByAppendingFormat:@"@\"%@\" : %@,\n\t",key,mapDict[key]];
        }
        implementation = [implementation stringByAppendingString:[NSString stringWithFormat:@"+ (NSDictionary *)modelContainerPropertyGenericClass {\n\treturn @{%@\t};\n}\n",dictStr]];
    }
    implementation = [implementation stringByAppendingFormat:@"\n@end\n"];
    
    [interfaceArray addObject:interface];
    [implementationArray addObject:implementation];
}


//json解析
- (id)dataWithJsonString:(NSString *)jsonString {
    if (jsonString == nil || jsonString.length == 0) {
        return nil;
    }
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *err;
    id data = [NSJSONSerialization JSONObjectWithData:jsonData
                                              options:NSJSONReadingMutableContainers
                                                error:&err];
    if(err) {
        NSAlert *alert = [NSAlert alertWithError:err];
        [alert runModal];
        return nil;
    }
    return data;
}

//判断json是否合法
- (BOOL)isJsonString:(NSString *)jsonString {
    if (jsonString == nil || jsonString.length == 0) {
        return NO;
    }
    NSError *err;
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&err];
    if(err) {
        return NO;
    }
    return YES;;
}

//转json
- (NSString*)dictionaryToJson:(NSDictionary *)dic {
    NSError *parseError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:&parseError];
    return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}
@end
