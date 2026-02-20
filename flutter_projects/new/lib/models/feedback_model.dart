import 'package:flutter/foundation.dart';

class FeedbackModel extends ChangeNotifier {
  final List<String> _items = [];

  List<String> get items => List.unmodifiable(_items);

  void addFeedback(String f) {
    _items.add(f);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
