/*
Read from sram, write to video memory
*/

typedef unsigned char byte;
typedef unsigned int TIMESTAMP;

int t(){
	byte *image = (byte *)0x80400000;
	volatile TIMESTAMP *mtime = (int *)0x0200bff8;

	for(int j = 0; j < 130; j++){ // number of frames
		byte *video_mem = (byte *)0x01000000;
		TIMESTAMP start_time = *mtime;
		for(int i = 0; i < 200*150; i++){
			*(video_mem++) = *(image++);
		}
		TIMESTAMP count = 0;
		while( (count>>3) != 37500 ){
			count = *mtime - start_time;
		}
	}

}