import re
import os

# --- 설정 ---
INPUT_COE = 'image_16bit.coe'          # 위에서 만든 16비트 파일
OUTPUT_COE = 'image_restored_24bit.coe' # 결과 24비트 COE 파일
# -----------

def simulate_verilog_logic():
    if not os.path.exists(INPUT_COE):
        print(f"오류: '{INPUT_COE}' 파일이 없습니다. 1번 코드를 먼저 실행하세요.")
        return

    print(f"[{INPUT_COE}] 읽는 중...")
    with open(INPUT_COE, 'r') as f:
        content = f.read()

    # 데이터 벡터 파싱
    match = re.search(r'MEMORY_INITIALIZATION_VECTOR\s*=\s*([\s\S]*?);', content, re.IGNORECASE)
    if not match:
        print("COE 포맷 오류: 데이터 벡터를 찾을 수 없습니다.")
        return

    # 콤마, 공백 등으로 분리
    hex_list = [x.strip() for x in re.split(r'[,\s]+', match.group(1)) if x.strip()]
    
    new_hex_data = []
    print(f"Verilog 로직 시뮬레이션 중... (총 {len(hex_list)}개)")

    for hex_val in hex_list:
        val_16 = int(hex_val, 16)
        
        # === Verilog 로직 구현 ===
        # assign wPixel = {
        #    {inbuf[4:0],   inbuf[4:2]},    // Red
        #    {inbuf[10:5],  inbuf[10:9]},   // Green
        #    {inbuf[15:11], inbuf[15:13]}   // Blue
        # };
        
        # 1. 비트 슬라이싱 (16비트 데이터에서 추출)
        r_slice = val_16 & 0x1F           # [4:0]
        g_slice = (val_16 >> 5) & 0x3F    # [10:5]
        b_slice = (val_16 >> 11) & 0x1F   # [15:11]
        
        # 2. 비트 확장 (Concatenation)
        # Red: 5bit + 상위 3bit
        # (r_slice >> 2)가 상위 3비트에 해당
        r_8 = (r_slice << 3) | (r_slice >> 2)
        
        # Green: 6bit + 상위 2bit
        # (g_slice >> 4)가 상위 2비트에 해당
        g_8 = (g_slice << 2) | (g_slice >> 4)
        
        # Blue: 5bit + 상위 3bit
        # (b_slice >> 2)가 상위 3비트에 해당
        b_8 = (b_slice << 3) | (b_slice >> 2)
        
        # 3. 24비트로 합치기 (RGB888)
        pixel_24 = (r_8 << 16) | (g_8 << 8) | b_8
        new_hex_data.append(f"{pixel_24:06X}")

    # 24비트 COE 파일 저장
    print(f"[{OUTPUT_COE}] 생성 중...")
    with open(OUTPUT_COE, 'w') as f:
        f.write("MEMORY_INITIALIZATION_RADIX = 16;\n")
        f.write("MEMORY_INITIALIZATION_VECTOR =\n")
        
        count = len(new_hex_data)
        for i, val in enumerate(new_hex_data):
            end_char = ";" if i == count - 1 else ","
            f.write(f"{val}{end_char}\n")
            
    print("완료! 24비트 복원 COE 파일이 생성되었습니다.")

if __name__ == "__main__":
    simulate_verilog_logic()