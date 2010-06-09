/*
 * Block_private.h
 *
 * Copyright 2008-2009 Apple, Inc. 
 * Copyright 2009 Plausible Labs Cooperative, Inc.
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
 *
 */

#ifndef _BLOCK_PRIVATE_H_
#define _BLOCK_PRIVATE_H_

/**
 * @ingroup private_api_constants
 * @{
 */

/**
 * Block Flags
 */
typedef enum {
    /** 16-bit block reference count. */
    BLOCK_REFCOUNT_MASK =     (0xffff),
    
    BLOCK_NEEDS_FREE =        (1 << 24),
    BLOCK_HAS_COPY_DISPOSE =  (1 << 25),
    
    /** Helpers have C++ code. */
    BLOCK_HAS_CTOR =          (1 << 26),

    BLOCK_IS_GC =             (1 << 27),
    BLOCK_IS_GLOBAL =         (1 << 28),
    BLOCK_HAS_DESCRIPTOR =    (1 << 29),
} block_flags_t;


/**
 * Block field flags.
 */
typedef enum {
    // see function implementation for a more complete description of these fields and combinations
    BLOCK_FIELD_IS_OBJECT   =  3,  // id, NSObject, __attribute__((NSObject)), block, ...
    BLOCK_FIELD_IS_BLOCK    =  7,  // a block variable
    BLOCK_FIELD_IS_BYREF    =  8,  // the on stack structure holding the __block variable
    BLOCK_FIELD_IS_WEAK     = 16,  // declared __weak, only used in byref copy helpers
    BLOCK_BYREF_CALLER      = 128, // called from __block (byref) copy/dispose support routines.
} block_field_flags_t;


/**
 * @}
 */


/**
 * @ingroup private_api
 * @{
 */


/**
 * Block description.
 *
 * Block descriptions are shared across all instances of a block, and
 * provide basic information on the block size, as well as pointers
 * to any helper functions necessary to copy or dispose of the block.
 */
struct Block_descriptor {
    /** Reserved value */
    unsigned long int reserved;

    /** Total size of the described block, including imported variables. */
    unsigned long int size;
    
    /** Optional block copy helper. May be NULL. */
    void (*copy)(void *dst, void *src);

    /** Optional block dispose helper. May be NULL. */
    void (*dispose)(void *);
};


/**
 * Block instance.
 *
 * The block layout defines the per-block instance state, which includes
 * a reference to the shared block descriptor.
 *
 * The block's imported variables are allocated following the block
 * descriptor member.
 */
struct Block_layout {
    /** Pointer to the block's Objective-C class. */
    void *isa;

    /** Block flags. */
    int flags;

    /** Reserved value. */
    int reserved;

    /** Block invocation function. */
    void (*invoke)(void *, ...);

    /** Shared block descriptor. */
    struct Block_descriptor *descriptor;

    // imported variables
};


/**
 * Block byref variable header.
 *
 * Defines the shared header of all Block_byref structure values.
 */
struct Block_byref_header {
    /** Initialized to NULL */
    void *isa;
    
    /** Pointer to the start of the enclosing structure */
    struct Block_byref *forwarding;
    
    /** 
     * Block reference flags. Set to BLOCK_HAS_COPY_DISPOSE if helper functions are required,
     * or 0 otherwise.
     */
    int flags;
    
    /** Total size of the enclosing structure. */
    int size;
};


/**
 * Block byref variable struct.
 *
 * Variables marked with __block are included by reference, and appended
 * to the Block_layout structure as a Block_byref instance.
 */
struct Block_byref {
    /** Initialized to NULL */
    void *isa;
    
    /** Pointer to the start of the enclosing structure */
    struct Block_byref *forwarding;
    
    /** 
     * Block reference flags. Set to BLOCK_HAS_COPY_DISPOSE if helper functions are required,
     * or 0 otherwise.
     */
    int flags;
    
    /** Total size of the enclosing structure. */
    int size;

    /** Block copy helper function, if needed. */
    void (*byref_keep)(struct Block_byref *dst, struct Block_byref *src);
    
    /** Block release helper function, if needed. */
    void (*byref_destroy)(struct Block_byref *);

    // long shared[0];
};


/**
 * @}
 */

#endif
