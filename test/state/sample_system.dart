// - 預け入れ、引き出しを取引で管理
// - ユーザー管理
// - JSONで保持
//  - マクロを使う

import 'dart:convert';
import 'sample_model.dart';

final class BankSystem {
  final BankAccountSettings settings = BankAccountSettings();
  final Map<int, BankAccountSystem> accounts = {};

  void register(int id) {
    accounts[id] = BankAccountSystem(id, settings.defaultBalance);
  }

  bool frozen(int id) {
    return accounts[id]!.frozen;
  }

  void nextDay() {
    for (final account in accounts.values) {
      account.nextDay();
    }
  }

  int getBalance(int id) {
    return accounts[id]!.balance;
  }

  BankAccountResult freeze(int id) {
    final account = accounts[id]!;
    if (account.frozen) {
      return BankAccountResult.alreadyFrozen;
    } else {
      account.freeze();
      return BankAccountResult.success;
    }
  }

  BankAccountResult unfreeze(int id) {
    final account = accounts[id]!;
    if (!account.frozen) {
      return BankAccountResult.notFrozen;
    } else {
      account.unfreeze();
      return BankAccountResult.success;
    }
  }

  BankAccountResult deposit(int id, int amount) {
    final result = _validateDeposit(id, amount);
    if (result != null) {
      return result;
    } else {
      final account = accounts[id]!;
      account.deposit(amount);
      return BankAccountResult.success;
    }
  }

  BankAccountResult? _validateDeposit(int id, int amount) {
    final account = accounts[id]!;
    if (account.frozen) {
      return BankAccountResult.frozen;
    } else if (account.transactions.length > settings.maxOperationsPerDay) {
      return BankAccountResult.overMaxOperationsPerDay;
    } else if (amount + account.depositPerDay > settings.maxDepositPerDay) {
      return BankAccountResult.overMaxDepositPerDay;
    } else if (amount + account.balance > settings.maxBalance) {
      return BankAccountResult.overBalance;
    } else {
      return null;
    }
  }

  BankAccountResult withdraw(int id, int amount) {
    final result = _validateWithdraw(id, amount);
    if (result != null) {
      return result;
    } else {
      final charged = _charge(amount);
      final account = accounts[id]!;
      account.withdraw(charged);
      return BankAccountResult.success;
    }
  }

  int _charge(int amount) => (amount + amount * settings.chargeRate).toInt();

  BankAccountResult? _validateWithdraw(int id, int amount) {
    final account = accounts[id]!;
    final charged = _charge(amount);
    if (account.frozen) {
      return BankAccountResult.frozen;
    } else if (account.transactions.length > settings.maxOperationsPerDay) {
      return BankAccountResult.overMaxOperationsPerDay;
    } else if (amount + account.withdrawPerDay > settings.maxWithdrawPerDay) {
      return BankAccountResult.overMaxWithdrawPerDay;
    } else if (account.balance - charged < settings.minBalance) {
      return BankAccountResult.underBalance;
    } else {
      return null;
    }
  }
}

final class BankAccountSystem {
  BankAccountSystem(this.id, this.balance);

  int id;
  bool frozen = false;
  int balance = 0;

  final List<BankAccountTransaction> transactions = [];

  void freeze() {
    frozen = true;
  }

  void unfreeze() {
    frozen = false;
  }

  void nextDay() {
    frozen = false;
    transactions.clear();
  }

  List<BankAccountTransaction> get depositTransactions => transactions
      .where((t) => t.operation == BankAccountOperation.deposit)
      .toList();

  List<BankAccountTransaction> get withdrawTransactions => transactions
      .where((t) => t.operation == BankAccountOperation.withdraw)
      .toList();

  int get depositPerDay =>
      depositTransactions.fold(0, (sum, t) => sum + t.amount);

  int get withdrawPerDay =>
      withdrawTransactions.fold(0, (sum, t) => sum + t.amount);

  void deposit(int amount) {
    balance += amount;
    transactions
        .add(BankAccountTransaction.deposit(transactions.length, amount));
  }

  void withdraw(int amount) {
    balance -= amount;
    transactions
        .add(BankAccountTransaction.withdraw(transactions.length, amount));
  }
}

final class BankAccountTransaction {
  BankAccountTransaction(this.id, this.amount, this.operation);

  factory BankAccountTransaction.deposit(int id, int amount) {
    return BankAccountTransaction(id, amount, BankAccountOperation.deposit);
  }

  factory BankAccountTransaction.withdraw(int id, int amount) {
    return BankAccountTransaction(id, amount, BankAccountOperation.withdraw);
  }

  final int id;
  final int amount;
  final BankAccountOperation operation;
}
