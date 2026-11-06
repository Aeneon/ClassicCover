/*
	MTEditTextCell.h
	ClassicCover

	Created by MacThemes on 10/28/26.
	Copyright © 2026 MacThemes. All rights reserved.
*/

#import <Foundation/Foundation.h>

#import <Preferences/PSEditableTableCell.h>
#import <Preferences/PSSpecifier.h>

@interface PSEditableTableCell(TextFieldAccess)

	- (UITextField *)textField;

@end

@interface MTEditTextCell: PSEditableTableCell
@end
