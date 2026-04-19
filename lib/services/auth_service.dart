import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Iniciar sessão com Google
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Inicia o fluxo de login do Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // O utilizador fechou a janela de login
      }

      // 2. Obtém os detalhes de autenticação do pedido
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // 3. Cria uma nova credencial para o Firebase
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Faz login no Firebase com a credencial
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      return userCredential.user;
    } catch (e) {
      debugPrint("Erro no Google Sign-In: $e");
      return null;
    }
  }

  // Terminar sessão (útil para adicionar às tuas Settings depois)
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
