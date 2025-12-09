from PIL import Image

# --- 설정 ---
COE_FILE_IN = 'out_rgb565.txt'        # <--- 읽어들일 COE 파일
IMAGE_FILE_OUT = 'restored_image1.png' # <--- 생성할 이미지 파일
IMAGE_WIDTH = 480
IMAGE_HEIGHT = 272
# --- 설정 끝 ---

print("COE 파일(RGB565)로부터 이미지 복원을 시작합니다...")

try:
    # 1. 새 이미지를 생성 (검은색으로 초기화)
    img = Image.new('RGB', (IMAGE_WIDTH, IMAGE_HEIGHT))
    
    # 픽셀 데이터를 저장할 리스트
    pixel_values = []

    # 2. COE 파일 열고 16진수 값만 읽어오기
    with open(COE_FILE_IN, 'r') as f:
        for line in f:
            # 헤더 라인 건너뛰기
            if "RADIX" in line.upper() or "VECTOR" in line.upper():
                continue
            
            # 라인 정리 (공백, 쉼표, 세미콜론 제거)
            hex_val = line.strip().replace(',', '').replace(';', '')
            
            # 빈 줄이 아니면 리스트에 추가
            if hex_val:
                pixel_values.append(hex_val)

    print(f"총 {len(pixel_values)}개의 픽셀 데이터를 읽었습니다.")

    # 3. 픽셀 데이터를 이미지에 매핑
    pixel_index = 0
    total_pixels_expected = IMAGE_WIDTH * IMAGE_HEIGHT
    
    if len(pixel_values) != total_pixels_expected:
        print(f"경고: 픽셀 수가 일치하지 않습니다! (예상: {total_pixels_expected}, 실제: {len(pixel_values)})")

    for y in range(IMAGE_HEIGHT):
        for x in range(IMAGE_WIDTH):
            if pixel_index < len(pixel_values):
                try:
                    # 현재 픽셀의 16진수 값
                    hex_value = pixel_values[pixel_index]
                    
                    # 16진수(RGB565)를 10진수 정수로 변환
                    rgb565 = int(hex_value, 16)
                    
                    # === RGB565를 RGB888(24비트)로 변환 ===
                    # R (상위 5비트): 11111 000000 00000
                    r5 = (rgb565 >> 11) & 0x1F
                    # G (중간 6비트): 00000 111111 00000
                    g6 = (rgb565 >> 5) & 0x3F
                    # B (하위 5비트): 00000 000000 11111
                    b5 = rgb565 & 0x1F
                    
                    # 5비트/6비트 값을 8비트 값으로 스케일링
                    # (x << 3)은 (x * 8)과 비슷하지만, 비트 손실을 보정하기 위해 상위 비트를 복사해주는 것이 좋음
                    r = (r5 << 3) | (r5 >> 2) # 5비트 -> 8비트
                    g = (g6 << 2) | (g6 >> 4) # 6비트 -> 8비트
                    b = (b5 << 3) | (b5 >> 2) # 5비트 -> 8비트
                    # =======================================
                    
                    # 이미지에 픽셀 찍기
                    img.putpixel((x, y), (r, g, b))
                    
                except (ValueError, IndexError) as e:
                    print(f"오류: '{hex_value}' 처리 중 문제 발생 - {e}")
                    img.putpixel((x, y), (255, 0, 255)) # 오류 픽셀 (마젠타)
                
                pixel_index += 1
            else:
                # 데이터가 부족하면 검은색으로 채움
                img.putpixel((x, y), (0, 0, 0)) 

    # 4. 이미지 파일로 저장
    img.save(IMAGE_FILE_OUT)
    
    print(f"'{IMAGE_FILE_OUT}' 이름으로 이미지가 성공적으로 복원되었습니다!")

except FileNotFoundError:
    print(f"오류: '{COE_FILE_IN}' 파일을 찾을 수 없습니다.")
except Exception as e:
    print(f"스크립트 실행 중 오류가 발생했습니다: {e}")