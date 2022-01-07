import 'package:flutter/material.dart';
import 'package:nextsense_trial_ui/ui/session_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Widget _buildBody(BuildContext context) {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Padding(
              padding: EdgeInsets.all(10.0),
              child: ElevatedButton(
                child: const Text('Record a session'),
                onPressed: () async {
                  // Navigate to the session screen.
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => SessionScreen()),
                  );
                },
              )),
        ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
            child: _buildBody(context)
        ),
      ),
    );
  }
}