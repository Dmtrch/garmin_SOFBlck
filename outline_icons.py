from PIL import Image
import numpy as np

img = Image.open('resources/images/Background_full.png').convert('RGBA')
arr = np.array(img, dtype=np.uint8)

r, g, b, a = arr[:,:,0].astype(int), arr[:,:,1].astype(int), arr[:,:,2].astype(int), arr[:,:,3].astype(int)

# Pictogram pixels: bright (white icons) with any visibility
bright = (r + g + b) / 3
picto_mask = (bright > 200) & (a > 30)

# 8-connected dilation by 1 pixel
dilated = np.zeros_like(picto_mask)
dilated[:-1, :-1] |= picto_mask[1:, 1:]
dilated[:-1,  : ] |= picto_mask[1:,  : ]
dilated[:-1,  1:] |= picto_mask[1:, :-1]
dilated[ : , :-1] |= picto_mask[ : , 1:]
dilated[ : ,  1:] |= picto_mask[ : , :-1]
dilated[ 1:, :-1] |= picto_mask[:-1, 1:]
dilated[ 1:,  : ] |= picto_mask[:-1,  : ]
dilated[ 1:,  1:] |= picto_mask[:-1, :-1]

# Border = dilated AND NOT original pictogram pixels
border = dilated & ~picto_mask

arr[border, 0] = 255
arr[border, 1] = 255
arr[border, 2] = 255
arr[border, 3] = 255

Image.fromarray(arr, 'RGBA').save('resources/images/Background_full.png')
print(f"Added white outline: {np.sum(border)} border pixels")
