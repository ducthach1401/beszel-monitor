# Beszel Monitor

Thiết lập `Beszel Hub` và `Beszel Agent` bằng `docker-compose`.

## Thành phần

- `docker-compose.hub.yml`: chạy Beszel Hub
- `docker-compose.agent.yml`: chạy Beszel Agent
- `run-hub.sh`: restart và chạy Hub
- `run-agent.sh`: restart và chạy Agent
- `cleanup-systems.sh`: xóa các máy cũ trên dashboard
- `install-cleanup-cron.sh`: cài cron tự dọn lúc `09:00` mỗi ngày
- `uninstall-cleanup-cron.sh`: gỡ cron tự dọn
- `.env.example`: mẫu biến môi trường

## Yêu cầu

- `docker-compose`
- `bash`
- `python3`
- `tailscale` nếu muốn agent tự đặt tên theo `Tailscale HostName`

## Cấu hình

Tạo file `.env`:

```bash
cp .env.example .env
```

Nội dung mẫu:

```env
APP_URL=http://10.10.0.2:8090
BESZEL_PORT=8090

HUB_URL=http://10.10.0.2:8090
AGENT_TOKEN=replace-with-universal-token
AGENT_KEY=replace-with-agent-public-key
```

## Chạy Hub

```bash
./run-hub.sh
```

Sau khi chạy, mở dashboard tại:

```text
http://10.10.0.2:8090
```

Nếu public dashboard qua reverse proxy thì nên đặt `APP_URL` thành URL public, ví dụ:

```env
APP_URL=https://monitor.example.com
```

## Chạy Agent

Trong Hub:

1. Mở `Settings -> Tokens`
2. Tạo hoặc copy `universal token`
3. Lấy `AGENT_KEY` trong phần thêm system/agent của Hub

Cập nhật `.env`, sau đó chạy:

```bash
./run-agent.sh
```

## SYSTEM_NAME

`run-agent.sh` sẽ tự đặt `SYSTEM_NAME` theo thứ tự:

1. `SYSTEM_NAME` trong `.env` nếu bạn tự khai báo
2. `Self.HostName` từ `tailscale status --json`
3. `hostname` của máy nếu không có Tailscale

## Lưu ý

- Agent đang chạy với `DISABLE_SSH=true`, tức là dùng `HUB_URL` để kết nối outbound về Hub
- `HUB_URL` có thể để nội bộ qua Tailscale
- `APP_URL` nên là URL public nếu dashboard đi qua Nginx Proxy Manager hoặc reverse proxy khác

## Xóa máy cũ trên dashboard

Script `cleanup-systems.sh` sẽ tìm các system có `status != up` và `updated` cũ hơn số ngày bạn chỉ định, sau đó xóa trực tiếp trong DB của Beszel.

Chạy thử không xóa:

```bash
./cleanup-systems.sh
```

Xóa thật:

```bash
./cleanup-systems.sh --apply
```

Bật tự động dọn lúc `09:00` mỗi ngày:

```bash
./install-cleanup-cron.sh
```

Gỡ lịch tự động dọn:

```bash
./uninstall-cleanup-cron.sh
```

Lưu ý:

- Script chỉ xóa record trong bảng `systems`
- Mặc định dùng Docker volume `beszel_data`
- Nếu thấy lỗi bảng `systems` không tồn tại, thường là do Hub chưa khởi tạo DB hoặc volume đang trỏ sai
- Nếu agent cũ vẫn còn chạy với token hợp lệ, nó có thể tự đăng ký lại
- Log cron được ghi vào `cleanup-systems.log`

## Lệnh hữu ích

Xem log Hub:

```bash
docker logs -f beszel
```

Xem log Agent:

```bash
docker logs -f beszel-agent
```

Dừng Hub:

```bash
docker-compose -f docker-compose.hub.yml down
```

Dừng Agent:

```bash
docker-compose -f docker-compose.agent.yml down
```
