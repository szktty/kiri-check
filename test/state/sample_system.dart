// - 預け入れ、引き出しを取引で管理
// - ユーザー管理
// - JSONで保持
//  - マクロを使う

import 'dart:convert';
import 'sample_model.dart';

final class BankSystem {
  final BankAccountSettings settings = BankAccountSettings();
  final Map<int, Map<String, dynamic>> accounts = {};

  void register(int id) {
    accounts[id] = {
      'frozen': false,
      'balance': 0,
      'depositPerDay': 0,
      'withdrawPerDay': 0,
    };
  }

  T _getProperty<T>(int id, String key) {
    return accounts[id]![key] as T;
  }

  dynamic _setProperty(int id, String key, dynamic value) {
    accounts[id]![key] = value;
  }

  bool frozen(int id) {
    return _getProperty(id, 'frozen');
  }

  void nextDay() {
    for (final account in accounts.values) {
      account['frozen'] = false;
      account['depositPerDay'] = 0;
      account['withdrawPerDay'] = 0;
    }
  }

  int getBalance(int id) {
    return _getProperty(id, 'balance');
  }

  BankAccountResult deposit(int id, int amount) {
    // TODO
    return BankAccountResult.success;
  }

  BankAccountResult withdraw(int id, int amount) {
    // TODO

    return BankAccountResult.success;
  }

  BankAccountResult freeze(int id) {
    if (_getProperty(id, 'frozen')) {
      return BankAccountResult.alreadyFrozen;
    } else {
      _setProperty(id, 'frozen', true);
      return BankAccountResult.success;
    }
  }

  BankAccountResult unfreeze(int id) {
    if (!_getProperty(id, 'frozen')) {
      return BankAccountResult.notFrozen;
    } else {
      _setProperty(id, 'frozen', false);
      return BankAccountResult.success;
    }
  }
}
