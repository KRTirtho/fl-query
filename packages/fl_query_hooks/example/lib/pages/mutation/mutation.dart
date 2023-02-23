import 'package:fl_query_hooks/fl_query_hooks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class MutationPage extends HookWidget {
  const MutationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final nameController = useTextEditingController();
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();

    final mutation = useMutation<Map<String, dynamic>, dynamic,
        Map<String, dynamic>, dynamic>(
      'sign-up',
      (variables) {
        return Future.delayed(
          const Duration(seconds: 1),
          () => {
            'name': variables['name'],
            'email': variables['email'],
            'password': variables['password'],
          },
        );
      },
      onMutate: (variables) {
        print('onMutate: $variables');
        return "Recover ME";
      },
      onData: (data, recoveryData) {
        print('onData: $data');
        print('recoveryData: $recoveryData');
      },
      refreshQueries: const ['hello'],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mutation'),
      ),
      body: mutation.hasData
          ? ListView(
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
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: nameController,
                  keyboardType: TextInputType.name,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    await mutation.mutate({
                      'name': nameController.text,
                      'email': emailController.text,
                      'password': passwordController.text,
                    });
                  },
                  child: mutation.isMutating
                      ? const CircularProgressIndicator()
                      : const Text('Sign Up'),
                ),
              ],
            ),
    );
  }
}
