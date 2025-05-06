# Hệ thống Dependency Injection và Quản lý Dependencies

## Giới thiệu

`AppDependencyManager` là lớp trung tâm quản lý việc khởi tạo và đăng ký tất cả dependencies của ứng dụng Roomily. Lớp này được thiết kế để đơn giản hóa và thống nhất cách đăng ký dependencies, tránh trùng lặp và dư thừa logic.

## Ưu điểm

1. **Quản lý tập trung**: Tất cả logic khởi tạo và đăng ký dependencies tập trung tại một nơi duy nhất
2. **Tránh trùng lặp**: Không đăng ký lại các dependencies đã tồn tại
3. **Chia nhỏ logic**: Phân chia việc khởi tạo thành các giai đoạn riêng biệt, dễ bảo trì
4. **Theo dõi tiến trình**: Cung cấp stream để theo dõi tiến trình khởi tạo
5. **Kiểm soát lỗi**: Xử lý lỗi tốt hơn, logging chi tiết

## Cách sử dụng

### 1. Khởi tạo ban đầu

Trong `main.dart`, khởi tạo `AppDependencyManager` và đăng ký các dependencies cơ bản:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Tạo và đăng ký AppDependencyManager
  final dependencyManager = AppDependencyManager();
  GetIt.I.registerSingleton<AppDependencyManager>(dependencyManager);
  
  // Khởi tạo các dịch vụ cơ bản
  await dependencyManager.initializeCore();
  
  // Bắt đầu khởi tạo đầy đủ trong background
  dependencyManager.initializeAll().then((_) {
    debugPrint('✅ Khởi tạo đầy đủ hoàn tất!');
  });
  
  // ... code tiếp theo
}
```

### 2. Theo dõi tiến trình khởi tạo

Bạn có thể theo dõi tiến trình khởi tạo thông qua stream được cung cấp:

```dart
dependencyManager.initializationProgress.listen(
  (progress) {
    setState(() {
      _progress = progress; // Cập nhật UI hiển thị tiến trình
    });
  },
);
```

### 3. Thêm Dependencies mới

Khi cần thêm dependencies mới vào ứng dụng, thay vì đăng ký chúng ở nhiều nơi khác nhau, hãy cập nhật trong các phương thức tương ứng của `AppDependencyManager`:

- `_registerCoreServices()`: Các services cốt lõi, cần thiết ngay từ đầu
- `_registerRepositories()`: Các repository của ứng dụng
- `_registerServices()`: Các services không phải core
- `_registerBlocs()`: Các BLoC và Cubit

### 4. Truy cập đến Dependencies

Sử dụng GetIt để truy cập đến các dependencies đã đăng ký:

```dart
final userRepository = GetIt.I<UserRepository>();
final authCubit = GetIt.I<AuthCubit>();
```

## Cấu trúc khởi tạo

`AppDependencyManager` chia quá trình khởi tạo thành hai giai đoạn chính:

1. **Core Initialization** (`initializeCore`): Khởi tạo các dependency cốt lõi cần thiết cho ứng dụng hoạt động cơ bản
2. **Full Initialization** (`initializeAll`): Khởi tạo đầy đủ tất cả các dependency của ứng dụng

Cách tiếp cận này giúp ứng dụng có thể hiển thị UI cơ bản trước, trong khi vẫn tiếp tục khởi tạo các dịch vụ còn lại ở background.

## Cách thức mở rộng

Khi cần thêm dependencies mới, hãy:

1. Import package hoặc class cần thiết
2. Thêm vào phương thức `_registerXXX()` phù hợp trong `AppDependencyManager`
3. Đảm bảo sử dụng `_registerIfNotExists()` để tránh đăng ký trùng lặp 