import 'package:firebase_3_pm_app/components/my_drawer.dart';
import 'package:firebase_3_pm_app/helpers/firebase_auth_helper.dart';
import 'package:firebase_3_pm_app/helpers/rtdb_helper.dart';
import 'package:firebase_3_pm_app/models/student_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DashBoard extends StatefulWidget {
  const DashBoard({Key? key}) : super(key: key);

  @override
  _DashBoardState createState() => _DashBoardState();
}

class _DashBoardState extends State<DashBoard> {
  final GlobalKey<FormState> _insertFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _updateFormKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  final TextEditingController _nameUpdateController = TextEditingController();
  final TextEditingController _ageUpdateController = TextEditingController();

  String name = "";
  int age = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    dynamic args = ModalRoute.of(context)!.settings.arguments;

    return Scaffold(
      appBar: AppBar(
        title: const Text("DashBoard"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new),
            onPressed: () {
              FirebaseAuthHelper.instance.signOutUser();

              Navigator.of(context)
                  .pushNamedAndRemoveUntil('/', (route) => false);
            },
          ),
        ],
      ),
      drawer: MyDrawer(
        userCredential: args,
      ),
      body: StreamBuilder(
        stream:
            RTDBHelper.databaseReference.child('students').orderByKey().onValue,
        builder: (context, AsyncSnapshot snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data != null) {
              // snapshot.data => Event
              Map data = snapshot.data.snapshot.value;

              List<Student> students = [];
              List keys = [];

              data.forEach((key, value) {
                keys.add(key);
                students.add(
                  Student(
                    id: value['id'],
                    name: value['name'],
                    age: value['age'],
                  ),
                );
              });

              return ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, i) {
                  return Card(
                    elevation: 3,
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      isThreeLine: true,
                      leading: Text("${i + 1}"),
                      title: Text(students[i].name),
                      subtitle: Text(
                          "Age: ${students[i].age}\nId: ${students[i].id}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              updateData(keys[i], students[i]);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              RTDBHelper.instance.delete(int.parse(keys[i]));
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            } else {
              return const Center(
                child: Text("No Data Found"),
              );
            }
          } else if (snapshot.hasError) {
            return Center(
              child: Text("ERROR: ${snapshot.error}"),
            );
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text("Insert"),
        icon: const Icon(Icons.add),
        onPressed: insertData,
      ),
    );
  }

  void insertData() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Center(
            child: Text("Insert Data"),
          ),
          content: Form(
            key: _insertFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  validator: (val) {
                    if (val!.isEmpty) {
                      return "Enter your name first...";
                    }
                    return null;
                  },
                  onSaved: (val) {
                    setState(() {
                      name = val!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "Name",
                    hintText: "Enter your name here",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                TextFormField(
                  controller: _ageController,
                  validator: (val) {
                    if (val!.isEmpty) {
                      return "Enter your age first...";
                    }
                    return null;
                  },
                  onSaved: (val) {
                    setState(() {
                      age = int.parse(val!);
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "Age",
                    hintText: "Enter your age first",
                    border: OutlineInputBorder(),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      child: const Text("Cancel"),
                      onPressed: () {
                        _nameController.clear();
                        _ageController.clear();

                        setState(() {
                          name = "";
                          age = 0;
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    ElevatedButton(
                      child: const Text("Insert"),
                      onPressed: () {
                        if (_insertFormKey.currentState!.validate()) {
                          _insertFormKey.currentState!.save();

                          int id = DateTime.now().millisecondsSinceEpoch;

                          Student data = Student(id: id, name: name, age: age);

                          RTDBHelper.instance.insert(id, data);
                        }

                        _nameController.clear();
                        _ageController.clear();

                        setState(() {
                          name = "";
                          age = 0;
                        });

                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void updateData(String key, Student s) {
    _nameUpdateController.text = s.name;
    _ageUpdateController.text = s.age.toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Center(
            child: Text("Update Data"),
          ),
          content: Form(
            key: _updateFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameUpdateController,
                  validator: (val) {
                    if (val!.isEmpty) {
                      return "Enter your name first...";
                    }
                    return null;
                  },
                  onSaved: (val) {
                    setState(() {
                      name = val!;
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "Name",
                    hintText: "Enter your name here",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                TextFormField(
                  controller: _ageUpdateController,
                  validator: (val) {
                    if (val!.isEmpty) {
                      return "Enter your age first...";
                    }
                    return null;
                  },
                  onSaved: (val) {
                    setState(() {
                      age = int.parse(val!);
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: "Age",
                    hintText: "Enter your age first",
                    border: OutlineInputBorder(),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      child: const Text("Cancel"),
                      onPressed: () {
                        _nameController.clear();
                        _ageController.clear();

                        setState(() {
                          name = "";
                          age = 0;
                        });
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    ElevatedButton(
                      child: const Text("Update"),
                      onPressed: () {
                        if (_updateFormKey.currentState!.validate()) {
                          _updateFormKey.currentState!.save();

                          Student data =
                              Student(id: int.parse(key), name: name, age: age);
                          RTDBHelper.instance.update(int.parse(key), data);
                        }

                        _nameController.clear();
                        _ageController.clear();

                        setState(() {
                          name = "";
                          age = 0;
                        });

                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
