//
//  MvrProtocol.h
//  Mover
//
//  Created by ∞ on 23/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

static const uint8_t kMvrPacketParserStartingBytes[] = { 'M', 'O', 'V', 'R', '2' };
static const size_t kMvrPacketParserStartingBytesLength =
	sizeof(kMvrPacketParserStartingBytes) / sizeof(uint8_t);

#define kMvrPacketParserSizeKey @"Size"

#define kMvrProtocolPayloadStopsKey @"Payload-Stops"
#define kMvrProtocolPayloadKeysKey @"Payload-Keys"

#define kMvrPacketIndeterminateProgress ((CGFloat) -1.0)

// ----

#define kMvrProtocolExternalRepresentationPayloadKey @"externalRepresentation"
#define kMvrProtocolMetadataTitleKey @"MvrTitle"
#define kMvrProtocolMetadataTypeKey @"MvrType"
