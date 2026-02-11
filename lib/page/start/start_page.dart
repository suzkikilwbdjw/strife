import 'package:flutter/material.dart';
import 'package:strife/page/login/authentication_page.dart';
import 'package:strife/page/register/registration_page.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Добро пожаловать',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Center(
                child: Text(
                  'Strife',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ),
            ),
            const MyContainer(),
          ],
        ),
      ),
    );
  }
}

class MyContainer extends StatelessWidget {
  const MyContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: MediaQuery.sizeOf(context).height * 0.3,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(20),
          right: Radius.circular(20),
        ),
        color: ColorScheme.of(context).onPrimary,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          LoginButton(),
          SizedBox(height: 8),
          RegisterButton(),
          Padding(padding: EdgeInsetsGeometry.symmetric(vertical: 50)),
        ],
      ),
    );
  }
}

class RegisterButton extends StatelessWidget {
  const RegisterButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (context) => RegistrationPage()),
        );
      },
      style: ButtonStyle(
        fixedSize: WidgetStatePropertyAll(
          Size(MediaQuery.sizeOf(context).width * 0.9, 50),
        ),
      ),
      child: const Text('Регистрация', style: TextStyle(fontSize: 20)),
    );
  }
}

class LoginButton extends StatelessWidget {
  const LoginButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (context) => AuthenticationPage()),
        );
      },
      style: ButtonStyle(
        fixedSize: WidgetStatePropertyAll(
          Size(MediaQuery.sizeOf(context).width * 0.9, 50),
        ),
      ),
      child: const Text('Вход', style: TextStyle(fontSize: 20)),
    );
  }
}
