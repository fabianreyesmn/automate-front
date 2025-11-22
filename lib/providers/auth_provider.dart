import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _loading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;
    if (user != null) {
      // Sincronizar con el backend cada vez que el estado de autenticación cambia y hay un usuario.
      // Esto es útil si el token se refresca o en el arranque inicial de la app.
      await _syncUserToBackend(user);
    }
    notifyListeners();
  }

  Future<bool> signInWithEmailPassword(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      // El listener _onAuthStateChanged se encargará del resto.
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        _errorMessage = "Usuario no encontrado.";
      } else if (e.code == 'wrong-password') {
        _errorMessage = "Contraseña incorrecta.";
      } else {
        _errorMessage = "Error al iniciar sesión.";
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createUserWithEmailPassword(String email, String password) async {
    _setLoading(true);
    _clearError();
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      // El listener _onAuthStateChanged se encargará del resto.
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _errorMessage = "El correo ya está en uso.";
      } else if (e.code == 'weak-password') {
        _errorMessage = "La contraseña es muy débil.";
      } else {
        _errorMessage = "Error al registrar el usuario.";
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> _syncUserToBackend(User firebaseUser) async {
    try {
      final idToken = await firebaseUser.getIdToken(true);
      final url = Uri.parse('${dotenv.env['BACKEND_URL']}/api/registerUser');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'email': firebaseUser.email,
          'displayName': firebaseUser.displayName,
        }),
      );

      if (response.statusCode == 200) {
        print('User synced successfully to backend.');
        // Aquí podrías guardar el perfil de usuario que retorna el backend si fuera necesario.
      } else {
        print('Failed to sync user to backend. Status: ${response.statusCode}');
        print('Response: ${response.body}');
      }
    } catch (e) {
      print('Error syncing user to backend: $e');
    }
  }
}
