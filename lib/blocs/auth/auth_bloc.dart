import 'package:army_ecommerce/blocs/auth/auth_event.dart';
import 'package:army_ecommerce/blocs/auth/auth_state.dart';
import 'package:army_ecommerce/core/constants/response_code.dart';
import 'package:army_ecommerce/core/services/session_manager.dart';
import 'package:army_ecommerce/core/utils/logger.dart';
import 'package:army_ecommerce/repositories/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitial()) {
    // Đăng ký xử lý khi nhận được sự kiện LoginButtonPressed
    on<LoginButtonPressed>((event, emit) async {

      // 1. Chuyển sang trạng thái loading khi bắt đầu đăng nhập
      emit(AuthLoading());

      try {
        // 2. Gọi API đăng nhập thông qua AuthRepository
        final response = await authRepository.login(event.phoneNumber, event.password);

        final responseCode = ResponseCode.fromCode(response.code); // Lấy mã phản hồi từ API

        // 3. Kiểm tra mã phản hồi theo chuẩn API (1000 là OK)
        if (responseCode == ResponseCode.ok && response.data != null) {

          // LƯU VÀO MÁY CỤC BỘ TRƯỚC
          await SessionManager.saveSession(response.data!.token, response.data!.username);

          // 4. Nếu đăng nhập thành công, chuyển sang trạng thái AuthSuccess với dữ liệu người dùng
          emit(AuthSuccess(user: response.data!));
        } else {
          // 5. Nếu mã phản hồi không phải 1000, coi như đăng nhập thất bại
          final errorMessage = response.message.isNotEmpty ? response.message : responseCode.message;
          emit(AuthFailure(error: errorMessage, code: response.code));
        }
      } catch (e) {
        // 6. Nếu có lỗi kết nối hoặc lỗi khác, chuyển sang trạng thái AuthFailure với thông báo lỗi chung
        emit(AuthFailure(error: e.toString(), code: ResponseCode.exception.code));
      }
    });

    on<SignupButtonPressed>((event, emit) async {
      emit(AuthLoading());

      try {
        final response = await authRepository.signup(event.phoneNumber, event.password, event.uuid);

        final responseCode = ResponseCode.fromCode(response.code);

        if (responseCode == ResponseCode.ok) {
          // Đăng ký bước 1 thành công 
          emit(AuthSignupSuccess(phoneNumber: event.phoneNumber));
        } else {
          final errorMessage = response.message.isNotEmpty ? response.message : responseCode.message;
          emit(AuthFailure(error: errorMessage, code: response.code));
        }
      } catch (e) {
        emit(AuthFailure(error: e.toString(), code: ResponseCode.exception.code));
      }
    });

    on<LogoutButtonPressed>((event, emit) async {
      emit(AuthLoading());

      // Bất kể có mạng hay không, xóa sạch bộ nhớ máy
      await SessionManager.clearSession();

      // Thử gọi API để server hủy token cũ
      try {
        await authRepository.logout(event.token);
      } catch (_) {
        // Nếu mất mạng hoặc server chết, đoạn catch này sẽ bắt lỗi.
        // Nhưng KHÔNG emit(AuthFailure) ở đây.
        // Thay vào đó, cố tình bỏ qua để thực hiện bước 3.
      }

      // Luôn luôn báo đăng xuất thành công bất chấp tình trạng mạng
      emit(AuthLogoutSuccess());
    });

    on<VerifyOtpPressed>((event, emit) async {
      emit(AuthLoading()); // Hiển thị trạng thái đang xử lý
      try {
        final response = await authRepository.checkSignupCode(event.phoneNumber, event.code);

        final responseCode = ResponseCode.fromCode(response.code);

        if (responseCode == ResponseCode.ok) {
          // Xác thực OTP thành công -> Cho phép vào trang Home hoặc yêu cầu Login lại
          // Ở đây ta phát trạng thái AuthSuccess để vào thẳng Home
          emit(AuthSuccess(user: response.data!));
        } else {
          final errorMessage = response.message.isNotEmpty ? response.message : responseCode.message;
          emit(AuthFailure(error: errorMessage, code: response.code));
        }
      } catch (e) {
        emit(AuthFailure(error: e.toString(), code: ResponseCode.exception.code));
      }
    });

    on<AppStarted>((event, emit) async {
      // 1. Lấy token đã lưu dưới máy (nếu có)
      final token = await SessionManager.getToken();

      // 2. Nếu không có token -> Chuyển sang trạng thái chưa đăng nhập
      if (token == null || token.isEmpty) {
        emit(Unauthenticated());
        return;
      }

      // 3. Nếu có token, thử gọi API lấy thông tin user để kiểm tra token còn sống không
      try {
        final response = await authRepository.getUserInfo(token);

        final responseCode = ResponseCode.fromCode(response.code);

        if (responseCode == ResponseCode.ok && response.data != null) {
          final user = response.data!.copyWith(token: token);
          // Token hợp lệ -> Chuyển thẳng vào trang Home
          emit(AuthSuccess(user: user));
        } else {
          // Token hết hạn hoặc không hợp lệ -> Xóa rác và yêu cầu login lại
          await SessionManager.clearSession();
          emit(Unauthenticated());
        }
      } catch (e) {
        logger.d("DEBUG: Lỗi Auto Login: $e");
        // Trường hợp mất mạng:
        // Tùy chiến thuật, ta có thể cho vào Home luôn (chế độ offline)
        // hoặc bắt login lại. Ở đây ta tạm cho login lại để an toàn.
        emit(Unauthenticated());
      }
    });

    on<ForgotPasswordRequested>((event, emit) async {
      emit(AuthLoading());

      try {
        final response = await authRepository.createCodeResetPassword(event.phoneNumber);
        final responseCode = ResponseCode.fromCode(response['code']); // response.code

        if (responseCode == ResponseCode.ok) {
          final tempOtp = response['data']['otp'].toString(); //
          // Thành công -> Phát state thông báo mã đã gửi
          emit(ForgotPasswordCodeSent(phoneNumber: event.phoneNumber, otp: tempOtp));
        } else {
          // Thất bại (SĐT chưa đăng ký...) -> Phát state lỗi
          emit(AuthFailure(error: response['message'], code: response['code'])); // response.message // response.code
        }
      } catch (e) {
        emit(AuthFailure(error: e.toString(), code: ResponseCode.exception.code));
      }

    });

    on<VerifyResetCodeRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final response = await authRepository.checkCodeResetPassword(
            event.phoneNumber,
            event.resetCode
        );

        final responseCode = ResponseCode.fromCode(response.code);

        if (responseCode == ResponseCode.ok) {
          // Xác thực mã OK -> Phát state Success để chuyển sang màn đặt Pass mới
          emit(VerifyResetCodeSuccess(phoneNumber: event.phoneNumber, resetCode: event.resetCode));
        } else {
          emit(AuthFailure(error: response.message, code: response.code));
        }
      } catch (e) {
        emit(AuthFailure(error: e.toString(), code: ResponseCode.exception.code));
      }
    });

    on<ResetPasswordRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final response = await authRepository.resetPassword(event.phoneNumber, event.newPassword);
        final responseCode = ResponseCode.fromCode(response.code);

        if (responseCode == ResponseCode.ok && response.data != null) {
          // 1. LƯU TOKEN MỚI VÀO MÁY (Giống hệt logic Login)
          await SessionManager.saveSession(
            response.data!.token,
            response.data!.username,
          );
          emit(ResetPasswordSuccess(user: response.data!));
        } else {
          emit(AuthFailure(error: response.message, code: response.code));
        }
      } catch (e) {
        emit(AuthFailure(error: e.toString(), code: ResponseCode.exception.code));
      }
    });

  }
}

