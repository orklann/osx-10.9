/*
 * Copyright (c) 2010 Apple Inc. All rights reserved.
 *
 * @APPLE_LLVM_LICENSE_HEADER@
 */

/*
 *  orbars.c
 *  testObjects
 *
 *  Created by Blaine Garst on 9/17/08.
 *  Copyright 2008 __MyCompanyName__. All rights reserved.
 */

// rdar://6276695 error: before ‘|’ token
// TEST_CONFIG RUN=0

/*
TEST_BUILD_OUTPUT
.*orbars.c: In function '.*__main_block_invoke_1.*':
.*orbars.c:32: error: expected (primary-)?expression before '\|' token
OR
.*orbars.c:32:(41|60): error: expected expression
END
*/

#include <stdio.h>
#include "test.h"

int main() {
    int i __unused = 10;
    void (^b)(void) __unused = ^(void){ | i | printf("hello world, %d\n", i); };
    fail("should not compile");
}
