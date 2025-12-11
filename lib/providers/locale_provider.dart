import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLocale { vi, en }
enum AppCurrency { vnd, usd }

class LocaleProvider extends ChangeNotifier {
  AppLocale _locale = AppLocale.vi;
  AppCurrency _currency = AppCurrency.vnd;
  
  static const String _localeKey = 'app_locale';
  static const String _currencyKey = 'app_currency';

  AppLocale get locale => _locale;
  AppCurrency get currency => _currency;

  String get localeCode => _locale == AppLocale.vi ? 'vi_VN' : 'en_US';
  String get currencyCode => _currency == AppCurrency.vnd ? 'VND' : 'USD';
  String get currencySymbol => _currency == AppCurrency.vnd ? 'đ' : '\$';

  // Tỷ giá chuyển đổi (1 USD = 24,000 VND - có thể lấy từ API)
  static const double usdToVndRate = 24000.0;

  LocaleProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final localeIndex = prefs.getInt(_localeKey) ?? 0;
    final currencyIndex = prefs.getInt(_currencyKey) ?? 0;
    
    _locale = AppLocale.values[localeIndex.clamp(0, AppLocale.values.length - 1)];
    _currency = AppCurrency.values[currencyIndex.clamp(0, AppCurrency.values.length - 1)];
    
    notifyListeners();
  }

  Future<void> setLocale(AppLocale newLocale) async {
    if (_locale == newLocale) return;
    
    _locale = newLocale;
    
    // Tự động set currency theo locale
    if (newLocale == AppLocale.vi) {
      _currency = AppCurrency.vnd;
    } else {
      _currency = AppCurrency.usd;
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_localeKey, newLocale.index);
    await prefs.setInt(_currencyKey, _currency.index);
    
    notifyListeners();
  }

  Future<void> setCurrency(AppCurrency newCurrency) async {
    if (_currency == newCurrency) return;
    
    _currency = newCurrency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currencyKey, newCurrency.index);
    notifyListeners();
  }

  // Format currency với chuyển đổi
  String formatCurrency(double amount) {
    double displayAmount = amount;
    
    if (_currency == AppCurrency.usd) {
      displayAmount = amount / usdToVndRate;
    }
    
    final formatter = NumberFormat.currency(
      locale: localeCode,
      symbol: currencySymbol,
      decimalDigits: _currency == AppCurrency.vnd ? 0 : 2,
    );
    return formatter.format(displayAmount);
  }

  // Chuyển đổi giá từ VND sang currency hiện tại
  double convertPrice(double vndAmount) {
    if (_currency == AppCurrency.usd) {
      return vndAmount / usdToVndRate;
    }
    return vndAmount;
  }

  // Lấy tên ngôn ngữ
  String getLocaleName() {
    return _locale == AppLocale.vi ? 'Tiếng Việt' : 'English';
  }

  // Lấy tên tiền tệ
  String getCurrencyName() {
    return _currency == AppCurrency.vnd ? 'VND (đ)' : 'USD (\$)';
  }
}

