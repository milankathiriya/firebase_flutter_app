import 'package:firebase_3_pm_app/models/student_model.dart';
import 'package:firebase_database/firebase_database.dart';

class RTDBHelper {
  static final databaseReference = FirebaseDatabase.instance.reference();
  static final String table = "students";

  RTDBHelper._();
  static final RTDBHelper instance = RTDBHelper._();

  insert(int id, Student s) {
    // databaseReference.set(s.toMap());
    // databaseReference.child(table).set(s.toMap());
    databaseReference.child(table).child("$id").set(s.toMap());
    // databaseReference.push().child(table).child("$id").set(s.toMap());
  }

  update(int id, Student s) {
    databaseReference.child("$table/$id").set(s.toMap());
  }

  delete(int id) {
    databaseReference.child(table).child("$id").remove();
  }
}
