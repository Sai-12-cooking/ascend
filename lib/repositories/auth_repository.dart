import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/player_profile.dart';

class AuthRepository {
  final FirebaseAuth? _firebaseAuth;
  final FirebaseFirestore? _firestore;

  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth,
        _firestore = firestore;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  /// Exposes a stream of authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Gets the currently authenticated user.
  User? get currentUser => _auth.currentUser;

  /// Registers a new user with email, password, and username.
  /// 
  /// On success, automatically triggers the creation of a corresponding
  /// [PlayerProfile] document inside the Firestore collection 'players'.
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
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
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Creates a matching PlayerProfile document inside the Firestore 'players' collection.
  Future<void> _createPlayerProfile(String uid, String username) async {
    final profile = PlayerProfile(
      uid: uid,
      username: username,
    );
    
    await _db
        .collection('players')
        .doc(uid)
        .set(profile.toMap());
  }
}
