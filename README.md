# Cyber City

Cyber City 是一個以 Verilog 實作的閉環資源經濟系統。專案模擬一座城市中六個部門之間的資源轉換與握手傳輸，所有資源交換都透過 `valid && ready` 在時脈邊緣完成。

## 目錄

- [專案目錄](#專案目錄)
- [系統架構](#系統架構)
- [資源流向](#資源流向)
- [模組職責](#模組職責)
- [檔案說明](#檔案說明)
- [執行模擬](#執行模擬)

## 專案目錄

```text
cybercity/
|-- README.md
|-- Cyber City.pdf
|-- Cyber City.md
|-- Hint.txt
|-- src/
|   |-- city_define.vh
|   |-- department.v
|   |-- government.v
|   |-- resource_router4.v
|   `-- cyber_city_top.v
`-- tb/
    `-- tb_cyber_city.v
```

## 系統架構

Cyber City 採用閉環經濟架構。每個部門都是暫存器化的生產者/消費者模組，上游只有在 `valid` 與 `ready` 同時為高時，才會把資源送入下游。這樣可以避免純組合邏輯串接造成握手迴圈，也能在資源滿載時自然形成 back-pressure。

```text
                    稅收
        +--------------------------+
        |                          v
+----------------+       +----------------+
|    商業區      |       |   中央政府     |
|  產生資金      |       |  資金仲裁器    |
+----------------+       +----------------+
      ^   ^   ^             |        |
      |   |   |             |        |
      |   |   |             v        v
      |   |   |        +--------+ +--------+
      |   |   +--------| 發電廠 | | 淨水廠 |
      |   |      電力  +--------+ +--------+
      |   |                 |        |
      |   |                 v        v
      |   |              資源路由器
      |   |                 |        |
      |   +-----------------+        |
      | 勞動力                       水
      |                              |
+-------------+    勞動力     +-------------+
|   住宅區    |-------------->|  重工業區   |
|  產生勞動力 |               |  產生物資   |
+-------------+               +-------------+
                                      |
                                      v
                                    商業區
```

## 資源流向

整合後的 `cyber_city_top` 將六個邏輯部門接成題目要求的經濟循環：

1. 中央政府分配資金給發電廠與淨水廠。
2. 發電廠消耗資金與水，產生電力。
3. 淨水廠消耗資金與電力，產生水。
4. 住宅區消耗水與電力，產生勞動力。
5. 重工業區消耗電力與勞動力，產生工業物資。
6. 商業區消耗工業物資、電力與勞動力，產生稅收並回流中央政府。

共享資源由暫存器化 round-robin 路由器分配：

- 電力分配給淨水廠、住宅區、重工業區、商業區。
- 水分配給發電廠、住宅區。
- 勞動力分配給重工業區、商業區。
- 工業物資分配給商業區。

## 模組職責

- `cyber_city_top`：整合所有部門與資源路由器，是整座城市的 Top Module。
- `government`：保存城市資金，接收商業區稅收，並以註冊握手介面分配資金。
- `department`：通用生產部門，供發電廠、淨水廠、住宅區、重工業區與商業區共用。
- `resource_router4`：單一輸入、四個輸出的 round-robin `valid/ready` 路由器。
- `city_define.vh`：集中定義資料寬度、初始資源、FSM 狀態與資源上限。
- `tb_cyber_city`：同時測試新手模式、專家模式與 6-2 挑戰模式，連續模擬 1000 個 clock，若任一模組進入 `S_DEAD` 則測試失敗。

## 檔案說明

- `src/city_define.vh`：共用常數與 FSM 狀態定義。
- `src/department.v`：具備 `valid/ready` 握手機制的通用生產部門。
- `src/government.v`：中央政府資金仲裁器。
- `src/resource_router4.v`：round-robin 資源路由器。
- `src/cyber_city_top.v`：城市整合層。
- `tb/tb_cyber_city.v`：三種驗收模式的模擬測試平台。

## 執行模擬

```powershell
iverilog -g2012 -I src -o cyber_city_tb.vvp src/department.v src/government.v src/resource_router4.v src/cyber_city_top.v tb/tb_cyber_city.v
vvp cyber_city_tb.vvp
```

預期最後會看到：

```text
通過：Cyber City 在所有模式下都存活 1000 個 clock。
```
