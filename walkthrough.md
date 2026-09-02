# Testbench Toàn Hệ Thống - Century Clock

## File Tạo

- [tb_top_century_clock.v](file:///d:/clock_verify/BT_TKS/simulation/tb_top_century_clock.v) — Testbench cực kì chi tiết cho toàn bộ hệ thống `control_controller`

## Tổng Quan

Testbench bao gồm **40 test case** chia thành nhiều nhóm, kiểm tra từ chức năng cơ bản đến các trường hợp khó nhất.

## Danh Sách Test Cases

| # | Nhóm | Mô tả | Độ khó |
|---|------|-------|--------|
| 1 | Reset | Reset và giá trị khởi tạo (00:00:00, 01/01/2026) | ⭐ |
| 2 | Đếm | Đếm giây tự động, kiểm tra BCD | ⭐ |
| 3 | Carry | Tràn giây 59→00, carry sang phút | ⭐⭐ |
| 4 | Carry | Tràn phút 59→00, carry sang giờ | ⭐⭐ |
| 5 | Carry | Tràn giờ 23→00, carry sang ngày (Midnight) | ⭐⭐ |
| 6 | Carry | Tràn ngày cuối tháng, carry sang tháng (5 sub-test) | ⭐⭐⭐ |
| 7 | Carry | Tràn tháng 12→01, carry sang năm + overflow 9999→1 | ⭐⭐⭐ |
| 8 | Nhuận | Năm nhuận: 2024✓, 2025✗, 1900✗, 2000✓, 2100✗, 2400✓, 4✓, 100✗, 400✓ | ⭐⭐⭐ |
| 9 | Nhuận | Số ngày tối đa trong mỗi tháng (12 tháng + tháng 2 nhuận) | ⭐⭐ |
| 10 | Edit | Chỉnh giây UP/DOWN, wrap-around 59↔0 | ⭐⭐ |
| 11 | Edit | Chỉnh phút UP/DOWN, wrap-around 59↔0 | ⭐⭐ |
| 12 | Edit | Chỉnh giờ UP/DOWN, wrap-around 23↔0 | ⭐⭐ |
| 13 | Edit | Chỉnh ngày DATE mode, wrap-around theo max_day | ⭐⭐⭐ |
| 14 | Edit | Chỉnh tháng UP/DOWN, wrap-around 12↔1 | ⭐⭐ |
| 15 | Edit | Chỉnh năm UP/DOWN, wrap-around 9999↔1, BCD 9999 | ⭐⭐⭐ |
| 16 | Mode | Chuyển đổi TIME↔DATE qua sig_1min | ⭐⭐ |
| 17 | Edit | Đồng hồ dừng khi chỉnh, chạy lại khi thoát, mode không đổi | ⭐⭐⭐ |
| 18 | Blink | Nhấp nháy 7 trường hợp: giây/phút/giờ/ngày/tháng/năm + không chỉnh | ⭐⭐⭐ |
| 19 | Display | Hiển thị 7 đoạn: 12:34:56 TIME + 01/01/2026 DATE | ⭐⭐ |
| 20 | Midnight | Midnight rollover hoàn chỉnh: 23:59:55→00:00:00, ngày+1 | ⭐⭐⭐ |
| 21 | Tháng | Chuyển 10 cặp tháng liên tiếp + cuối năm | ⭐⭐⭐ |
| 22 | Năm | Wrap-around năm 9999→1 qua carry chain, BCD 0001 | ⭐⭐⭐ |
| 23 | Debounce | Nút bấm bounce, nhấn nhanh liên tục | ⭐⭐⭐ |
| 24 | Edge | UP+DOWN đồng thời → UP priority | ⭐⭐⭐ |
| 25 | Edge | Chuyển switch liên tục, priority encoding nhiều switch | ⭐⭐⭐ |
| 26 | Thực tế | Đặt 23:59:57, chờ midnight tự nhiên | ⭐⭐ |
| 27 | Tháng | 31/01→01/02, kiểm tra max_day thay đổi | ⭐⭐ |
| 28 | Edge | Hiệu chỉnh ngày khi day > max_day (31→28) | ⭐⭐⭐ |
| 29 | BCD | Double Dabble: 2026, 1999, 2000, 1, 9999, 1234, 5678 | ⭐⭐⭐ |
| 30 | Priority | Edit field selector: priority encoding cả TIME lẫn DATE | ⭐⭐⭐ |
| 31 | Carry | Full carry chain: giây→phút→giờ→ngày→tháng→năm 1 lần | ⭐⭐⭐ |
| 32 | Liên tục | 65 giây đếm liên tục | ⭐⭐ |
| 33 | Display | Digit selector đúng cho TIME 12:30:45 và DATE 25/11/2026 | ⭐⭐ |
| 34 | Nhuận | Chỉnh ngày tháng 2 năm nhuận: 29 ngày, wrap | ⭐⭐⭐ |
| 35 | Nhuận | Chuyển 2024(nhuận)→2025 với day=29 → tự giảm | ⭐⭐⭐ |
| 36 | Reset | Reset giữa chừng khi đang chỉnh | ⭐⭐ |
| 37 | 7-Seg | Hiển thị từng số 0-9 trên 7-segment | ⭐ |
| 38 | Nhuận | Tháng 2/1900 (chia 100, ko chia 400 → ko nhuận) | ⭐⭐⭐ |
| 39 | Nhuận | Tháng 2/2000 (chia 400 → nhuận): 28→29 ko carry, 29→01/03 carry | ⭐⭐⭐ |
| 40 | Stress | 60 UP/DOWN giây (vòng tròn), 24 UP giờ (vòng tròn) | ⭐⭐ |

## Đặc Điểm Kỹ Thuật

- **Override `clock_divider` parameter** `clk_f=100` để mô phỏng nhanh (thay vì 50MHz)
- **`force`/`release`** để đặt nhanh giá trị counter cho các edge case
- **Task helpers**: `press_btn_up`, `press_btn_down`, `wait_seconds`, `force_time`,...
- **Auto-check**: `check_counter`, `check_bcd`, `check_leap`, `check_blink_mask`, `check_seg_time`
- **Timeout watchdog**: 500ms simulation time
- **Waveform dump**: VCD file cho debug
- **Báo cáo tổng hợp**: PASS/FAIL count tự động

## Cách Chạy (ModelSim/QuestaSim)

```tcl
vlog ../control/top_century_clock.v ../control/*.v ../counter/*.v ../display/*.v tb_top_century_clock.v
vsim -c tb_top_century_clock -do "run -all"
```
