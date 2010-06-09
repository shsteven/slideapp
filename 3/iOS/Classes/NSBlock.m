/*
 * Copyright 2008-2009 Apple, Inc.
 * Copyright 2009 Plausible Labs Cooperative, Inc.
 *
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge,
 * to any person obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without restriction,
 * including without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to permit
 * persons to whom the Software is furnished to do so, subject to the following
 * conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#import "NSBlock.h"

/**
 * @ingroup private_api
 * @{
 */

#define BLOCK(id) ((struct Block_layout *)id)

/**
 * Abstract Block Superclass.
 */
@implementation _PLAbstractBlock

- (void) dealloc {
    /* Quiesce [super dealloc] warnings */
    if (NO) [super dealloc];
}

@end



@implementation _PLConcreteMallocBlock


- (id) copyWithZone: (NSZone *) zone {
    return (id) Block_copy((void *) self);
}

- (id) copy {
    return [self copyWithZone: nil];
}

- (id) retain {
    return [self copyWithZone: nil];
}

- (void) release {
    Block_release((void *) self);
}

- (NSUInteger) retainCount {
    return BLOCK(self)->flags & BLOCK_REFCOUNT_MASK;
}

@end



@implementation _PLConcreteStackBlock

- (id) copyWithZone: (NSZone *) zone {
    return (id) Block_copy((void *) self);
}

- (id) copy {
    return [self copyWithZone: nil];
}

- (id) retain {
    /* Allocated on stack */
    return self;
}

- (void) release {
    /* Allocated on stack */
}

- (NSUInteger) retainCount {
    return UINT_MAX;
}

@end


@implementation _PLConcreteGlobalBlock

- (id) copyWithZone: (NSZone *) zone {
    return self; 
}

- (id) copy { 
    return self;
}

- (id) retain { 
    return self; 
}

- (void) release {
}

- (NSUInteger) retainCount { 
    return UINT_MAX; 
}

@end

// XXX TODO: Garbage Collection Support

@implementation _PLConcreteWeakBlockVariable
@end

@implementation _PLConcreteAutoBlock
@end

@implementation _PLConcreteFinalizingBlock
@end


/**
 * @}
 */