import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  print('Initializing Supabase...');
  await Supabase.initialize(
    url: 'https://fvrmbifeikpleuwblgqw.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZ2cm1iaWZlaWtwbGV1d2JsZ3F3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5MDE3NTAsImV4cCI6MjA5NDQ3Nzc1MH0.uJ0jRqD0Kb1tXrMqX8OlvgQpOfvow5lCMBwZFu7reHY',
  );

  final client = Supabase.instance.client;
  print('Querying du_program_eligibility...');
  final res = await client.from('du_program_eligibility').select();
  
  print('Results:');
  for (var row in res) {
    final name = row['program_name'] as String;
    if (name.toLowerCase().contains('b.a.') || name.toLowerCase().contains('program')) {
      print('Program: $name');
      print('Combinations: ${row['combinations']}');
      print('-----------------------------');
    }
  }
}
