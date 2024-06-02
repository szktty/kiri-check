import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'dart:math' as math;

enum BankAccountResult {
  success,
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

  bool checksHistory = true;
  bool checksDepositRange = true;
  bool checksWithdrawRange = true;
  bool checksBalanceRange = true;
  bool checksChargeOnWithdraw = true;

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

  BankAccountResult freeze() {
    if (frozen) {
      return BankAccountResult.alreadyFrozen;
    } else {
      frozen = true;
      return BankAccountResult.success;
    }
  }

  BankAccountResult unfreeze() {
    if (frozen) {
      frozen = false;
      return BankAccountResult.success;
    } else {
      return BankAccountResult.notFrozen;
    }
  }

  BankAccountResult deposit(int amount) {
    final result = _validateDeposit(amount);
    if (result != null) {
      return result;
    } else {
      depositPerDay += amount;
      balance += amount;
      addHistory(BankAccountOperation.deposit);
      return BankAccountResult.success;
    }
  }

  BankAccountResult? _validateDeposit(int amount) {
    if (frozen) {
      return BankAccountResult.frozen;
    } else if (checksDepositRange &&
        depositPerDay + amount > settings.maxDepositPerDay) {
      return BankAccountResult.overMaxDepositPerDay;
    } else if (checksBalanceRange && balance + amount > settings.maxBalance) {
      return BankAccountResult.overBalance;
    } else if (checksHistory && history.length > settings.maxOperationsPerDay) {
      return BankAccountResult.overMaxOperationsPerDay;
    } else {
      return null;
    }
  }

  BankAccountResult withdraw(int amount) {
    final result = _validateWithdraw(amount);
    if (result != null) {
      return result;
    } else {
      final charged = _charge(amount);
      withdrawPerDay += charged;
      balance -= charged;
      addHistory(BankAccountOperation.withdraw);
      return BankAccountResult.success;
    }
  }

  int _charge(int amount) => (amount + amount * settings.chargeRate).toInt();

  BankAccountResult? _validateWithdraw(int amount) {
    final charged = _charge(amount);
    if (frozen) {
      return BankAccountResult.frozen;
    } else if (checksWithdrawRange && amount > settings.maxWithdrawPerDay) {
      return BankAccountResult.overMaxWithdrawPerDay;
    } else if (checksBalanceRange &&
        checksChargeOnWithdraw &&
        balance - charged < settings.minBalance) {
      return BankAccountResult.underBalance;
    } else if (checksHistory && history.length > settings.maxOperationsPerDay) {
      return BankAccountResult.overMaxOperationsPerDay;
    } else {
      return null;
    }
  }
}
