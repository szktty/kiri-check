import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:test/test.dart';

enum BankAccountResult {
  success,
  frozen,
  alreadyFrozen,
  notFrozen,
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

// TODO: 確認したいシュリンク内容ごとにBehaviorを用意したほうがよさそう

abstract class BankAccountBehaviorBase extends Behavior<BankAccount> {
  @override
  BankAccount createState() {
    return BankAccount();
  }

  Action0<BankAccount> nextDayAction() => Action0(
        'next day',
        (s) {
          s.nextDay();
        },
      );

  List<Action0<BankAccount>> freezeActions() => [
        Action0(
          'freeze',
          (s) {
            expect(
                s.freeze(),
                anyOf(
                  BankAccountResult.success,
                  BankAccountResult.alreadyFrozen,
                ));
          },
        ),
        Action0(
          'unfreeze',
          (s) {
            expect(
                s.unfreeze(),
                anyOf(
                  BankAccountResult.success,
                  BankAccountResult.notFrozen,
                ));
          },
        ),
      ];

  Action<BankAccount, int> amountAction(
    String description,
    BankAccountResult Function(BankAccount, int) action, {
    required bool success,
    List<BankAccountResult>? result,
    String? reason,
    int min = 0,
    int? max,
    bool freezable = true,
    bool checksHistory = true,
  }) {
    final result0 = List<BankAccountResult>.from(result ?? []);
    if (checksHistory) {
      result0
        ..add(BankAccountResult.overMaxSameOperationsPerDay)
        ..add(BankAccountResult.overMaxOperationsPerDay);
    }

    if (success) {
      result0.add(BankAccountResult.success);
    }

    final expected = result0.fold(
      null,
      (Matcher? prev, result) =>
          prev == null ? equals(result) : anyOf(prev, result),
    )!;

    return Action(
      description,
      integer(min: min, max: max),
      (s, amount) {
        s
          ..freezable = freezable
          ..checksHistory = checksHistory;

        if (s.frozen) {
          expect(
            action(s, amount),
            BankAccountResult.frozen,
            reason: 'account frozen',
          );
        } else {
          expect(action(s, amount), expected, reason: reason);
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
        (s, amount) => s.deposit(amount),
        result: result,
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
        (s, amount) => s.withdraw(amount),
        result: result,
        reason: reason,
        min: min,
        max: max,
        success: success,
      );
}

// 基本的な実装。すべて成功すべき
final class BankAccountBasicBehavior extends BankAccountBehaviorBase {
  @override
  List<Command<BankAccount>> generateCommands(BankAccount s) {
    return [
      nextDayAction(),
      ...freezeActions(),
      depositAction(
        'under min deposit per once',
        success: false,
        max: s.minDepositPerOnce - 1,
        result: [BankAccountResult.underMinDepositPerOnce],
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
  double chargeRate = 0.03;

  bool freezable = true;
  bool frozen = false;
  int balance = 1000000;
  int depositPerDay = 0;
  int withdrawPerDay = 0;

  bool checksHistory = true;
  List<BankAccountOperation> history = [];
  int maxSameOperationsPerDay = 10;
  int maxOperationsPerDay = 20;

  int countOfOperationPerDay(BankAccountOperation operation) =>
      history.where((o) => o == operation).length;

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

  void nextDay() {
    frozen = false;
    history.clear();
    depositPerDay = 0;
    withdrawPerDay = 0;
  }

  BankAccountResult freeze() {
    if (!freezable) {
      return BankAccountResult.success;
    } else if (frozen) {
      return BankAccountResult.alreadyFrozen;
    } else {
      frozen = true;
      return BankAccountResult.success;
    }
  }

  BankAccountResult unfreeze() {
    if (!freezable) {
      return BankAccountResult.success;
    } else if (frozen) {
      frozen = false;
      return BankAccountResult.success;
    } else {
      return BankAccountResult.notFrozen;
    }
  }

  BankAccountResult deposit(int amount) {
    final result = validateDeposit(amount);
    if (result != null) {
      return result;
    } else {
      depositPerDay += amount;
      balance += amount;
      history.add(BankAccountOperation.deposit);
      return BankAccountResult.success;
    }
  }

  BankAccountResult? validateDeposit(int amount) {
    if (freezable && frozen) {
      return BankAccountResult.frozen;
    } else if (amount > maxDepositPerOnce) {
      return BankAccountResult.overMaxDepositPerOnce;
    } else if (amount < minDepositPerOnce) {
      return BankAccountResult.underMinDepositPerOnce;
    } else if (depositPerDay + amount > maxDepositPerDay) {
      return BankAccountResult.overMaxDepositPerDay;
    } else if (balance + amount > maxBalance) {
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

  int charge(int amount) => (amount + amount * chargeRate).toInt();

  BankAccountResult? validateWithdraw(int amount) {
    final charged = charge(amount);
    if (freezable && frozen) {
      return BankAccountResult.frozen;
    } else if (amount > maxWithdrawPerOnce) {
      return BankAccountResult.overMaxWithdrawPerOnce;
    } else if (amount < minWithdrawPerOnce) {
      return BankAccountResult.underMinWithdrawPerOnce;
    } else if (amount > maxWithdrawPerDay) {
      return BankAccountResult.overMaxWithdrawPerDay;
    } else if (balance - charged < minBalance) {
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

  BankAccountResult withdraw(int amount) {
    final result = validateWithdraw(amount);
    if (result != null) {
      return result;
    } else {
      final charged = charge(amount);
      withdrawPerDay += charged;
      balance -= charged;
      history.add(BankAccountOperation.withdraw);
      return BankAccountResult.success;
    }
  }
}
