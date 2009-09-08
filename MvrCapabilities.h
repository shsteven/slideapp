// Mover Features
// List of kill-switches to be used during compiling to insert or remove a feature. Use this for testing or other non-nefarious purposes.

// Disables legacy Wi-Fi support (that is, connecting over sockets/BLIP to Mover 2.0.4 or previous versions thereof).
#ifndef kL0MoverTestByDisablingLegacyWiFi
#define kL0MoverTestByDisablingLegacyWiFi 0
#endif

// Disables modern Wi-Fi support (that is, connecting over sockets with AAP to Mover 2.1 and later).
#ifndef kL0MoverTestByDisablingModernWiFi
#define kL0MoverTestByDisablingModerWiFi 0
#endif

// Disables legacy Bluetooth support. (As of this build, all Bluetooth support is legacy since there is no AAP-enabled BT stack.)
#ifndef kL0MoverTestByDisablingBluetooth
#define kL0MoverTestByDisablingBluetooth 0
#endif