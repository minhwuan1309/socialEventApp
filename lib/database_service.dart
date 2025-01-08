import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _realtimeDb = FirebaseDatabase.instance;

  Future<void> syncData(Map<String, dynamic> data, String docId) async {
    try {
      // Ghi dữ liệu vào Firestore
      await _firestore.collection('collection_name').doc(docId).set(data);

      // Ghi dữ liệu vào Realtime Database
      await _realtimeDb.ref('collection_name/$docId').set(data);

      print('Data synchronized successfully!');
    } catch (e) {
      print('Error syncing data: $e');
    }
  }

  Future<void> deleteData(String docId) async {
    try {
      // Xóa dữ liệu khỏi Firestore
      await _firestore.collection('collection_name').doc(docId).delete();

      // Xóa dữ liệu khỏi Realtime Database
      await _realtimeDb.ref('collection_name/$docId').remove();

      print('Data deleted successfully!');
    } catch (e) {
      print('Error deleting data: $e');
    }
  }
}
