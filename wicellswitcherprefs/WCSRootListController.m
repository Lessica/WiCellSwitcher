#include "WCSRootListController.h"

@implementation WCSRootListController

- (NSArray *)specifiers
{
	if (!_specifiers)
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	return _specifiers;
}

@end
