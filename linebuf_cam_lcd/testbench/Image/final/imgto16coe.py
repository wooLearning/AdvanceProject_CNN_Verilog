from PIL import Image
import os

# --- 설정 ---
INPUT_IMAGE = 'image.png'        # 변환할 이미지 파일명
OUTPUT_COE = 'image_16bit.coe'   # 생성될 16비트 COE 파일명
TARGET_WIDTH = 480               # 리사이즈할 가로 크기
TARGET_HEIGHT = 272              # 리사이즈할 세로 크기
# -----------

def convert_image_to_16bit_coe():
    print(f"[{INPUT_IMAGE}] 이미지를 엽니다...")
    try:
        img = Image.open(INPUT_IMAGE)
    except FileNotFoundError:
        print(f"오류: '{INPUT_IMAGE}' 파일을 찾을 수 없습니다.")
        return

    # 이미지 크기 변경 (필요한 경우)
    img = img.resize((TARGET_WIDTH, TARGET_HEIGHT))
    img = img.convert('RGB')
    
    pixels = img.load()
    hex_data = []

    print("픽셀 데이터를 16비트로 변환 중...")
    # Verilog 로직에 맞춘 비트 할당:
    # inbuf[4:0]   = Red (5bit)
    # inbuf[10:5]  = Green (6bit)
    # inbuf[15:11] = Blue (5bit)

    for y in range(TARGET_HEIGHT):
        for x in range(TARGET_WIDTH):
            r, g, b = pixels[x, y]

            # 8bit -> 5bit / 6bit로 축소 (상위 비트 사용)
            r5 = (r >> 3) & 0x1F  # 5 bit
            g6 = (g >> 2) & 0x3F  # 6 bit
            b5 = (b >> 3) & 0x1F  # 5 bit

            # 비트 결합 (B가 상위, R이 하위)
            # 순서: [Blue 5bit] [Green 6bit] [Red 5bit]
            pixel_16bit = (b5 << 11) | (g6 << 5) | r5
            
            hex_data.append(f"{pixel_16bit:04X}")

    # COE 파일 작성
    print(f"[{OUTPUT_COE}] 작성 중...")
    with open(OUTPUT_COE, 'w') as f:
        f.write("MEMORY_INITIALIZATION_RADIX = 16;\n")
        f.write("MEMORY_INITIALIZATION_VECTOR =\n")
        
        count = len(hex_data)
        for i, val in enumerate(hex_data):
            end_char = ";" if i == count - 1 else ","
            f.write(f"{val}{end_char}\n")
            
    print("완료! 16비트 COE 파일이 생성되었습니다.")

if __name__ == "__main__":
    convert_image_to_16bit_coe()