// All that follows comes from http://landonf.bikemonkey.org/code/iphone/iPhone_Preventing_Piracy.20090213.html
// Used with slight changes and without permission. May landonf forgive me.

#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <TargetConditionals.h>

/* The encryption info struct and constants are missing from the iPhoneSimulator SDK, but not from the iPhoneOS or
 * Mac OS X SDKs. Since one doesn't ever ship a Simulator binary, we'll just provide the definitions here. */
#if TARGET_IPHONE_SIMULATOR && !defined(LC_ENCRYPTION_INFO)
#define LC_ENCRYPTION_INFO 0x21
struct encryption_info_command {
    uint32_t cmd;
    uint32_t cmdsize;
    uint32_t cryptoff;
    uint32_t cryptsize;
    uint32_t cryptid;
};
#endif

int main (int argc, char *argv[]);

static inline BOOL MvrIsRunningUnsignedInSeatbeltedEnvironment() __attribute__((always_inline));
static inline BOOL MvrIsRunningUnsignedInSeatbeltedEnvironment() {
#if TARGET_IPHONE_SIMULATOR || kMvrIsOpen
	return NO;
#else
    const struct mach_header *header;
    Dl_info dlinfo;
	
    /* Fetch the dlinfo for main() */
    if (dladdr(main, &dlinfo) == 0 || dlinfo.dli_fbase == NULL) {
        NSLog(@"Could not find main() symbol (very odd)");
        return YES;
    }
    header = dlinfo.dli_fbase;
	
    /* Compute the image size and search for a UUID */
    struct load_command *cmd = (struct load_command *) (header+1);
	
    for (uint32_t i = 0; cmd != NULL && i < header->ncmds; i++) {
        /* Encryption info segment */
        if (cmd->cmd == LC_ENCRYPTION_INFO) {
            struct encryption_info_command *crypt_cmd = (struct encryption_info_command *) cmd;
            /* Check if binary encryption is enabled */
            if (crypt_cmd->cryptid < 1) {
                /* Disabled, probably pirated */
                return YES;
            }
			
            /* Probably not pirated? */
            return NO;
        }
		
        cmd = (struct load_command *) ((uint8_t *) cmd + cmd->cmdsize);
    }
	
    /* Encryption info not found */
    return YES;
#endif
}
