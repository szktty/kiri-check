import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

enum BankAccountResult {
  success,
  frozen,
  alreadyFrozen,
  notFreezable,
  underMinDepositPerOnce,
  underMinWithdrawPerOnce,
  overMaxDepositPerOnce,
  overMaxDepositPerDay,
  overMaxWithdrawPerOnce,
  overMaxWithdrawPerDay,
  overBalance,
  underBalance,
  overMaxSameOperationsPerDay,
  overMaxOperationsPerDay;

  @override
  String toString() => super.toString().split('.').last;
}

enum BankAccountOperation {
  deposit,
  withdraw,
}

class BankAccountBehavior extends Behavior<BankAccount> {
  @override
  BankAccount createState() {
    return BankAccount();
  }

  Action0<BankAccount> nextDayAction() {
    return Action0(
      'next day',
      (s) {
        s.nextDay();
      },
    );
  }

  List<Action0<BankAccount>> freezeActions() {
    BankAccountResult? freezeResult;
    BankAccountResult? unfreezeResult;
    return [
      Action0(
        'freeze',
        (s) {
          freezeResult = s.tryFreeze();
        },
        postcondition: (s) {
          return s.frozen &&
              (freezeResult == BankAccountResult.success ||
                  freezeResult == BankAccountResult.alreadyFrozen);
        },
      ),
      Action0(
        'unfreeze',
        (s) {
          unfreezeResult = s.tryUnfreeze();
        },
        postcondition: (s) {
          return !s.frozen &&
              (unfreezeResult == BankAccountResult.success ||
                  unfreezeResult == BankAccountResult.notFreezable);
        },
      ),
    ];
  }

  Action<BankAccount, int> amountAction(
    String description,
    BankAccountResult Function(BankAccount, int) action, {
    required bool success,
    List<BankAccountResult>? expected,
    String? reason,
    int min = 0,
    int? max,
    bool freezable = true,
    bool checksHistory = true,
  }) {
    final result0 = [BankAccountResult.frozen];
    if (expected != null) {
      result0.addAll(expected);
    }

    if (checksHistory) {
      result0
        ..add(BankAccountResult.overMaxSameOperationsPerDay)
        ..add(BankAccountResult.overMaxOperationsPerDay);
    }

    if (success) {
      result0.add(BankAccountResult.success);
    }

    BankAccountResult? actual;
    int? before;
    return Action(
      description,
      integer(min: min, max: max),
      (s, amount) {
        s
          ..freezable = freezable
          ..checksHistory = checksHistory;
        before = s.balance;
        actual = action(s, amount);
      },
      postcondition: (s) {
        print('postcondition: $actual, balance $before -> ${s.balance}');
        if (s.frozen) {
          return actual == BankAccountResult.frozen && s.balance == before;
        } else {
          return result0.contains(actual);
        }
      },
    );
  }

  Action<BankAccount, int> depositAction(
    String description, {
    required bool success,
    List<BankAccountResult>? result,
    String? reason,
    int min = 0,
    int? max,
  }) =>
      amountAction(
        description,
        (s, amount) => s.tryDeposit(amount),
        expected: result,
        reason: reason,
        min: min,
        max: max,
        success: success,
      );

  Action<BankAccount, int> withdrawAction(
    String description, {
    required bool success,
    List<BankAccountResult>? result,
    String? reason,
    int min = 0,
    int? max,
  }) =>
      amountAction(
        description,
        (s, amount) => s.tryWithdraw(amount),
        expected: result,
        reason: reason,
        min: min,
        max: max,
        success: success,
      );

  List<Command<BankAccount>> basicDepositActions(BankAccount s) => [
        depositAction(
          'under min deposit per once',
          success: false,
          max: s.minDepositPerOnce - 1,
          result: [
            BankAccountResult.underMinDepositPerOnce,
          ],
        ),
        depositAction(
          'valid range deposit per once',
          success: true,
          min: s.minDepositPerOnce,
          max: s.maxDepositPerOnce,
          result: [
            BankAccountResult.overMaxDepositPerDay,
            BankAccountResult.overBalance,
          ],
        ),
        depositAction(
          'over max deposit per once',
          success: false,
          min: s.maxDepositPerOnce + 1,
          max: s.maxDepositPerDay,
          result: [BankAccountResult.overMaxDepositPerOnce],
        ),
        depositAction(
          'over max deposit per day',
          success: false,
          min: s.maxDepositPerDay + 1,
          result: [BankAccountResult.overMaxDepositPerOnce],
        ),
      ];

  List<Command<BankAccount>> basicWithdrawActions(BankAccount s) => [
        withdrawAction(
          'under min withdraw per once',
          success: false,
          max: s.minWithdrawPerOnce - 1,
          result: [BankAccountResult.underMinWithdrawPerOnce],
        ),
        withdrawAction(
          'valid range withdraw per once',
          success: true,
          min: s.minWithdrawPerOnce,
          max: s.maxWithdrawPerOnce,
          result: [
            BankAccountResult.overMaxWithdrawPerDay,
            BankAccountResult.underBalance,
          ],
        ),
        withdrawAction(
          'over max withdraw per once',
          success: false,
          min: s.maxWithdrawPerOnce + 1,
          max: s.maxWithdrawPerDay,
          result: [BankAccountResult.overMaxWithdrawPerOnce],
        ),
        withdrawAction(
          'over max withdraw per day',
          success: false,
          min: s.maxWithdrawPerDay + 1,
          result: [
            BankAccountResult.overMaxWithdrawPerOnce,
            BankAccountResult.overMaxWithdrawPerDay,
          ],
        ),
      ];

  @override
  List<Command<BankAccount>> generateCommands(BankAccount s) {
    return [
      nextDayAction(),
      ...freezeActions(),
      ...basicDepositActions(s),
      ...basicWithdrawActions(s),
    ];
  }
}

final class BankAccount extends State {
  int minDepositPerOnce = 1000;
  int minWithdrawPerOnce = 1000;

  int maxDepositPerOnce = 500000;
  int maxDepositPerDay = 1000000;
  int maxWithdrawPerOnce = 200000;
  int maxWithdrawPerDay = 500000;
  int maxBalance = 100000000;
  int minBalance = 0;
  double chargeRate = 0.01;

  bool freezable = true;
  bool frozen = false;
  int balance = 1000000;
  int depositPerDay = 0;
  int withdrawPerDay = 0;

  List<BankAccountOperation> history = [];
  int maxSameOperationsPerDay = 10;
  int maxOperationsPerDay = 20;

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

  BankAccountResult tryFreeze() {
    if (!freezable) {
      return BankAccountResult.notFreezable;
    } else if (frozen) {
      return BankAccountResult.alreadyFrozen;
    } else {
      freeze();
      return BankAccountResult.success;
    }
  }

  @protected
  void freeze() {
    frozen = true;
  }

  BankAccountResult tryUnfreeze() {
    if (!freezable) {
      return BankAccountResult.notFreezable;
    } else if (frozen) {
      unfreeze();
      return BankAccountResult.success;
    } else {
      return BankAccountResult.notFreezable;
    }
  }

  @protected
  void unfreeze() {
    frozen = false;
  }

  @protected
  bool validateFrozen() => freezable && frozen;

  BankAccountResult tryDeposit(int amount) {
    final result = validateDeposit(amount);
    if (result != null) {
      return result;
    } else {
      final before = balance;
      deposit(amount);
      didDeposit(amount, before);
      return BankAccountResult.success;
    }
  }

  @protected
  BankAccountResult? validateDeposit(int amount) {
    if (validateFrozen()) {
      return BankAccountResult.frozen;
    } else if (checksDepositRange && amount > maxDepositPerOnce) {
      return BankAccountResult.overMaxDepositPerOnce;
    } else if (checksDepositRange && amount < minDepositPerOnce) {
      return BankAccountResult.underMinDepositPerOnce;
    } else if (checksDepositRange &&
        depositPerDay + amount > maxDepositPerDay) {
      return BankAccountResult.overMaxDepositPerDay;
    } else if (checksBalanceRange && balance + amount > maxBalance) {
      return BankAccountResult.overBalance;
    } else if (checksHistory &&
        countOfLastOperationPerDay(BankAccountOperation.deposit) >
            maxSameOperationsPerDay) {
      return BankAccountResult.overMaxSameOperationsPerDay;
    } else if (checksHistory && history.length > maxOperationsPerDay) {
      return BankAccountResult.overMaxOperationsPerDay;
    } else {
      return null;
    }
  }

  @protected
  void deposit(int amount) {
    depositPerDay += amount;
    balance += amount;
    addHistory(BankAccountOperation.deposit);
  }

  @protected
  void didDeposit(int amount, int before) {
    // override if needed at subclass
  }

  BankAccountResult tryWithdraw(int amount) {
    final result = validateWithdraw(amount);
    if (result != null) {
      return result;
    } else {
      final before = balance;
      withdraw(amount);
      didWithdraw(amount, before);
      return BankAccountResult.success;
    }
  }

  @protected
  int charge(int amount) => (amount + amount * chargeRate).toInt();

  @protected
  BankAccountResult? validateWithdraw(int amount) {
    final charged = charge(amount);
    if (validateFrozen()) {
      return BankAccountResult.frozen;
    } else if (checksWithdrawRange && amount > maxWithdrawPerOnce) {
      return BankAccountResult.overMaxWithdrawPerOnce;
    } else if (checksWithdrawRange && amount < minWithdrawPerOnce) {
      return BankAccountResult.underMinWithdrawPerOnce;
    } else if (checksWithdrawRange && amount > maxWithdrawPerDay) {
      return BankAccountResult.overMaxWithdrawPerDay;
    } else if (checksBalanceRange &&
        checksChargeOnWithdraw &&
        balance - charged < minBalance) {
      return BankAccountResult.underBalance;
    } else if (checksHistory &&
        countOfLastOperationPerDay(BankAccountOperation.deposit) >
            maxSameOperationsPerDay) {
      return BankAccountResult.overMaxSameOperationsPerDay;
    } else if (checksHistory && history.length > maxOperationsPerDay) {
      return BankAccountResult.overMaxOperationsPerDay;
    } else {
      return null;
    }
  }

  @protected
  void withdraw(int amount) {
    final charged = charge(amount);
    withdrawPerDay += charged;
    balance -= charged;
    addHistory(BankAccountOperation.withdraw);
  }

  @protected
  void didWithdraw(int amount, int before) {
    // override if needed at subclass
  }
}

final class BankAccountFreezeNotWorkingBehavior extends BankAccountBehavior {
  @override
  BankAccount createState() => BankAccountFreezeNotWorking();
}

final class BankAccountFreezeNotWorking extends BankAccount {
  @override
  bool validateFrozen() => false;
}
