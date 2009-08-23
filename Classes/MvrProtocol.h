//
//  MvrProtocol.h
//  Mover
//
//  Created by ∞ on 23/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

static const char kMvrPacketParserStartingBytes[] = { 'M', 'O', 'V', 'R', '2' };
static const size_t kMvrPacketParserStartingBytesLength =
	sizeof(kMvrPacketParserStartingBytes) / sizeof(char);

#define kMvrPacketParserSizeKey @"Size"
