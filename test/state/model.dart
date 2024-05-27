import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:test/test.dart';

enum BankAccountResult {
  success,
  locked,
  alreadyLocked,
  notLocked,
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

  List<Action0<BankAccount>> lockActions() => [
        Action0(
          'lock',
          (s) {
            expect(
                s.lock(),
                anyOf(
                  BankAccountResult.success,
                  BankAccountResult.alreadyLocked,
                ));
          },
        ),
        Action0(
          'unlock',
          (s) {
            expect(
                s.unlock(),
                anyOf(
                  BankAccountResult.success,
                  BankAccountResult.notLocked,
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
    bool canLock = true,
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
          ..canLock = canLock
          ..checksHistory = checksHistory;

        if (s.locked) {
          expect(
            action(s, amount),
            BankAccountResult.locked,
            reason: 'account locked',
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
      ...lockActions(),
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

  bool canLock = true;
  bool locked = false;
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
    locked = false;
    history.clear();
    depositPerDay = 0;
    withdrawPerDay = 0;
  }

  BankAccountResult lock() {
    if (locked) {
      return BankAccountResult.alreadyLocked;
    } else {
      locked = true;
      return BankAccountResult.success;
    }
  }

  BankAccountResult unlock() {
    if (locked) {
      locked = false;
      return BankAccountResult.success;
    } else {
      return BankAccountResult.notLocked;
    }
  }

  BankAccountResult deposit(int amount) {
    if (canLock && locked) {
      return BankAccountResult.locked;
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
      depositPerDay += amount;
      balance += amount;
      history.add(BankAccountOperation.deposit);
      return BankAccountResult.success;
    }
  }

  BankAccountResult withdraw(int amount) {
    final charged = (amount + amount * chargeRate).toInt();
    if (canLock && locked) {
      return BankAccountResult.locked;
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
      withdrawPerDay += charged;
      balance -= charged;
      history.add(BankAccountOperation.withdraw);
      return BankAccountResult.success;
    }
  }
}
