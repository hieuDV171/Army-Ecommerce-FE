import 'package:army_ecommerce/blocs/auth/auth_event.dart';
import 'package:army_ecommerce/blocs/auth/auth_state.dart';
import 'package:army_ecommerce/core/constants/response_code.dart';
import 'package:army_ecommerce/core/services/session_manager.dart';
import 'package:army_ecommerce/core/utils/logger.dart';
import 'package:army_ecommerce/repositories/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

          // LƯU VÀO MÁY CỤC BỘ TRƯỚC (lưu token, username, phoneNumber nếu có)
          await SessionManager.saveSession(response.data!.token, response.data!.username, event.phoneNumber); // :)))

          // Lưu avatar từ API response
          if (response.data!.avatar != null && response.data!.avatar!.isNotEmpty) {
            await SessionManager.setAvatar(response.data!.avatar!);
          }
          logger.i('Login: saved session for username="${response.data!.username}" phone="${event.phoneNumber}"');

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
      logger.i('DEBUG LOGOUT BLOC: Received LogoutButtonPressed event, token="${event.token}"');
      emit(AuthLoading());

      // 1. Gửi request gọi API logout chạy ngầm mà không await để tránh treo UI
      if (event.token.isNotEmpty) {
        logger.i('DEBUG LOGOUT BLOC: Requesting backend logout...');
        authRepository.logout(event.token).then((_) {
          logger.i('DEBUG LOGOUT BLOC: Backend logout request succeeded.');
        }).catchError((e) {
          logger.e('DEBUG LOGOUT BLOC: Backend logout request failed: $e');
          return null;
        });
      } else {
        logger.w('DEBUG LOGOUT BLOC: Token is empty, skipping backend logout request.');
      }

      // 2. Xóa session local lập tức và chuyển trạng thái thành công
      logger.i('DEBUG LOGOUT BLOC: Clearing local session via SessionManager...');
      await SessionManager.clearSession();
      logger.i('DEBUG LOGOUT BLOC: Local session cleared successfully. Emitting AuthLogoutSuccess.');
      emit(AuthLogoutSuccess());
    });

    on<VerifyOtpPressed>((event, emit) async {
      emit(AuthLoading()); // Hiển thị trạng thái đang xử lý
      try {
        final response = await authRepository.checkSignupCode(event.phoneNumber, event.code);

        final responseCode = ResponseCode.fromCode(response.code);

        if (responseCode == ResponseCode.ok) {
          // Xác thực OTP thành công -> Lưu session (nếu BE trả token) rồi vào Home
          if (response.data != null) {
            await SessionManager.saveSession(response.data!.token, response.data!.username, event.phoneNumber);

            // Lưu avatar từ API response
            if (response.data!.avatar != null && response.data!.avatar!.isNotEmpty) {
              await SessionManager.setAvatar(response.data!.avatar!);
            }
            logger.i('VerifyOtp: saved session for username="${response.data!.username}" phone="${event.phoneNumber}"');
          }
          // Phát state để vào Home
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
      logger.d('AutoLogin: token from SessionManager: ${token != null ? "[REDACTED]" : "null"}');

      // 2. Nếu không có token -> Chuyển sang trạng thái chưa đăng nhập
      if (token == null || token.isEmpty) {
        logger.i('AutoLogin: no token found -> Unauthenticated');
        emit(Unauthenticated());
        return;
      }

      // 3. Nếu có token, thử gọi API lấy thông tin user để kiểm tra token còn sống không
        try {
         final prefs = await SharedPreferences.getInstance();
         final localUsername = prefs.getString('username') ?? '';
         final localPhone = prefs.getString('phone_number') ?? '';
         logger.d('AutoLogin: local username from SharedPreferences: "$localUsername" phone="$localPhone"');

        final response = await authRepository.getUserInfo(token: token);
        logger.d('AutoLogin: getUserInfo response code=${response.code}, data=${response.data}');

        final responseCode = ResponseCode.fromCode(response.code);

         if (responseCode == ResponseCode.ok && response.data != null) {
           // Nếu API không trả username, dùng username lưu local làm fallback
           final apiUsername = response.data!.username;
           final usernameToUse = apiUsername.isNotEmpty ? apiUsername : localUsername;
           if (apiUsername.isEmpty && localUsername.isNotEmpty) {
             logger.w('AutoLogin: API returned empty username -> using local username "$localUsername"');
           } else {
             logger.d('AutoLogin: using username from API: "$apiUsername"');
           }

           // Lấy avatar từ local storage nếu API không trả
           final localAvatar = await SessionManager.getAvatar();
           final avatarToUse = (response.data!.avatar != null && response.data!.avatar!.isNotEmpty)
               ? response.data!.avatar
               : localAvatar;

           // Lưu avatar lại nếu API trả về
           if (response.data!.avatar != null && response.data!.avatar!.isNotEmpty) {
             await SessionManager.setAvatar(response.data!.avatar!);
           }

           final user = response.data!.copyWith(
             token: token,
             username: usernameToUse,
             avatar: avatarToUse,
           );
           // Token hợp lệ -> Chuyển thẳng vào trang Home
           emit(AuthSuccess(user: user));
        } else {
          logger.w('AutoLogin: token invalid or response not OK -> clearing session. response.code=${response.code}');
          // Token hết hạn hoặc không hợp lệ -> Xóa rác và yêu cầu login lại
          await SessionManager.clearSession();
          emit(Unauthenticated());
        }
      } catch (e) {
        logger.e("DEBUG: Lỗi Auto Login: $e");
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
            event.phoneNumber,
          );

          // Lưu avatar từ API response
          if (response.data!.avatar != null && response.data!.avatar!.isNotEmpty) {
            await SessionManager.setAvatar(response.data!.avatar!);
          }
          logger.i('ResetPassword: saved session for username="${response.data!.username}" phone="${event.phoneNumber}"');

          emit(ResetPasswordSuccess(user: response.data!));
        } else {
          emit(AuthFailure(error: response.message, code: response.code));
        }
      } catch (e) {
        emit(AuthFailure(error: e.toString(), code: ResponseCode.exception.code));
      }
    });

    on<ChangePasswordRequested>((event, emit) async {
      emit(AuthLoading());

      try {
        final response = await authRepository.changePassword(
            oldPassword: event.oldPassword,
            newPassword: event.newPassword
        );

        final responseCode = ResponseCode.fromCode(response.code);

        if (responseCode == ResponseCode.ok) {
          emit(ChangePasswordSuccess());
        } else {
          emit(AuthFailure(error: response.message, code: response.code));
        }
      } catch (e) {
        emit(AuthFailure(error: e.toString(), code: ResponseCode.exception.code));
      }
    });

    on<VerifyOldPasswordRequested>((event, emit) async {
      emit(AuthLoading());
        try {
        // Lấy SĐT từ SessionManager (phone stored under phone_number)
        final prefs = await SharedPreferences.getInstance();
        final phone = prefs.getString('phone_number') ?? "";

        // Gọi API Login để kiểm tra mật khẩu cũ
        final response = await authRepository.login(phone, event.oldPassword);
        final responseCode = ResponseCode.fromCode(response.code);

        if (responseCode == ResponseCode.ok) {
          emit(OldPasswordVerifySuccess()); // Mật khẩu cũ đúng
        } else {
          emit(AuthFailure(error: response.message, code: response.code));
        }
      } catch (e) {
        emit(AuthFailure(error: e.toString(), code: ResponseCode.exception.code));
      }
    });

    on<ChangeInfoRequested>((event, emit) async {
      emit(AuthLoading());

      try {
        final response = await authRepository.changeInfoAfterSignup(
          username: event.username,
          avatarFile: event.avatarFile,
        );

        final responseCode = ResponseCode.fromCode(response.code);
        if (responseCode == ResponseCode.ok && response.data != null) {
           // Cập nhật lại username và avatar trong bộ nhớ tạm
           await SessionManager.setUsername(response.data!.username);
           if (response.data!.avatar != null && response.data!.avatar!.isNotEmpty) {
             await SessionManager.setAvatar(response.data!.avatar!);
           }

           emit(ChangeInfoSuccess(updatedUser: response.data!));

           // Phát tiếp AuthSuccess để đồng bộ trạng thái hệ thống và tự động chuyển sang HomeScreen
           final token = await SessionManager.getToken() ?? '';
           final userWithToken = response.data!.copyWith(token: token, active: 1);
           emit(AuthSuccess(user: userWithToken));
        } else {
          emit(AuthFailure(error: response.message, code: response.code));
        }
      } catch (e) {
        emit(AuthFailure(error: e.toString(), code: ResponseCode.exception.code));
      }
    });

    on<GetUserInfoRequested>((event, emit) async {
      emit(GetUserInfoLoading());

      try {
        final token = await SessionManager.getToken();
        if (token == null || token.isEmpty) {
          emit(GetUserInfoFailure(
            error: ResponseCode.tokenInvalid.message,
            code: ResponseCode.tokenInvalid.code,
          ));
          return;
        }

        final userId = event.userId;
        final response = await authRepository.getUserInfo(
          token: token,
          userId: userId,
        );
        logger.d('GetUserInfo: response code=${response.code}, data=${response.data}');

        final responseCode = ResponseCode.fromCode(response.code);

        if (responseCode == ResponseCode.ok && response.data != null) {
          emit(GetUserInfoSuccess(user: response.data!));
        } else {
          emit(GetUserInfoFailure(
            error: response.message.isNotEmpty ? response.message : responseCode.message,
            code: response.code,
          ));
        }
      } catch (e) {
        emit(GetUserInfoFailure(
          error: e.toString(),
          code: ResponseCode.exception.code,
        ));
      }
    });


    on<SetUserInfoRequested>((event, emit) async {
      emit(SetUserInfoLoading());

      try {
        final response = await authRepository.setUserInfo(
          currentUser: event.currentUser,
          email: event.email,
          username: event.username,
          status: event.status,
          avatarFile: event.avatarFile,
          firstName: event.firstName,
          lastName: event.lastName,
          address: event.address,
          password: event.password,
          coverImageFile: event.coverImageFile,
          coverImageWebFile: event.coverImageWebFile,
        );

        final responseCode = ResponseCode.fromCode(response.code);
        if (responseCode == ResponseCode.ok && response.data != null) {
          final updatedUser = response.data!;

          if (updatedUser.username.isNotEmpty) {
            await SessionManager.setUsername(updatedUser.username);
          }
          if (updatedUser.avatar != null && updatedUser.avatar!.isNotEmpty) {
            await SessionManager.setAvatar(updatedUser.avatar!);
          }

          emit(SetUserInfoSuccess(user: updatedUser));
        } else {
          emit(SetUserInfoFailure(
            error: response.message.isNotEmpty ? response.message : responseCode.message,
            code: response.code,
          ));
        }
      } catch (e) {
        emit(SetUserInfoFailure(
          error: e.toString(),
          code: ResponseCode.exception.code,
        ));
      }
    });

  }
}
