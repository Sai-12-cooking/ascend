import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_profile.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Exposes a stream of authentication state changes.
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Gets the currently authenticated user.
  User? get currentUser => _firebaseAuth.currentUser;

  /// Registers a new user with email, password, and username.
  /// 
  /// On success, automatically triggers the creation of a corresponding
  /// [PlayerProfile] document inside the Firestore collection 'players'.
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      await _createPlayerProfile(user.uid, username);
    }

    return credential;
  }

  /// Signs in an existing user with email and password.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Creates a matching PlayerProfile document inside the Firestore 'players' collection.
  Future<void> _createPlayerProfile(String uid, String username) async {
    final profile = PlayerProfile(
      uid: uid,
      username: username,
    );
    
    await _firestore
        .collection('players')
        .doc(uid)
        .set(profile.toMap());
  }
}
