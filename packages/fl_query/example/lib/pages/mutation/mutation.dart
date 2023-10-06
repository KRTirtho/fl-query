import 'package:fl_query/fl_query.dart';
import 'package:flutter/material.dart';

class MutationPage extends StatefulWidget {
  const MutationPage({super.key});

  @override
  State<MutationPage> createState() => _MutationPageState();
}

class _MutationPageState extends State<MutationPage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mutation'),
      ),
      body: MutationBuilder<Map<String, dynamic>, dynamic, Map<String, dynamic>,
          dynamic>(
        'sign-up',
        (variables) {
          return Future.delayed(
            const Duration(seconds: 5),
            () => {
              'name': variables['name'],
              'email': variables['email'],
              'password': variables['password'],
            },
          );
        },
        onMutate: (variables) {
          debugPrint('onMutate: $variables');
          return "Recover ME";
        },
        onData: (data, recoveryData) {
          debugPrint('onData: $data');
          debugPrint('recoveryData: $recoveryData');
        },
        refreshQueries: const ['hello'],
        builder: (context, mutation) {
          if (mutation.hasData) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Text('Welcome ${mutation.data!['name']}'),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text('Your email is ${mutation.data!['email']}'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    mutation.reset();
                  },
                  child: const Text('Log out'),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _nameController,
                keyboardType: TextInputType.name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  await mutation.mutate({
                    'name': _nameController.text,
                    'email': _emailController.text,
                    'password': _passwordController.text,
                  });
                },
                child: mutation.isMutating
                    ? const CircularProgressIndicator()
                    : const Text('Sign Up'),
              ),
            ],
          );
        },
      ),
    );
  }
}
