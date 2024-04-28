import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'firebase_options.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArtFolio',
      home: MyHomePage(title: 'Explore'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoggedIn = false;
  bool _showArtworks = false;

  void _updateAuthState(User? user) {
    setState(() {
      _isLoggedIn = user != null;
    });
  }

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((User? user) => _updateAuthState(user));
  }

  void _signOut() async {
    await _auth.signOut();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Signed out successfully'),
    ));
  }

  void _exploreArtworks() {
    setState(() {
      _showArtworks = true;
    });
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfileScreen()),
    );
  }

  void _navigateToUploadScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UploadScreen()),
    );
  }

  void _showChatScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          backgroundColor: const Color.fromARGB(255, 203, 203, 203),
          actions: <Widget>[
            ElevatedButton(
              onPressed: _signOut,
              child: Text('Sign Out'),
            ),
          ],
        ),
        body: Center(
          child: _showArtworks ? _buildArtworksGridView() : Container(),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: BottomAppBar(
          color: Color.fromARGB(255, 203, 203, 203),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.featured_play_list),
                onPressed: _showChatScreen,
              ),
              IconButton(
                icon: Icon(Icons.explore),
                onPressed: _exploreArtworks,
              ),
              IconButton(
                icon: Icon(Icons.cloud_upload),
                onPressed: _navigateToUploadScreen,
              ),
              IconButton(
                icon: Icon(Icons.account_circle),
                onPressed: _navigateToProfile,
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              EmailPasswordForm(auth: _auth),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpPage()),
                  );
                },
                child: Text('Are you new? Register here'),
              ),
            ],
          ),
        ),
      );
    }
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<String> messages = [];

  void addMessage(String message) {
    setState(() {
      messages.add(message);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Messages'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Align(
                    alignment: messages[index].startsWith('You: ')
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      decoration: BoxDecoration(
                        color: messages[index].startsWith('You: ')
                            ? Colors.blue
                            : Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.all(10),
                      child: Text(
                        messages[index],
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                    ),
                    onSubmitted: (value) {
                      addMessage('You: $value');
                    },
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () {
                    addMessage('You: ${messages.length}');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RegisterEmailSection extends StatefulWidget {
  RegisterEmailSection({Key? key, required this.auth}) : super(key: key);
  final FirebaseAuth auth;

  @override
  _RegisterEmailSectionState createState() => _RegisterEmailSectionState();
}

class _RegisterEmailSectionState extends State<RegisterEmailSection> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _success = false;
  bool _initialState = true;
  String? _userEmail;

  void _register() async {
    try {
      await widget.auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(_emailController.text)
          .set({
        'email': _emailController.text,
        'password': _passwordController.text,
      });

      setState(() {
        _success = true;
        _userEmail = _emailController.text;
        _initialState = false;
      });
    } catch (e) {
      setState(() {
        _success = false;
        _initialState = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            child: Text('Are you new here? Register Today!'),
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
          ),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter some text';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: 'Password'),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter some text';
              }
              return null;
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            alignment: Alignment.center,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _register();
                }
              },
              child: Text('Submit'),
            ),
          ),
          Container(
            alignment: Alignment.center,
            child: Text(
              _initialState
                  ? ''
                  : _success
                      ? 'Successfully registered $_userEmail'
                      : 'Registration failed',
              style: TextStyle(color: _success ? Colors.green : Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class EmailPasswordForm extends StatefulWidget {
  EmailPasswordForm({Key? key, required this.auth}) : super(key: key);
  final FirebaseAuth auth;

  @override
  _EmailPasswordFormState createState() => _EmailPasswordFormState();
}

class _EmailPasswordFormState extends State<EmailPasswordForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _success = false;
  bool _initialState = true;
  String _userEmail = '';

  void _signInWithEmailAndPassword() async {
    try {
      await widget.auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      setState(() {
        _success = true;
        _userEmail = _emailController.text;
        _initialState = false;
      });
    } catch (e) {
      setState(() {
        _success = false;
        _initialState = false;
      });
    }
  }

  void _resetPassword() async {
    try {
      await widget.auth.sendPasswordResetEmail(email: _emailController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent. Please check your inbox.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending password reset email.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            child: Text('Welcome Back Login Now!'),
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
          ),
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter some text';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: 'Password'),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter some text';
              }
              return null;
            },
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            alignment: Alignment.center,
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _signInWithEmailAndPassword();
                }
              },
              child: Text('Login'),
            ),
          ),
          Container(
            alignment: Alignment.center,
            child: Text(
              _initialState
                  ? ''
                  : _success
                      ? 'Successfully signed in $_userEmail'
                      : 'Sign in failed',
              style: TextStyle(color: _success ? Colors.green : Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _resetPassword();
            },
            child: Text('Forgot Password'),
          ),
        ],
      ),
    );
  }
}

Widget _buildArtworksGridView() {
  List<String> imagePaths = [
    'assets/art1.jpg',
    'assets/art2.jpg',
    'assets/art3.jpg',
    'assets/art4.jpg',
    'assets/art5.jpg',
    'assets/art6.jpg',
  ];
  List<String> artworkNames = [
    'Colored Dog',
    'Glass Half Sideways',
    'Childhood Home',
    'Frida Kahlo',
    'Picasso',
    'Lion',
  ];
  List<String> artistNames = [
    'Samantha X',
    'Richard D',
    'Micheal M',
    'Megan F',
    'Blake G',
    'Isabel M',
  ];
  List<String> descriptions = [
    ' A vibrant portrait capturing the essence of a colorful canine companion.',
    ' An abstract depiction of a tilted glass, presenting an unconventional perspective on everyday objects.',
    'A nostalgic portrayal evoking memories of the artists early years and the warmth of home.',
    'A tribute to the iconic Mexican artist, reflecting her distinctive style and indomitable spirit.',
    'An artistic homage inspired by the avant-garde works of the renowned Spanish painter, Pablo Picasso.',
    'An artistic homage inspired by the avant-garde works of the renowned Spanish painter, Pablo Picasso.',
  ];

  return Container(
    color: Color.fromARGB(223, 209, 207, 207),
    child: GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: imagePaths.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ArtworkDetailScreen(
                  artworkName: artworkNames[index],
                  artistName: artistNames[index],
                  description: descriptions[index],
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(imagePaths[index]),
                fit: BoxFit.cover,
              ),
            ),
            alignment: Alignment.center,
          ),
        );
      },
    ),
  );
}

class ArtworkDetailScreen extends StatelessWidget {
  final String artworkName;
  final String artistName;
  final String description;

  ArtworkDetailScreen({
    required this.artworkName,
    required this.artistName,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Artwork Detail'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              artworkName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'By $artistName',
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatScreen()),
                );
              },
              child: Text('Message Me'),
            ),
          ],
        ),
      ),
    );
  }
}
