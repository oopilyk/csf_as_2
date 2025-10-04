from PIL import Image

# Create an 8x8 image
img = Image.new('RGB', (4, 4))
pixels = img.load()

# Fill with a simple gradient pattern
for y in range(4):
    for x in range(4):
        pixels[x, y] = (x * 32, y * 32, (x + y) * 16)  # R, G, B values

# Save the image
img.save('test_4x4.png')
print("4x4 PNG saved as test_4x4.png")
