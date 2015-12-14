//
//  CYRTextStorage.m
//
//  Version 0.4.0
//
//  Created by Illya Busigin on 01/05/2014.
//  Copyright (c) 2014 Cyrillian, Inc.
//
//  Distributed under MIT license.
//  Get the latest version from here:
//
//  https://github.com/illyabusigin/CYRTextView
//
// The MIT License (MIT)
//
// Copyright (c) 2014 Cyrillian, Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
// the Software, and to permit persons to whom the Software is furnished to do so,
// subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "CYRTextStorage.h"
#import "CYRToken.h"

@interface CYRTextStorage ()

@property (nonatomic, strong) NSMutableAttributedString *attributedString;
@property (nonatomic, strong) NSMutableDictionary *regularExpressionCache;

@end

@implementation CYRTextStorage

#pragma mark - Initialization & Setup

- (id)init
{
    if (self = [super init])
    {
        _defaultFont = [UIFont systemFontOfSize:17.5f];
        _defaultTextColor = [UIColor colorWithRed:0.11 green:0.11 blue:0.11 alpha:1];
        _attributedString = [NSMutableAttributedString new];
        
        _tokens = @[];
        _regularExpressionCache = @{}.mutableCopy;
    }
    
    return self;
}


#pragma mark - Overrides

- (void)setTokens:(NSMutableArray *)tokens
{
    _tokens = tokens;
    
    // Clear the regular expression cache
    [self.regularExpressionCache removeAllObjects];
    
    // Redraw all text
    [self update];
}

- (NSString *)string
{
    return [_attributedString string];
}

- (NSDictionary *)attributesAtIndex:(NSUInteger)location effectiveRange:(NSRangePointer)range
{
    return [_attributedString attributesAtIndex:location effectiveRange:range];
}

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString*)str
{
    [self beginEditing];
    
    [_attributedString replaceCharactersInRange:range withString:str];
    
    [self edited:NSTextStorageEditedCharacters | NSTextStorageEditedAttributes range:range changeInLength:str.length - range.length];
    [self endEditing];
}

- (void)setAttributes:(NSDictionary*)attrs range:(NSRange)range
{
    [self beginEditing];
    
    [_attributedString setAttributes:attrs range:range];
    
    [self edited:NSTextStorageEditedAttributes range:range changeInLength:0];
    [self endEditing];
}

-(void)processEditing
{
    [self performReplacementsForRange:[self editedRange]];
    [super processEditing];
}

- (void)performReplacementsForRange:(NSRange)changedRange
{
    return [self update];
    NSRange extendedRange = NSUnionRange(changedRange, [[_attributedString string] lineRangeForRange:NSMakeRange(NSMaxRange(changedRange), 0)]);
    
    [self applyStylesToRange:extendedRange];
}


-(void)update
{
    NSRange range = NSMakeRange(0, self.length);

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 6;// 字体的行间距
    
    NSDictionary *attributes =
    @{
      NSFontAttributeName : self.defaultFont,
      NSForegroundColorAttributeName : self.defaultTextColor,
      NSParagraphStyleAttributeName:paragraphStyle
     };
    [self addAttributes:attributes range:range];

    [self applyStylesToRange:range];
}

- (void)applyStylesToRange:(NSRange)searchRange
{
    if (self.editedRange.location == NSNotFound)
    {
        return;
    }
    
    NSRange paragaphRange = [self.string paragraphRangeForRange: self.editedRange];

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineSpacing = 6;// 字体的行间距
    // Reset the text attributes
    NSDictionary *attributes =
    @{
      NSFontAttributeName : self.defaultFont,
      NSForegroundColorAttributeName : self.defaultTextColor,
      NSParagraphStyleAttributeName:paragraphStyle
     };
    [self setAttributes:attributes range:paragaphRange];
    
    for (CYRToken *token in self.tokens)
    {
        NSRegularExpression *regex = token.expression;//[self expressionForDefinition:attribute.name];
        
        [regex enumerateMatchesInString:self.string options:0 range:paragaphRange
                             usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                 NSLog(@"%@=>%@",regex,[self.string substringWithRange:result.range]);
                                 for (int i=0; i<result.numberOfRanges; i++) {
                                     NSRange range=[result rangeAtIndex:i];
                                     if (range.length>0) {
                                         NSLog(@"%@[%d]=>%@",regex,i,[self.string substringWithRange: range]);
                                     }
                                     
                                 }
                                 if (result.numberOfRanges>token.index) {
                                     NSRange range=[result rangeAtIndex:token.index];
                                     if (range.length>0) {
                                         [token.attributes enumerateKeysAndObjectsUsingBlock:^(NSString *attributeName, id attributeValue, BOOL *stop) {
                                             [self addAttribute:attributeName value:attributeValue range:range];
                                         }];
                                     }
                                 }
                                 
                                 
                             }];
    }
}

//- (NSRegularExpression *)expressionForDefinition:(NSString *)definition
//{
//    __block CYRToken *attribute = nil;
//    
//    [self.tokens enumerateObjectsUsingBlock:^(CYRToken *enumeratedAttribute, NSUInteger idx, BOOL *stop) {
//        if ([enumeratedAttribute.name isEqualToString:definition])
//        {
//            attribute = enumeratedAttribute;
//            *stop = YES;
//        }
//    }];
//    
//    NSRegularExpression *expression = self.regularExpressionCache[attribute.expression];
//    
//    if (!expression)
//    {
//        expression = [NSRegularExpression regularExpressionWithPattern:attribute.expression
//                                                               options:NSRegularExpressionCaseInsensitive error:nil];
//        
//        [self.regularExpressionCache setObject:expression forKey:definition];
//    }
//    
//    return expression;
//}

@end
