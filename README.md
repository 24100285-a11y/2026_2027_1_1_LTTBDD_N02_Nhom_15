# Học Tốt – Study Planner

## 1. Giới thiệu dự án

**Học Tốt (Study Planner)** là ứng dụng di động hỗ trợ sinh viên quản lý việc học tập cá nhân. Ứng dụng giúp người dùng quản lý môn học, theo dõi bài tập, kiểm soát thời hạn nộp bài và sắp xếp lịch học.

Ứng dụng hướng đến giao diện thân thiện, dễ sử dụng, hỗ trợ hai ngôn ngữ Tiếng Việt và Tiếng Anh. Dữ liệu được lưu trữ cục bộ trên thiết bị, cho phép sử dụng các chức năng chính mà không cần tài khoản hoặc kết nối máy chủ.

## 2. Mục tiêu

- Quản lý danh sách môn học.
- Thêm, chỉnh sửa, tìm kiếm và xóa bài tập.
- Theo dõi trạng thái và thời hạn hoàn thành bài tập.
- Ghi chú cho từng bài tập.
- Sắp xếp và quản lý lịch học cá nhân.
- Thống kê tiến độ hoàn thành bài tập.
- Tự động nhận diện bài tập quá hạn.
- Nhắc nhở thời hạn nộp bài trước một ngày và một giờ.
- Hỗ trợ hai ngôn ngữ: Tiếng Việt và Tiếng Anh.
- Lưu trữ dữ liệu trực tiếp trên thiết bị.

## 3. Chức năng chính

| STT | Chức năng | Mô tả |
|---|---|---|
| 1 | Tổng quan | Hiển thị thông tin và tiến độ học tập |
| 2 | Quản lý môn học | Thêm, sửa, tìm kiếm và xóa môn học |
| 3 | Quản lý bài tập | Thêm, sửa, xóa và tìm kiếm bài tập |
| 4 | Trạng thái bài tập | Theo dõi bài tập đã hoàn thành và chưa hoàn thành |
| 5 | Ghi chú bài tập | Lưu ghi chú cho từng bài tập |
| 6 | Quản lý lịch học | Tạo, chỉnh sửa và xóa lịch học |
| 7 | Thống kê | Tổng hợp số lượng và tỷ lệ hoàn thành bài tập |
| 8 | Nhắc nhở | Nhắc hạn nộp bài tập |
| 9 | Cài đặt | Thay đổi ngôn ngữ và quản lý thông báo |
| 10 | Thông tin dự án | Giới thiệu ứng dụng và công nghệ sử dụng |

## 4. Công nghệ sử dụng

- **Ngôn ngữ lập trình:** Dart.
- **Framework:** Flutter.
- **Giao diện:** Material Design 3.
- **Cơ sở dữ liệu:** SQLite.
- **Thư viện cơ sở dữ liệu:** sqflite.
- **Quản lý trạng thái:** StatefulWidget, ChangeNotifier và AnimatedBuilder.
- **Đa ngôn ngữ:** Flutter localization.
- **Thông báo cục bộ:** flutter_local_notifications.
- **Môi trường phát triển:** Visual Studio Code.
- **Quản lý mã nguồn:** Git và GitHub.

## 5. Cấu trúc dự án

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── app_settings_controller.dart
│   └── theme.dart
├── core/
│   ├── constants/
│   ├── errors/
│   ├── localization/
│   ├── utils/
│   └── validators/
├── data/
│   ├── database/
│   ├── models/
│   ├── repositories/
│   └── services/
└── features/
    ├── dashboard/
    ├── subjects/
    ├── assignments/
    ├── schedules/
    ├── statistics/
    └── settings/
```

## 6. Thành viên thực hiện

| STT |     Họ và tên     | Mã sinh viên |
| --- |        ---        |     ---      |
| 1   | Nguyễn Công Cường |   24100285   |

## 7. Thông tin học phần

- **Trường:** Đại học Phenikaa.
- **Học phần:** Lập trình thiết bị di động.
- **Hình thức thực hiện:** Cá nhân.

## 8. Nền tảng mục tiêu

- Android.

## 9. Cài đặt và chạy dự án

### Yêu cầu môi trường

- Flutter SDK.
- Dart SDK.
- Android Studio hoặc Android SDK.
- Visual Studio Code (khuyến nghị).

### Các bước thực hiện

**Bước 1: Clone repository**

```bash
git clone <GITHUB_REPOSITORY_URL>
```

**Bước 2: Di chuyển vào thư mục dự án**

```bash
cd <PROJECT_FOLDER>
```

**Bước 3: Cài đặt dependencies**

```bash
flutter pub get
```

**Bước 4: Kiểm tra môi trường**

```bash
flutter doctor
```

**Bước 5: Chạy ứng dụng**

```bash
flutter run
```

## 10. Lưu trữ dữ liệu

Ứng dụng sử dụng SQLite để lưu trữ dữ liệu cục bộ trên thiết bị.

Các nhóm dữ liệu chính bao gồm:

- Môn học.
- Bài tập.
- Lịch học.
- Lịch nhắc nhở.
- Cài đặt ứng dụng.

Dữ liệu được quản lý thông qua các lớp Model, Repository và Service nhằm phân tách giao diện, xử lý nghiệp vụ và lưu trữ dữ liệu.

## 11. Trạng thái dự án

Dự án đang trong giai đoạn hoàn thiện và tích hợp các chức năng.

Các nội dung đang được tập trung:

- Hoàn thiện giao diện và điều hướng giữa các màn hình.
- Hoàn thiện trang thống kê và thông tin ứng dụng.
- Rà soát tính nhất quán giữa các chức năng.
- Hoàn thiện tài liệu và chuẩn bị bàn giao.

## 12. Định hướng phát triển

- Tiếp tục cải thiện trải nghiệm người dùng.
- Hoàn thiện các chức năng quản lý học tập.
- Tối ưu khả năng lưu trữ và truy xuất dữ liệu.
- Hoàn thiện xử lý thông báo và nhắc nhở.
- Nâng cao tính ổn định của ứng dụng.

---

**Học Tốt – Study Planner**

*Ứng dụng hỗ trợ quản lý và tổ chức việc học tập cá nhân.*