#pragma MIME video/mp4
#pragma endian big

#include <std/mem.pat>

fn not_end_of_box() {
	return $ < addressof(parent.parent.header) + parent.parent.header.size;
};

struct FileTypeBox {
	char major_brand[4];
	u32 minor_version;
	char compatible_brands[while(not_end_of_box())];
};

struct MvhdBox {
	u32 version_and_flag;
	u32 creation_time;
	u32 modification_time;
	u32 time_scale;
	u32 duration;
	u32 preferred_rate;
	u16 preferred_volume;
	padding[10]; // reserved
	u32 matrix[9];
	u32 preview_time;
	u32 preview_duration;
	u32 poster_time;
	u32 selection_time;
	u32 selection_duration;
	u32 current_time;
	u32 next_track_id;
};

struct TkhdBox {
	u32 version_and_flag;
	u32 creation_time;
	u32 modification_time;
	u32 track_id;
	padding[4]; // reserved
	u32 duration;
	padding[8]; // reserved
	u16 layer;
	u16 alternate_group;
	u16 volume;
	padding[2];
	u32 matrix[9];
	u32 width;
	u32 height;
};

struct TrunSample {
	if (parent.flags.duration == 1) {
		u32 duration;
	}
	if (parent.flags.size == 1) {
		u32 size;
	}
	if (parent.flags.flags == 1) {
		u32 flags;
	}
	if (parent.flags.cts_offset == 1) {
		if (parent.version == 0) {
			u32 sample_composition_time_offset;
		} else {
			s32 sample_composition_time_offset;
		}
	}
	
};

bitfield TrunFlags {
	padding: 12;
	cts_offset: 1;
	flags: 1;
	size: 1;
	duration: 1;
	padding: 5;
	first_flag: 1;
	padding: 1;
	data_offset: 1;
};

struct TrunBox {
	u8 version;
	TrunFlags flags;
	u32 sample_count;
	if (flags.data_offset == 1) {
		s32 data_offset;
	}
	if (flags.first_flag == 1) {
		u32 first_sample_flags;
	}
	TrunSample samples[while(not_end_of_box())];
};

struct BoxHeader {
	u32 size [[name("Size")]];
    char type[4] [[name("Name")]];
    
    // if (size == 1) {
    //    u64 largesize;
    //    u8 data[largesize - 16];
    // } else {
    //    u8 data[size - 8];
    // }
};

struct Box {
    BoxHeader header [[inline]];
    
    
    if (header.type == "ftyp") {
    	FileTypeBox content [[inline]];
    } else if (header.type == "mvhd") {
    	MvhdBox content [[inline]];
   	} else if (header.type == "tkhd") {
    	TkhdBox content [[inline]];
   	} else if (header.type == "trun") {
    	TrunBox content [[inline]];
   	} else if (
   		header.type == "moov" ||
   		header.type == "mvex" ||
   		header.type == "mdia" ||
   		header.type == "minf" ||
   		header.type == "dinf" ||
   		header.type == "stbl" ||
   		header.type == "udta" ||
   		header.type == "trak" ||
   		header.type == "traf" ||
   		header.type == "moof"
   	) {
   		Box children[while($ < addressof(header) + header.size)] [[inline]];
    } else if (
    	header.type == "stsd"
    ) {
    	u32 version_and_flag;
    	u32 entry_count;
    	Box children[while($ < addressof(header) + header.size)] [[inline]];
    } else {
    	u8 content[header.size - 8] [[comment("Unparsed Data")]];
    }
};

Box boxes[while($ < std::mem::size())] @ 0x00;