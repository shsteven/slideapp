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

#include "Block.h"
#include "Block_private.h"

#include <stdlib.h>
#include <string.h>
#include <libkern/OSAtomic.h>
#include <objc/runtime.h>

#include <CoreFoundation/CoreFoundation.h>



/* Class to use for block copies (Defaults to non-GC implementation) */
static void *_Block_copy_class;

/* Class to use for finalized block copies (Defaults to non-GC implementation) */
static void *_Block_copy_finalizing_class;


static id _NSConcreteStackBlock;
static id _NSConcreteMallocBlock;
static id _NSConcreteAutoBlock;
static id _NSConcreteFinalizingBlock;
static id _NSConcreteGlobalBlock;
static id _NSConcreteWeakBlockVariable;

/** Perform block initialization */
__attribute__((constructor)) static void  PLBlockInit () {
    /* Fetch ISA pointers */
    _NSConcreteStackBlock = objc_getClass("_PLConcreteStackBlock");
    _NSConcreteMallocBlock = objc_getClass("_PLConcreteMallocBlock");
    _NSConcreteAutoBlock = objc_getClass("_PLConcreteAutoBlock");
    _NSConcreteFinalizingBlock = objc_getClass("_PLConcreteFinalizingBlock");
    _NSConcreteGlobalBlock = objc_getClass("_PLConcreteGlobalBlock");
    _NSConcreteWeakBlockVariable = objc_getClass("_PLConcreteWeakBlockVariable");

    /* Set defaults */
    _Block_copy_class = _NSConcreteMallocBlock;
    _Block_copy_finalizing_class = _NSConcreteMallocBlock;
}


static int latching_incr_int(int *where);
static int latching_decr_int(int *where);

static void *_Block_copy_internal(const void *arg, const bool wantsOne);

/* If true, Garbage Collection is enabled */
static bool isGC = false;


/* Flag to set for block copies. (Defaults to non-GC implementation) */
static int _Block_copy_flag = BLOCK_NEEDS_FREE;


/* Flag to set for by-ref variables. (Defaults to non-GC flag) */
static int _Byref_flag_initial_value = BLOCK_NEEDS_FREE | 2;

/* GC/Non-GC Implementation Function Prototypes */
typedef void *(_Block_allocator_t)(const unsigned long, const bool isOne, const bool isObject);
typedef void (_Block_deallocator_t)(const void *);
typedef void (_Block_assign_t)(void *value, void **destptr);
typedef void (_Block_setHasRefcount_t)(const void *ptr, const bool hasRefcount);
typedef void (_Block_retain_object_t)(const void *ptr);
typedef void (_Block_release_object_t)(const void *ptr);
typedef void (_Block_assign_weak_t)(const void *dest, void *ptr);
typedef void (_Block_memmove_t)(void *dest, void *src, unsigned long size);

/* Default retain/release implementations */
static _Block_allocator_t       _Block_alloc_default;
static _Block_assign_t          _Block_assign_default;
static _Block_setHasRefcount_t  _Block_setHasRefcount_default;
static _Block_retain_object_t   _Block_retain_object_default;
static _Block_release_object_t  _Block_release_object_default;
static _Block_assign_weak_t     _Block_assign_weak_default;
static _Block_memmove_t         _Block_memmove_default;

/* GC/Non-GC support callout functions pointers. Default to non-GC implementation. */
static _Block_allocator_t       *_Block_allocator       = _Block_alloc_default;
static _Block_deallocator_t     *_Block_deallocator     = (void (*)(const void *))free;
static _Block_assign_t          *_Block_assign          = _Block_assign_default;
static _Block_setHasRefcount_t  *_Block_setHasRefcount  = _Block_setHasRefcount_default;
static _Block_retain_object_t   *_Block_retain_object   = _Block_retain_object_default;
static _Block_release_object_t  *_Block_release_object  = _Block_release_object_default;
static _Block_assign_weak_t     *_Block_assign_weak     = _Block_assign_weak_default;
static _Block_memmove_t         *_Block_memmove         = _Block_memmove_default;

/**
 * @ingroup functions
 * @{
 */


/**
 * Copy a a stack-allocated block. Blocks that do not require copying
 * (such as global or malloc-allocated blocks) will have their retain
 * count increased.
 *
 * @warning Calls to PLBlock_copy must be balanced with calls to PLBlock_release.
 */
void *_PLBlock_copy(const void *arg) {
    return _Block_copy_internal(arg, true);
}


/**
 * Release a copied block.
 * API entry point to release a copied Block
 */
void _PLBlock_release(const void *arg) {
    struct Block_layout *aBlock = (struct Block_layout *)arg;
    int32_t newCount;
    if (!aBlock) return;
    newCount = latching_decr_int(&aBlock->flags) & BLOCK_REFCOUNT_MASK;
    if (newCount > 0) return;
    // Hit zero
    if (aBlock->flags & BLOCK_IS_GC) {
        // Tell GC we no longer have our own refcounts.  GC will decr its refcount
        // and unless someone has done a CFRetain or marked it uncollectable it will
        // now be subject to GC reclamation.
        _Block_setHasRefcount(aBlock, false);
    }
    else if (aBlock->flags & BLOCK_NEEDS_FREE) {
        if (aBlock->flags & BLOCK_HAS_COPY_DISPOSE)(*aBlock->descriptor->dispose)(aBlock);
        _Block_deallocator(aBlock);
    }
    else if (aBlock->flags & BLOCK_IS_GLOBAL) {
        ;
    }
    else {
        printf("Block_release called upon a stack Block: %p, ignored\n", aBlock);
    }
}


/**
 * @}
 */


/**
 * @internal
 * @defgroup functions_internal_implementation Internal Implementation Functions
 * @ingroup functions
 * @{
 */

/** Non-GC block allocator */
static void *_Block_alloc_default(const unsigned long size, const bool initialCountIsOne, const bool isObject) {
    return malloc(size);
}

/** Non-GC block assignment */
static void _Block_assign_default(void *value, void **destptr) {
    *destptr = value;
}

/** Increment/decrement GC refcount. No-op if GC is disabled. */
static void _Block_setHasRefcount_default(const void *ptr, const bool hasRefcount) {
}

/** No-op block call. Used to replace retain/release calls if GC is enabled. */
static void _Block_do_nothing(const void *aBlock) {
}

/** Retain an object instance */
static void _Block_retain_object_default(const void *ptr) {
    if (!ptr) return;

    /* Bump the object's reference count */
    CFRetain(ptr);
}

/** Release an object instance */
static void _Block_release_object_default(const void *ptr) {
    if (!ptr) return;

    /* Decrement the object's reference count */
    CFRelease(ptr);
}

/** Non-GC weak assignment */
static void _Block_assign_weak_default(const void *ptr, void *dest) {
    *(long *)dest = (long)ptr;
}

/** Non-GC memmove */
static void _Block_memmove_default(void *dst, void *src, unsigned long size) {
    memmove(dst, src, (size_t)size);
}


// Public SPI
// Called from objc-auto to turn on GC.
// version 3, 4 arg, but changed 1st arg
void _PLBlock_use_GC(_Block_allocator_t *alloc,
                   _Block_setHasRefcount_t *setHasRefcount,
                   _Block_assign_t *gc_assign,
                   _Block_assign_weak_t *gc_assign_weak,
                   _Block_memmove_t *gc_memmove) {
    
    isGC = true;
    _Block_allocator = alloc;
    _Block_deallocator = _Block_do_nothing;
    _Block_assign = gc_assign;
    _Block_copy_flag = BLOCK_IS_GC;
    _Block_copy_class = _NSConcreteAutoBlock;
    // blocks with ctors & dtors need to have the dtor run from a class with a finalizer
    _Block_copy_finalizing_class = _NSConcreteFinalizingBlock;
    _Block_setHasRefcount = setHasRefcount;
    _Byref_flag_initial_value = BLOCK_IS_GC;   // no refcount
    _Block_retain_object = _Block_do_nothing;
    _Block_release_object = _Block_do_nothing;
    _Block_assign_weak = gc_assign_weak;
    _Block_memmove = gc_memmove;
}

// Copy, or bump refcount, of a block.  If really copying, call the copy helper if present.
static void *_Block_copy_internal(const void *arg, const bool wantsOne) {
    struct Block_layout *aBlock;
    
    //printf("_Block_copy_internal(%p, %x)\n", arg, flags);	
    if (!arg) return NULL;
    
    
    // The following would be better done as a switch statement
    aBlock = (struct Block_layout *)arg;
    if (aBlock->flags & BLOCK_NEEDS_FREE) {
        // latches on high
        latching_incr_int(&aBlock->flags);
        return aBlock;
    }
    else if (aBlock->flags & BLOCK_IS_GC) {
        // GC refcounting is expensive so do most refcounting here.
        if (wantsOne && ((latching_incr_int(&aBlock->flags) & BLOCK_REFCOUNT_MASK) == 1)) {
            // Tell collector to hang on this - it will bump the GC refcount version
            _Block_setHasRefcount(aBlock, true);
        }
        return aBlock;
    }
    else if (aBlock->flags & BLOCK_IS_GLOBAL) {
        return aBlock;
    }
    
    // Its a stack block.  Make a copy.
    if (!isGC) {
        struct Block_layout *result = malloc(aBlock->descriptor->size);
        if (!result) return (void *)0;
        memmove(result, aBlock, aBlock->descriptor->size); // bitcopy first
        // reset refcount
        result->flags &= ~(BLOCK_REFCOUNT_MASK);    // XXX not needed
        result->flags |= BLOCK_NEEDS_FREE | 1;
        result->isa = _NSConcreteMallocBlock;
        if (result->flags & BLOCK_HAS_COPY_DISPOSE) {
            //printf("calling block copy helper %p(%p, %p)...\n", aBlock->descriptor->copy, result, aBlock);
            (*aBlock->descriptor->copy)(result, aBlock); // do fixup
        }
        return result;
    }
    else {
        // Under GC want allocation with refcount 1 so we ask for "true" if wantsOne
        // This allows the copy helper routines to make non-refcounted block copies under GC
        unsigned long int flags = aBlock->flags;
        bool hasCTOR = (flags & BLOCK_HAS_CTOR) != 0;
        struct Block_layout *result = _Block_allocator(aBlock->descriptor->size, wantsOne, hasCTOR);
        if (!result) return (void *)0;
        memmove(result, aBlock, aBlock->descriptor->size); // bitcopy first
        // reset refcount
        // if we copy a malloc block to a GC block then we need to clear NEEDS_FREE.
        flags &= ~(BLOCK_NEEDS_FREE|BLOCK_REFCOUNT_MASK);   // XXX not needed
        if (wantsOne)
            flags |= BLOCK_IS_GC | 1;
        else
            flags |= BLOCK_IS_GC;
        result->flags = flags;
        if (flags & BLOCK_HAS_COPY_DISPOSE) {
            //printf("calling block copy helper...\n");
            (*aBlock->descriptor->copy)(result, aBlock); // do fixup
        }
        if (hasCTOR) {
            result->isa = _NSConcreteFinalizingBlock;
        }
        else {
            result->isa = _NSConcreteAutoBlock;
        }
        return result;
    }
}


static void _Block_destroy(const void *arg) {
    struct Block_layout *aBlock;
    if (!arg) return;
    aBlock = (struct Block_layout *)arg;
    if (aBlock->flags & BLOCK_IS_GC) {
        // assert(aBlock->Block_flags & BLOCK_HAS_CTOR);
        return; // ignore, we are being called because of a DTOR
    }
    _Block_release(aBlock);
}


// A closure has been copied and its fixup routine is asking us to fix up the reference to the shared byref data
// Closures that aren't copied must still work, so everyone always accesses variables after dereferencing the forwarding ptr.
// We ask if the byref pointer that we know about has already been copied to the heap, and if so, increment it.
// Otherwise we need to copy it and update the stack forwarding pointer
// XXX We need to account for weak/nonretained read-write barriers.
static void _Block_byref_assign_copy(void *dest, const void *arg, const int flags) {
    struct Block_byref **destp = (struct Block_byref **)dest;
    struct Block_byref *src = (struct Block_byref *)arg;
    
    //printf("_Block_byref_assign_copy called, byref destp %p, src %p, flags %x\n", destp, src, flags);
    //printf("src dump: %s\n", _Block_byref_dump(src));
    if (src->forwarding->flags & BLOCK_IS_GC) {
        ;   // don't need to do any more work
    }
    else if ((src->forwarding->flags & BLOCK_REFCOUNT_MASK) == 0) {
        //printf("making copy\n");
        // src points to stack
        bool isWeak = ((flags & (BLOCK_FIELD_IS_BYREF|BLOCK_FIELD_IS_WEAK)) == (BLOCK_FIELD_IS_BYREF|BLOCK_FIELD_IS_WEAK));
        // if its weak ask for an object (only matters under GC)
        struct Block_byref *copy = (struct Block_byref *)_Block_allocator(src->size, false, isWeak);
        copy->flags = src->flags | _Byref_flag_initial_value; // non-GC one for caller, one for stack
        copy->forwarding = copy; // patch heap copy to point to itself (skip write-barrier)
        src->forwarding = copy;  // patch stack to point to heap copy
        copy->size = src->size;
        if (isWeak) {
            copy->isa = &_NSConcreteWeakBlockVariable;  // mark isa field so it gets weak scanning
        }
        if (src->flags & BLOCK_HAS_COPY_DISPOSE) {
            // Trust copy helper to copy everything of interest
            // If more than one field shows up in a byref block this is wrong XXX
            copy->byref_keep = src->byref_keep;
            copy->byref_destroy = src->byref_destroy;
            (*src->byref_keep)(copy, src);
        }
        else {
            // just bits.  Blast 'em using _Block_memmove in case they're __strong
            _Block_memmove(
                           (void *)&copy->byref_keep,
                           (void *)&src->byref_keep,
                           src->size - sizeof(struct Block_byref_header));
        }
    }
    // already copied to heap
    else if ((src->forwarding->flags & BLOCK_NEEDS_FREE) == BLOCK_NEEDS_FREE) {
        latching_incr_int(&src->forwarding->flags);
    }
    // assign byref data block pointer into new Block
    _Block_assign(src->forwarding, (void **)destp);
}


static void _Block_byref_release(const void *arg) {
    struct Block_byref *shared_struct = (struct Block_byref *)arg;
    int refcount;
    
    // dereference the forwarding pointer since the compiler isn't doing this anymore (ever?)
    shared_struct = shared_struct->forwarding;
    
    //printf("_Block_byref_release %p called, flags are %x\n", shared_struct, shared_struct->flags);
    // To support C++ destructors under GC we arrange for there to be a finalizer for this
    // by using an isa that directs the code to a finalizer that calls the byref_destroy method.
    if ((shared_struct->flags & BLOCK_NEEDS_FREE) == 0) {
        return; // stack or GC or global
    }
    refcount = shared_struct->flags & BLOCK_REFCOUNT_MASK;
    if (refcount <= 0) {
        printf("_Block_byref_release: Block byref data structure at %p underflowed\n", arg);
    }
    else if ((latching_decr_int(&shared_struct->flags) & BLOCK_REFCOUNT_MASK) == 0) {
        //printf("disposing of heap based byref block\n");
        if (shared_struct->flags & BLOCK_HAS_COPY_DISPOSE) {
            //printf("calling out to helper\n");
            (*shared_struct->byref_destroy)(shared_struct);
        }
        _Block_deallocator((struct Block_layout *)shared_struct);
    }
}


/**
 * @}
 */



/**
 * @internal
 * @defgroup functions_internal_utilities Internal Utilities
 * @ingroup functions
 * @{
 */

/**
 * Atomic reference count increment.
 */
static int latching_incr_int(int *where) {
    while (1) {
        int old_value = *(volatile int *)where;
        if ((old_value & BLOCK_REFCOUNT_MASK) == BLOCK_REFCOUNT_MASK) {
            return BLOCK_REFCOUNT_MASK;
        }
        if (OSAtomicCompareAndSwapInt(old_value, old_value+1, (volatile int *)where)) {
            return old_value+1;
        }
    }
}


/**
 * Atomic reference count decrement.
 */
static int latching_decr_int(int *where) {
    while (1) {
        int old_value = *(volatile int *)where;
        if ((old_value & BLOCK_REFCOUNT_MASK) == BLOCK_REFCOUNT_MASK) {
            return BLOCK_REFCOUNT_MASK;
        }
        if ((old_value & BLOCK_REFCOUNT_MASK) == 0) {
            return 0;
        }
        if (OSAtomicCompareAndSwapInt(old_value, old_value-1, (volatile int *)where)) {
            return old_value-1;
        }
    }
}

/**
 * @}
 */


/**
 * @defgroup private_api_abi_functions Block ABI Functions
 *
 * Functions required by the Blocks Implementation ABI.
 *
 * A block-compatible compiler will issue calls to these ABI-required functions, and
 * they are not exposed to API clients.
 *
 * http://clang.llvm.org/docs/BlockImplementation.txt
 *
 * @ingroup private_api
 * @{
 */

/**
 * When Blocks or Block_byrefs hold objects then their copy routine helpers use this entry point
 * to do the assignment.
 */
void _PLBlock_object_assign(void *destAddr, const void *object, const int flags) {
    //printf("_Block_object_assign(*%p, %p, %x)\n", destAddr, object, flags);
    if ((flags & BLOCK_BYREF_CALLER) == BLOCK_BYREF_CALLER) {
        if ((flags & BLOCK_FIELD_IS_WEAK) == BLOCK_FIELD_IS_WEAK) {
            _Block_assign_weak(object, destAddr);
        }
        else {
            // do *not* retain or *copy* __block variables whatever they are
            _Block_assign((void *)object, destAddr);
        }
    }
    else if ((flags & BLOCK_FIELD_IS_BYREF) == BLOCK_FIELD_IS_BYREF)  {
        // copying a __block reference from the stack Block to the heap
        // flags will indicate if it holds a __weak reference and needs a special isa
        _Block_byref_assign_copy(destAddr, object, flags);
    }
    // (this test must be before next one)
    else if ((flags & BLOCK_FIELD_IS_BLOCK) == BLOCK_FIELD_IS_BLOCK) {
        // copying a Block declared variable from the stack Block to the heap
        _Block_assign(_Block_copy_internal(object, flags), destAddr);
    }
    // (this test must be after previous one)
    else if ((flags & BLOCK_FIELD_IS_OBJECT) == BLOCK_FIELD_IS_OBJECT) {
        //printf("retaining object at %p\n", object);
        _Block_retain_object(object);
        //printf("done retaining object at %p\n", object);
        _Block_assign((void *)object, destAddr);
    }
}

/**
 * When Blocks or Block_byrefs hold objects their destroy helper routines call this entry point
 * to help dispose of the contents
 * Used initially only for __attribute__((NSObject)) marked pointers.
 */
void _PLBlock_object_dispose(const void *object, const int flags) {
    //printf("_Block_object_dispose(%p, %x)\n", object, flags);
    if (flags & BLOCK_FIELD_IS_BYREF)  {
        // get rid of the __block data structure held in a Block
        _Block_byref_release(object);
    }
    else if ((flags & (BLOCK_FIELD_IS_BLOCK|BLOCK_BYREF_CALLER)) == BLOCK_FIELD_IS_BLOCK) {
        // get rid of a referenced Block held by this Block
        // (ignore __block Block variables, compiler doesn't need to call us)
        _Block_destroy(object);
    }
    else if ((flags & (BLOCK_FIELD_IS_WEAK|BLOCK_FIELD_IS_BLOCK|BLOCK_BYREF_CALLER)) == BLOCK_FIELD_IS_OBJECT) {
        // get rid of a referenced object held by this Block
        // (ignore __block object variables, compiler doesn't need to call us)
        _Block_release_object(object);
    }
}


/**
 * @}
 */
