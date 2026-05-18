from PIL import Image
import numpy as np

def shorten_hand(path, remove_px):
    img = Image.open(path).convert('RGBA')
    arr = np.array(img)
    center_y = arr.shape[0] // 2  # 130
    new_arr = arr.copy()
    new_arr[:remove_px, :, :] = 0
    new_arr[remove_px:center_y, :, :] = arr[:center_y - remove_px, :, :]
    Image.fromarray(new_arr, 'RGBA').save(path)
    print(f"{path}: tip shifted down by {remove_px}px")

base = 'resources/images/'
shorten_hand(base + 'sek.png',  35)
shorten_hand(base + 'min.png',  35)
shorten_hand(base + 'hour.png', 25)
