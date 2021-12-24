"""
This script is to:
- Read bad_apple.flv & Write full_10fps.bin (Downloaded from https://www.bilibili.com/video/BV1Wx411c7JT)
- Change fps from 30 to 10
- Change resolution to 200*150
- Convert 256-bit rgb to 8-bit rgb
- Compress each frame by counting number of continuously repeated pixels
"""

import cv2
from progress.bar import Bar

def convert_frame(frame):
	"""Convert 256 bit rgb to 8 bit
	frame: opencv image
	"""
	bytes_int = []
	rows,cols,_ = frame.shape
	for i in range(rows):
		for j in range(cols):
			pixel = frame[i,j]
			eight_bit_pixel = (round(pixel[0]*7/255) << 5) \
							+ (round(pixel[1]*7/255) << 2) \
							+ (round(pixel[2]*3/255))
			bytes_int.append(eight_bit_pixel)
	return bytes(bytes_int)

def compress_frame(frame, frame_size):
	"""Compress one frame
	frame: bytes array containing each pixel's information
	"""
	compressed_int = []
	i = 0
	while True:
		first = frame[i]
		idents = 0
		while i < frame_size and first == frame[i] and idents < 255:
			idents += 1
			i += 1
		compressed_int.append(first)
		compressed_int.append(idents)
		if i == frame_size:
			break
	return bytes(compressed_int)

new_resolution = (200, 150)

def video():
	video = cv2.VideoCapture('bad_apple.flv')
	video.set(cv2.CAP_PROP_FPS, 10)
	with open('full_10fps.bin', 'wb') as f:
		with Bar('video...') as bar:
			i = 0
			while True:
				ret, frame = video.read()
				if not ret:
					break
				# if i >= 300 and i % 3 == 0 and i < 300+3*130: # output 130 frames starting from 300
				if i % 3 == 0: # all frames but 10 fps
					b = cv2.resize(frame, new_resolution, 
						fx=0, fy=0, interpolation=cv2.INTER_CUBIC)
					# cv2.imwrite('one.jpg', b) # save image
					converted_frame = convert_frame(b)
					compressed_frame = compress_frame(converted_frame, new_resolution[0] * new_resolution[1])
					f.write(compressed_frame)
				i += 1
				bar.next()
	video.release()
	cv2.destroyAllWindows()

if __name__ == '__main__':
	video()

