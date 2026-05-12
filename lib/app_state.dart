import 'package:flutter/material.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {}

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  String _selectedMediaId = '';
  String get selectedMediaId => _selectedMediaId;
  set selectedMediaId(String value) {
    _selectedMediaId = value;
  }

  String _selectedMediaMetadata = '';
  String get selectedMediaMetadata => _selectedMediaMetadata;
  set selectedMediaMetadata(String value) {
    _selectedMediaMetadata = value;
  }

  String _selectedMediaProcessing = '';
  String get selectedMediaProcessing => _selectedMediaProcessing;
  set selectedMediaProcessing(String value) {
    _selectedMediaProcessing = value;
  }

  String _selectedMediaEntry = '';
  String get selectedMediaEntry => _selectedMediaEntry;
  set selectedMediaEntry(String value) {
    _selectedMediaEntry = value;
  }

  String _selectedMediaDate = '';
  String get selectedMediaDate => _selectedMediaDate;
  set selectedMediaDate(String value) {
    _selectedMediaDate = value;
  }

  double _selectedMediaAvgScore = 0.0;
  double get selectedMediaAvgScore => _selectedMediaAvgScore;
  set selectedMediaAvgScore(double value) {
    _selectedMediaAvgScore = value;
  }

  double _selectedMediaHighScore = 0.0;
  double get selectedMediaHighScore => _selectedMediaHighScore;
  set selectedMediaHighScore(double value) {
    _selectedMediaHighScore = value;
  }

  String _selectedMediaFileUrl = '';
  String get selectedMediaFileUrl => _selectedMediaFileUrl;
  set selectedMediaFileUrl(String value) {
    _selectedMediaFileUrl = value;
  }

  String _selectedMediaTitle = '';
  String get selectedMediaTitle => _selectedMediaTitle;
  set selectedMediaTitle(String value) {
    _selectedMediaTitle = value;
  }
}
