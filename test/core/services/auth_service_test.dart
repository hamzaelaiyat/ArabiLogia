import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arabilogia/core/services/auth_service.dart';
import 'package:arabilogia/core/services/supabase_service_interface.dart';

class _MockSupabaseService extends Mock implements SupabaseServiceInterface {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

User _createUser({String id = 'user_1'}) {
  return User(
    id: id,
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
    email: 'test@example.com',
    role: 'authenticated',
  );
}

Session _createSession({User? user}) {
  return Session(
    accessToken: 'test_access_token',
    tokenType: 'bearer',
    user: user ?? _createUser(),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(OtpType.signup);
    registerFallbackValue(UserAttributes(password: 'fallback'));
  });

  late _MockSupabaseService mockSupabase;
  late _MockGoTrueClient mockAuth;
  late AuthService authService;

  setUp(() {
    mockSupabase = _MockSupabaseService();
    mockAuth = _MockGoTrueClient();
    when(() => mockSupabase.auth).thenReturn(mockAuth);
    authService = AuthService(mockSupabase);
  });

  group('signIn', () {
    test('returns SignInResult on success', () async {
      final user = _createUser();
      final session = _createSession(user: user);
      when(
        () => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => AuthResponse(session: session, user: user),
      );

      final result = await authService.signIn('test@example.com', 'password');

      expect(result.user.id, equals('user_1'));
      expect(result.session.accessToken, equals('test_access_token'));
    });

    test('throws AuthException when user or session is null', () async {
      when(
        () => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => AuthResponse());

      expect(
        () => authService.signIn('test@example.com', 'password'),
        throwsA(isA<AuthException>()),
      );
    });

    test('forwards AuthException from client', () async {
      when(
        () => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthException('Invalid login credentials'));

      expect(
        () => authService.signIn('test@example.com', 'password'),
        throwsA(
          isA<AuthException>().having((e) => e.message, 'message',
              contains('Invalid login credentials')),
        ),
      );
    });

    test('forwards arbitrary exceptions', () async {
      when(
        () => mockAuth.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('Network error'));

      expect(
        () => authService.signIn('test@example.com', 'password'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('signUp', () {
    test('returns SignUpResult with null user when account already exists',
        () async {
      when(
        () => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenThrow(const AuthException('User already registered'));

      final result = await authService.signUp(
        email: 'existing@example.com',
        password: 'password',
        fullName: 'Existing User',
        username: 'existing',
        grade: 1,
      );

      expect(result.alreadyExists, isTrue);
      expect(result.user, isNull);
    });

    test('returns SignUpResult with user on successful signUp', () async {
      when(
        () => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => AuthResponse(user: _createUser(id: 'new_user')),
      );

      final result = await authService.signUp(
        email: 'new@example.com',
        password: 'password',
        fullName: 'New User',
        username: 'newuser',
        grade: 2,
      );

      expect(result.alreadyExists, isFalse);
      expect(result.user, isNotNull);
      expect(result.user!.id, equals('new_user'));
    });

    test('forwards other AuthExceptions from signUp', () async {
      when(
        () => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenThrow(const AuthException('Email not confirmed'));

      expect(
        () => authService.signUp(
          email: 'new@example.com',
          password: 'password',
          fullName: 'New User',
          username: 'newuser',
          grade: 2,
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('forwards arbitrary exceptions from signUp', () async {
      when(
        () => mockAuth.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
          data: any(named: 'data'),
        ),
      ).thenThrow(Exception('Network error'));

      expect(
        () => authService.signUp(
          email: 'new@example.com',
          password: 'password',
          fullName: 'New User',
          username: 'newuser',
          grade: 2,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('verifyEmail', () {
    test('returns VerifyEmailResult on successful signup OTP', () async {
      final user = _createUser();
      final session = _createSession(user: user);
      when(
        () => mockAuth.verifyOTP(
          type: any(named: 'type'),
          token: any(named: 'token'),
          email: any(named: 'email'),
        ),
      ).thenAnswer(
        (_) async => AuthResponse(session: session, user: user),
      );

      final result = await authService.verifyEmail(
          'test@example.com', '123456');

      expect(result.isAuthenticated, isTrue);
      expect(result.user!.id, equals('user_1'));
    });

    test('falls back to email OTP type when signup OTP fails', () async {
      final user = _createUser();
      final session = _createSession(user: user);
      bool signupAttempted = false;
      bool emailAttempted = false;

      when(
        () => mockAuth.verifyOTP(
          type: OtpType.signup,
          token: any(named: 'token'),
          email: any(named: 'email'),
        ),
      ).thenAnswer((_) async {
        signupAttempted = true;
        throw const AuthException('Invalid OTP');
      });
      when(
        () => mockAuth.verifyOTP(
          type: OtpType.email,
          token: any(named: 'token'),
          email: any(named: 'email'),
        ),
      ).thenAnswer((_) async {
        emailAttempted = true;
        return AuthResponse(session: session, user: user);
      });

      final result = await authService.verifyEmail(
          'test@example.com', '123456');

      expect(signupAttempted, isTrue);
      expect(emailAttempted, isTrue);
      expect(result.isAuthenticated, isTrue);
    });

    test('returns unauthenticated result when session is null', () async {
      when(
        () => mockAuth.verifyOTP(
          type: any(named: 'type'),
          token: any(named: 'token'),
          email: any(named: 'email'),
        ),
      ).thenAnswer((_) async => AuthResponse(user: _createUser()));

      final result = await authService.verifyEmail(
          'test@example.com', '123456');

      expect(result.isAuthenticated, isFalse);
      expect(result.user, isNotNull);
    });
  });

  group('resetPassword', () {
    test('completes successfully', () async {
      when(
        () => mockAuth.resetPasswordForEmail(any()),
      ).thenAnswer((_) async {});

      await expectLater(
        authService.resetPassword('test@example.com'),
        completes,
      );
    });

    test('forwards AuthException', () async {
      when(
        () => mockAuth.resetPasswordForEmail(any()),
      ).thenThrow(const AuthException('User not found'));

      expect(
        () => authService.resetPassword('test@example.com'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('verifyResetCode', () {
    test('returns VerifyResetCodeResult on success', () async {
      final user = _createUser();
      final session = _createSession(user: user);
      when(
        () => mockAuth.verifyOTP(
          type: any(named: 'type'),
          token: any(named: 'token'),
          email: any(named: 'email'),
        ),
      ).thenAnswer(
        (_) async => AuthResponse(session: session, user: user),
      );

      final result =
          await authService.verifyResetCode('test@example.com', '123456');

      expect(result.user.id, equals('user_1'));
      expect(result.session.accessToken, equals('test_access_token'));
    });

    test('throws AuthException when user or session is null', () async {
      when(
        () => mockAuth.verifyOTP(
          type: any(named: 'type'),
          token: any(named: 'token'),
          email: any(named: 'email'),
        ),
      ).thenAnswer((_) async => AuthResponse());

      expect(
        () =>
            authService.verifyResetCode('test@example.com', '123456'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('updatePassword', () {
    test('completes successfully', () async {
      when(
        () => mockAuth.updateUser(any()),
      ).thenAnswer((_) async => UserResponse.fromJson({}));

      await expectLater(
        authService.updatePassword('new_password'),
        completes,
      );
    });

    test('forwards AuthException', () async {
      when(
        () => mockAuth.updateUser(any()),
      ).thenThrow(const AuthException('Password too weak'));

      expect(
        () => authService.updatePassword('weak'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('resendOTP', () {
    test('completes successfully with default type', () async {
      when(
        () => mockAuth.resend(
          type: any(named: 'type'),
          email: any(named: 'email'),
        ),
      ).thenAnswer((_) async => ResendResponse());

      await expectLater(
        authService.resendOTP('test@example.com'),
        completes,
      );
    });

    test('completes successfully with custom type', () async {
      when(
        () => mockAuth.resend(
          type: any(named: 'type'),
          email: any(named: 'email'),
        ),
      ).thenAnswer((_) async => ResendResponse());

      await expectLater(
        authService.resendOTP('test@example.com', type: OtpType.email),
        completes,
      );
    });

    test('forwards AuthException', () async {
      when(
        () => mockAuth.resend(
          type: any(named: 'type'),
          email: any(named: 'email'),
        ),
      ).thenThrow(const AuthException('Rate limit exceeded'));

      expect(
        () => authService.resendOTP('test@example.com'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('signOut', () {
    test('completes successfully', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await expectLater(authService.signOut(), completes);
    });
  });
}
