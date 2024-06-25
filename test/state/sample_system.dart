import 'sample_model.dart';

final class BankAccountManager {
  final BankAccountSettings settings = BankAccountSettings();
  final Map<int, BankAccountSystem> accounts = {};

  BankAccountSystem register(int id) {
    return accounts[id] = BankAccountSystem(this, id, settings.defaultBalance);
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

  BankAccountError? freeze(int id) {
    final account = accounts[id]!;
    if (account.frozen) {
      return BankAccountError.alreadyFrozen;
    } else {
      account.frozen = true;
      return null;
    }
  }

  BankAccountError? unfreeze(int id) {
    final account = accounts[id]!;
    if (!account.frozen) {
      return BankAccountError.notFrozen;
    } else {
      account.frozen = false;
      return null;
    }
  }

  dynamic deposit(int id, int amount) {
    final result = _validateDeposit(id, amount);
    if (result != null) {
      return result;
    } else {
      return accounts[id]!.balance += amount;
    }
  }

  BankAccountError? _validateDeposit(int id, int amount) {
    final account = accounts[id]!;
    if (account.frozen) {
      return BankAccountError.frozen;
    } else if (account.transactions.length > settings.maxOperationsPerDay) {
      return BankAccountError.overMaxOperationsPerDay;
    } else if (amount + account.depositPerDay > settings.maxDepositPerDay) {
      return BankAccountError.overMaxDepositPerDay;
    } else if (amount + account.balance > settings.maxBalance) {
      return BankAccountError.overBalance;
    } else {
      return null;
    }
  }

  dynamic withdraw(int id, int amount) {
    final result = _validateWithdraw(id, amount);
    if (result != null) {
      return result;
    } else {
      return accounts[id]!.balance -= _charge(amount);
    }
  }

  int _charge(int amount) => (amount + amount * settings.chargeRate).toInt();

  BankAccountError? _validateWithdraw(int id, int amount) {
    final account = accounts[id]!;
    final charged = _charge(amount);
    if (account.frozen) {
      return BankAccountError.frozen;
    } else if (account.transactions.length > settings.maxOperationsPerDay) {
      return BankAccountError.overMaxOperationsPerDay;
    } else if (amount + account.withdrawPerDay > settings.maxWithdrawPerDay) {
      return BankAccountError.overMaxWithdrawPerDay;
    } else if (account.balance - charged < settings.minBalance) {
      return BankAccountError.underBalance;
    } else {
      return null;
    }
  }
}

final class BankAccountSystem {
  BankAccountSystem(this.manager, this.id, this.balance);

  BankAccountManager manager;
  int id;
  bool frozen = false;
  int balance = 0;

  final List<BankAccountTransaction> transactions = [];

  void freeze() {
    manager.freeze(id);
  }

  void unfreeze() {
    manager.unfreeze(id);
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

  dynamic deposit(int amount) {
    final result = manager.deposit(id, amount);
    if (result is int) {
      transactions
          .add(BankAccountTransaction.deposit(transactions.length, amount));
      return balance;
    } else {
      return result;
    }
  }

  dynamic withdraw(int amount) {
    final result = manager.withdraw(id, amount);
    if (result is int) {
      transactions
          .add(BankAccountTransaction.withdraw(transactions.length, amount));
      return balance;
    } else {
      return result;
    }
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
