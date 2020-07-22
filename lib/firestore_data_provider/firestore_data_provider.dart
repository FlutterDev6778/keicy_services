import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class KeicyFireStoreDataProvider {
  static KeicyFireStoreDataProvider _instance = KeicyFireStoreDataProvider();
  static KeicyFireStoreDataProvider get instance => _instance;

  Future<dynamic> addDocument({@required String path, @required Map<String, dynamic> data}) async {
    try {
      final ref = await Firestore.instance.collection(path).add(data);
      if (ref != null) {
        data['id'] = ref.documentID;
        var res = await updateDocument(
          path: path,
          id: ref.documentID,
          data: {'id': ref.documentID},
        );
        if (res) {
          return data;
        } else {
          return '-1';
        }
      }
    } catch (e) {
      print("____________ firebase addDocument error ____________");
      print(e);
      return '-1';
    }
  }

  Future<bool> updateDocument({@required String path, @required String id, @required Map<String, dynamic> data}) async {
    try {
      await Firestore.instance.collection(path).document(id).updateData(data);
      return true;
    } catch (e) {
      print("____________ firebase updateDocument error ____________");
      print(e);
      return false;
    }
  }

  Future<bool> deleteDocument({@required String path, @required String id}) async {
    try {
      await Firestore.instance.collection(path).document(id).delete();
      return true;
    } catch (e) {
      print("____________ firebase deleteDocument error ____________");
      print(e);
      return false;
    }
  }

  Future<bool> isDocExist({String path, String id}) async {
    try {
      final DocumentSnapshot docSnapShot = await Firestore.instance.collection(path).document(id).get();
      return docSnapShot.exists;
    } catch (e) {
      print("____________ firebase isDocExist error ____________");
      print(e);
      return false;
    }
  }

  Future getDocumentByID({@required String path, @required String id}) async {
    try {
      DocumentSnapshot documentSnapshot = await Firestore.instance.collection(path).document(id).get();
      Map<String, dynamic> data = documentSnapshot.data;
      data["id"] = documentSnapshot.documentID;
      return data;
    } catch (e) {
      print("____________ firebase getDocumentByID error ____________");
      print(e);
      return '-1';
    }
  }

  Stream<Map<String, dynamic>> getDocumentStreamByID({@required String path, @required String id}) {
    Stream<DocumentSnapshot> stream = Firestore.instance.collection(path).document(id).snapshots();
    return stream.map((documentSnapshot) {
      Map<String, dynamic> data = documentSnapshot.data;
      data["id"] = documentSnapshot.documentID;
      return data;
    });
  }

  Future getDocumentData({@required String path, List<Map<String, dynamic>> wheres, List<Map<String, dynamic>> orderby, int limit}) async {
    CollectionReference ref;
    Query query;
    try {
      ref = Firestore.instance.collection(path);
      query = ref;
      if (wheres != null) query = _getQuery(query, wheres);
      if (orderby != null) query = _getOrderby(query, orderby);
      if (limit != null) query.limit(limit);
      QuerySnapshot snapshot = await query.getDocuments();
      List<Map<String, dynamic>> data = [];
      for (var i = 0; i < snapshot.documents.length; i++) {
        var tmp = snapshot.documents.elementAt(i).data;
        tmp["id"] = snapshot.documents.elementAt(i).documentID;
        data.add(tmp);
      }
      return data;
    } catch (e) {
      print("____________ firebase getDocumentData error ____________");
      print(e);
      return '-1';
    }
  }

  Stream<List<Map<String, dynamic>>> getDocumentsStream(
      {@required String path, List<Map<String, dynamic>> wheres, List<Map<String, dynamic>> orderby, int limit}) {
    try {
      CollectionReference ref;
      Query query;
      ref = Firestore.instance.collection(path);
      query = ref;
      if (wheres != null) query = _getQuery(query, wheres);
      if (orderby != null) query = _getOrderby(query, orderby);
      if (limit != null) query.limit(limit);
      return query.snapshots().map((snapshot) {
        return snapshot.documents.map((document) {
          Map<String, dynamic> data = document.data;
          data["id"] = document.documentID;
          return data;
        }).toList();
      });
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future getDocumentDataWithChilCollection({
    @required String parentCollectionName,
    @required String childCollectionName,
    List<Map<String, dynamic>> parentWheres,
    List<Map<String, dynamic>> parentOrderby,
    int parentLimit,
    List<Map<String, dynamic>> childWheres,
    List<Map<String, dynamic>> childOrderby,
    int childLimit,
  }) async {
    CollectionReference parentRef;
    Query parentQuery;
    QuerySnapshot parentSnapshot;
    CollectionReference childRef;
    Query childQuery;
    QuerySnapshot childSnapshot;
    List<Map<String, dynamic>> data = [];
    try {
      parentRef = Firestore.instance.collection(parentCollectionName);
      parentQuery = parentRef;
      if (parentWheres != null) parentQuery = _getQuery(parentQuery, parentWheres);
      if (parentOrderby != null) parentQuery = _getOrderby(parentQuery, parentOrderby);
      if (parentLimit != null) parentQuery.limit(parentLimit);
      parentQuery.snapshots().map((snapshot) async {
        return Future.wait(snapshot.documents.map((document) async {
          Map<String, dynamic> parentData = document.data;
          parentData["id"] = document.documentID;
          childRef = document.reference.collection(childCollectionName);
          childQuery = childRef;
          if (childWheres != null) childQuery = _getQuery(childQuery, childWheres);
          if (childOrderby != null) childQuery = _getOrderby(childQuery, childOrderby);
          if (childLimit != null) childQuery.limit(childLimit);
          try {
            childSnapshot = await childQuery.getDocuments();
            for (var j = 0; j < childSnapshot.documents.length; j++) {
              Map<String, dynamic> childData = childSnapshot.documents.elementAt(j).data;
              childData["id"] = childSnapshot.documents.elementAt(j).documentID;
              data.add({"parent": parentData, "child": childData});
            }
          } catch (e) {
            print(e);
          }

          return data;
        }));
      });

      parentSnapshot = await parentQuery.getDocuments();
      for (var i = 0; i < parentSnapshot.documents.length; i++) {}
    } catch (e) {
      print("getDocument Error : $e");
      return '-1';
    }
  }

  Stream<List<Stream<List<Map<String, dynamic>>>>> getDocumentsStreamWithChildCollection({
    @required String parentCollectionName,
    @required String childCollectionName,
    List<Map<String, dynamic>> parentWheres,
    List<Map<String, dynamic>> parentOrderby,
    int parentLimit,
    List<Map<String, dynamic>> childWheres,
    List<Map<String, dynamic>> childOrderby,
    int childLimit,
  }) {
    CollectionReference parentRef;
    Query parentQuery;
    CollectionReference childRef;
    Query childQuery;
    try {
      parentRef = Firestore.instance.collection(parentCollectionName);
      parentQuery = parentRef;
      if (parentWheres != null) parentQuery = _getQuery(parentQuery, parentWheres);
      if (parentOrderby != null) parentQuery = _getOrderby(parentQuery, parentOrderby);
      if (parentLimit != null) parentQuery.limit(parentLimit);
      return parentQuery.snapshots().map((parentSnapshot) {
        return parentSnapshot.documents.map((parentDocument) {
          Map<String, dynamic> parentData = parentDocument.data;
          parentData["id"] = parentDocument.documentID;
          childRef = parentDocument.reference.collection(childCollectionName);
          childQuery = childRef;
          if (childWheres != null) childQuery = _getQuery(childQuery, childWheres);
          if (childOrderby != null) childQuery = _getOrderby(childQuery, childOrderby);
          if (childLimit != null) childQuery.limit(childLimit);
          return childQuery.snapshots().map((snapshot) {
            return snapshot.documents.map((document) {
              Map<String, dynamic> childData = document.data;
              childData["id"] = document.documentID;
              return {
                "parent": parentData,
                "child": childData,
              };
            }).toList();
          });
        }).toList();
      });
    } catch (e) {
      print(e);
      return null;
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
  }
}

Query _getQuery(Query query, List<Map<String, dynamic>> wheres) {
  for (var i = 0; i < wheres.length; i++) {
    var key = wheres[i]["key"];
    var cond = wheres[i]["cond"];
    var val = wheres[i]["val"];

    switch (cond.toString()) {
      case "":
        query = query.where(key, isEqualTo: val);
        break;
      case "null":
        query = query.where(key, isEqualTo: val);
        break;
      case "=":
        query = query.where(key, isEqualTo: val);
        break;
      case "<":
        query = query.where(key, isLessThan: val);
        break;
      case "<=":
        query = query.where(key, isLessThanOrEqualTo: val);
        break;
      case ">":
        query = query.where(key, isGreaterThan: val);
        break;
      case ">=":
        query = query.where(key, isGreaterThanOrEqualTo: val);
        break;
      case "arrayContains":
        query = query.where(key, arrayContains: val);
        break;
      case "whereIn":
        query = query.where(key, whereIn: val);
        break;
      case "arrayContainsAny":
        query = query.where(key, arrayContainsAny: val);
        break;
      default:
        query = query.where(key, isEqualTo: val);
        break;
    }
  }
  return query;
}

Query _getOrderby(Query query, List<Map<String, dynamic>> orderby) {
  for (var i = 0; i < orderby.length; i++) {
    query = query.orderBy(orderby[i]["key"], descending: (orderby[i]["desc"] == null) ? false : true);
  }
  return query;
}
