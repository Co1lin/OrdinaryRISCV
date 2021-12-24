/*
Read from sram, decompress, write to video memory
*/

typedef unsigned char byte;
typedef unsigned int TIMESTAMP;

int t(){
	byte *image = (byte *)0x80400000;
	volatile TIMESTAMP *mtime = (int *)0x0200bff8;

	for(int j = 0; j < 2180; j++){ // number of frames
		byte *video_mem = (byte *)0x01000000;
		
		TIMESTAMP start_time = *mtime;

		while (video_mem != (byte *)0x1007530){
			byte pixel = *(image++);
			byte num = *(image++);
			for(int i = 0; i != num; i++){
				*(video_mem++) = pixel;
			}
		}

		TIMESTAMP count = 0;
		while( (count>>3) != 37500 ){
			/* - mtime: 3MHz, fps: 10
			     => mtime per frame = 1 / fps * mtime = 300,000
			   - mtime is added by 1 every 10 clocks
			   - The loop takes 4 instructions, that's about 6 clock cycles
			   - Thus theoretically a 1-count bias is sufficient
			   - But for safety use 8-count instead
			*/ 
			count = *mtime - start_time;
		}
	}

}