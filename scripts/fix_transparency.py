from PIL import Image
import sys
import os

def remove_background(image_path, tolerance=30):
    try:
        print(f"Processing {image_path}...")
        img = Image.open(image_path).convert("RGBA")
        datas = img.getdata()
        
        # Get background color from top-left pixel
        bg_color = datas[0]
        print(f"Detected background color: {bg_color}")
        
        newData = []
        for item in datas:
            # Check Euclidean distance or simple difference for tolerance
            if (abs(item[0] - bg_color[0]) < tolerance and 
                abs(item[1] - bg_color[1]) < tolerance and 
                abs(item[2] - bg_color[2]) < tolerance):
                newData.append((255, 255, 255, 0)) # Transparent
            else:
                newData.append(item)
        
        img.putdata(newData)
        img.save(image_path, "PNG")
        print(f"Successfully processed {image_path}")
    except Exception as e:
        print(f"Error processing {image_path}: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python fix_transparency.py <image_path1> <image_path2> ...")
        sys.exit(1)
        
    for path in sys.argv[1:]:
        remove_background(path)
