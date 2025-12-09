from PIL import Image
import re

# --- 설정 ---
COE_FILE_PATH = 'image_out.coe'  # .coe 파일 경로
OUTPUT_IMAGE_PATH = 'restored_image.png' # 저장할 이미지 파일명
IMAGE_WIDTH = 480  # 이미지 가로 크기
IMAGE_HEIGHT = 272 # 이미지 세로 크기
# --- ---

def parse_coe_file(filepath):
    """
    .coe 파일에서 픽셀 데이터(16진수)를 파싱합니다.
    """
    print(f"'{filepath}' 파일 읽는 중...")
    try:
        with open(filepath, 'r') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"오류: '{filepath}' 파일을 찾을 수 없습니다.")
        print("스크립트와 동일한 디렉토리에 .coe 파일을 위치시켜 주세요.")
        return None
    except Exception as e:
        print(f"파일 읽기 오류: {e}")
        return None

    # MEMORY_INITIALIZATION_VECTOR = 다음부터 데이터 추출
    data_match = re.search(r'MEMORY_INITIALIZATION_VECTOR\s*=\s*([\s\S]*);', content, re.IGNORECASE)
    
    if not data_match:
        print("오류: 'MEMORY_INITIALIZATION_VECTOR'를 찾을 수 없습니다.")
        return None

    data_string = data_match.group(1)
    
    # 쉼표, 공백, 줄바꿈을 기준으로 16진수 값들을 분리합니다.
    # 16진수 값(6자리)만 정확히 추출하기 위해 정규식 사용
    hex_values = re.findall(r'([0-9a-fA-F]{6})', data_string)
    
    print(f"총 {len(hex_values)}개의 픽셀 데이터를 찾았습니다.")
    return hex_values

def create_image_from_hex(hex_list, width, height):
    """
    16진수 픽셀 값 리스트로 PIL 이미지를 생성합니다.
    """
    expected_pixels = width * height
    if len(hex_list) != expected_pixels:
        print(f"경고: 데이터 개수({len(hex_list)})가 예상 픽셀 수({expected_pixels})와 일치하지 않습니다.")
        # 데이터가 부족할 경우, 일단 진행하되 예상치 못한 결과가 나올 수 있음
        if len(hex_list) < expected_pixels:
            print("데이터가 부족하여 이미지 일부가 검게 나올 수 있습니다.")
            # 부족한 만큼 검은색(000000)으로 채우기
            hex_list.extend(['000000'] * (expected_pixels - len(hex_list)))
        else:
            # 데이터가 더 많으면 자르기
            print("데이터가 더 많아 일부 데이터가 잘립니다.")
            hex_list = hex_list[:expected_pixels]

    print(f"이미지 생성 중... (크기: {width}x{height})")
    # 새 RGB 이미지 생성
    img = Image.new('RGB', (width, height))
    
    pixel_data = []
    for hex_val in hex_list:
        try:
            # 16진수 문자열을 R, G, B 값(정수)으로 변환
            r = int(hex_val[0:2], 16)
            g = int(hex_val[2:4], 16)
            b = int(hex_val[4:6], 16)
            pixel_data.append((r, g, b))
        except ValueError:
            print(f"경고: 잘못된 16진수 값 '{hex_val}'을 건너뜁니다. (검은색으로 대체)")
            pixel_data.append((0, 0, 0))
    
    # 이미지에 픽셀 데이터 적용
    img.putdata(pixel_data)
    
    return img

def main():
    # 1. COE 파일 파싱
    hex_pixel_data = parse_coe_file(COE_FILE_PATH)
    
    if hex_pixel_data:
        # 2. 이미지 생성
        image = create_image_from_hex(hex_pixel_data, IMAGE_WIDTH, IMAGE_HEIGHT)
        
        # 3. 이미지 저장
        try:
            image.save(OUTPUT_IMAGE_PATH)
            print(f"\n성공! 이미지가 '{OUTPUT_IMAGE_PATH}'로 저장되었습니다.")
            image.show() # 이미지 바로 보기
        except Exception as e:
            print(f"이미지 저장 오류: {e}")

if __name__ == "__main__":
    main()