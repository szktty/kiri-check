import 'dart:math' as math;

import 'package:meta/meta.dart';

enum BankAccountError {
  frozen,
  alreadyFrozen,
  notFrozen,
  overMaxDepositPerDay,
  overMaxWithdrawPerDay,
  overBalance,
  underBalance,
  overMaxOperationsPerDay;

  @override
  String toString() => super.toString().split('.').last;
}

enum BankAccountOperation {
  deposit,
  withdraw,
}

final class BankAccountSettings {
  int defaultBalance = 5000000;
  int maxDepositPerDay = 1000000;
  int maxWithdrawPerDay = 500000;
  int maxBalance = 1000000;
  int minBalance = 0;
  double chargeRate = 0.01;

  int maxOperationsPerDay = 20;
}

final class BankAccountModel {
  BankAccountModel() {
    balance = settings.defaultBalance;
  }

  final BankAccountSettings settings = BankAccountSettings();

  final int id = math.Random().nextInt(1000000);

  bool frozen = false;
  late int balance;
  int depositPerDay = 0;
  int withdrawPerDay = 0;

  List<BankAccountOperation> history = [];

  @protected
  int countOfOperationPerDay(BankAccountOperation operation) =>
      history.where((o) => o == operation).length;

  @protected
  int countOfLastOperationPerDay(BankAccountOperation operation) {
    var count = 0;
    for (var i = history.length - 1; i >= 0; i--) {
      if (history[i] != operation) {
        return count;
      }
      count++;
    }
    return count;
  }

  @protected
  void addHistory(BankAccountOperation operation) {
    history.add(operation);
  }

  void nextDay() {
    unfreeze();
    clearHistory();
    clearDepositPerDay();
    clearWithdrawPerDay();
  }

  @protected
  void clearHistory() {
    history.clear();
  }

  @protected
  void clearDepositPerDay() {
    depositPerDay = 0;
  }

  @protected
  void clearWithdrawPerDay() {
    withdrawPerDay = 0;
  }

  BankAccountError? freeze() {
    if (frozen) {
      return BankAccountError.alreadyFrozen;
    } else {
      frozen = true;
      return null;
    }
  }

  BankAccountError? unfreeze() {
    if (frozen) {
      frozen = false;
      return null;
    } else {
      return BankAccountError.notFrozen;
    }
  }

  dynamic tryDeposit(int amount) {
    final result = _validateDeposit(amount);
    if (result != null) {
      return result;
    } else {
      return balance + amount;
    }
  }

  dynamic deposit(int amount) {
    final result = _validateDeposit(amount);
    if (result != null) {
      return result;
    } else {
      depositPerDay += amount;
      balance += amount;
      addHistory(BankAccountOperation.deposit);
      return balance;
    }
  }

  BankAccountError? _validateDeposit(int amount) {
    if (frozen) {
      return BankAccountError.frozen;
    } else if (depositPerDay + amount > settings.maxDepositPerDay) {
      return BankAccountError.overMaxDepositPerDay;
    } else if (balance + amount > settings.maxBalance) {
      return BankAccountError.overBalance;
    } else if (history.length > settings.maxOperationsPerDay) {
      return BankAccountError.overMaxOperationsPerDay;
    } else {
      return null;
    }
  }

  dynamic tryWithdraw(int amount) {
    final result = _validateWithdraw(amount);
    if (result != null) {
      return result;
    } else {
      return balance - _charge(amount);
    }
  }

  dynamic withdraw(int amount) {
    final result = _validateWithdraw(amount);
    if (result != null) {
      return result;
    } else {
      final charged = _charge(amount);
      withdrawPerDay += charged;
      balance -= charged;
      addHistory(BankAccountOperation.withdraw);
      return balance;
    }
  }

  int _charge(int amount) => (amount + amount * settings.chargeRate).toInt();

  BankAccountError? _validateWithdraw(int amount) {
    final charged = _charge(amount);
    if (frozen) {
      return BankAccountError.frozen;
    } else if (amount + withdrawPerDay > settings.maxWithdrawPerDay) {
      return BankAccountError.overMaxWithdrawPerDay;
    } else if (balance - charged < settings.minBalance) {
      return BankAccountError.underBalance;
    } else if (history.length > settings.maxOperationsPerDay) {
      return BankAccountError.overMaxOperationsPerDay;
    } else {
      return null;
    }
  }
}
