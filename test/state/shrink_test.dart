import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:test/test.dart';

enum BankAccountError {
  locked,
  overMaxDepositPerOnce,
  overMaxDepositPerDay,
  overMaxWithdrawPerOnce,
  overMaxWithdrawPerDay,
  overBalance,
  underBalance,
  overMaxSameOperationsPerDay,
  overMaxOperationsPerDay,
}

enum BankAccountOperation {
  deposit,
  withdraw,
}

// TODO: 確認したいシュリンク内容ごとにBehaviorを用意したほうがよさそう
final class BankAccountBehavior extends Behavior<BankAccountState> {
  @override
  BankAccountState createState() {
    return BankAccountState();
  }

  @override
  List<Command<BankAccountState>> generateCommands(BankAccountState s) {
    return [
      Action(
        'small deposit',
        integer(min: 0, max: s.maxDepositPerOnce),
        (s, amount) {
          expect(
              s.deposit(amount),
              anyOf(
                isNull,
                BankAccountError.overMaxDepositPerDay,
                BankAccountError.overBalance,
                BankAccountError.overMaxSameOperationsPerDay,
                BankAccountError.overMaxOperationsPerDay,
              ));
        },
      ),
      Action(
        'deposit over per once and under per day',
        integer(min: s.maxDepositPerOnce + 1, max: s.maxDepositPerDay),
        (s, amount) {
          expect(
              s.deposit(amount),
              anyOf(
                BankAccountError.overMaxDepositPerOnce,
                BankAccountError.overMaxSameOperationsPerDay,
                BankAccountError.overMaxOperationsPerDay,
              ));
        },
      ),
      Action(
        'deposit under balance',
        integer(min: s.maxDepositPerDay + 1),
        (s, amount) {
          expect(
              s.deposit(amount),
              anyOf(
                BankAccountError.overMaxDepositPerDay,
                BankAccountError.overMaxSameOperationsPerDay,
                BankAccountError.overMaxOperationsPerDay,
              ));
        },
      ),
      Action(
        'small withdraw',
        integer(min: 0, max: s.maxWithdrawPerOnce),
        (s, amount) {
          expect(s.withdraw(amount), isNull);
        },
      ),
      Action(
        'withdraw over per once and under per day',
        integer(min: s.maxWithdrawPerOnce + 1, max: s.maxWithdrawPerDay),
        (s, amount) {
          expect(s.withdraw(amount), BankAccountError.overMaxWithdrawPerOnce);
        },
      ),
      Action(
        'withdraw under balance',
        integer(min: s.maxWithdrawPerDay + 1, max: s.maxBalance),
        (s, amount) {
          expect(s.withdraw(amount), BankAccountError.underBalance);
        },
      ),
      Action0(
        'next day',
        (s) {
          s.nextDay();
        },
      ),
    ];
  }
}

final class BankAccountState extends State {
  // TODO: 日をまたぐ操作を可能にする
  // 日付更新操作

  // TODO: トータルで振込可能な額を設定する
  // 額を超えるとロックする
  // 複数回の振込操作が必要になる

  // TODO: 同一操作回数制限
  // 同じ操作を一定回数行うとロックする
  // 同じ操作が複数回必要になる

  // TODO: 操作制限
  // 引き出しと振込をそれぞれ一定回数行うとロックする
  // 異なる操作が複数回必要になる

  int maxDepositPerOnce = 500000;
  int maxDepositPerDay = 1000000;
  int maxWithdrawPerOnce = 200000;
  int maxWithdrawPerDay = 500000;
  int maxBalance = 100000000;
  int minBalance = 0;
  double chargeRate = 0.03;

  bool locked = false;
  int balance = 1000000;
  int depositPerDay = 0;
  int withdrawPerDay = 0;

  List<BankAccountOperation> history = [];

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

  void lock() {
    locked = true;
  }

  void unlock() {
    locked = false;
  }

  BankAccountError? deposit(int amount) {
    if (locked) {
      return BankAccountError.locked;
    } else if (amount > maxDepositPerOnce) {
      return BankAccountError.overMaxDepositPerOnce;
    } else if (balance + amount > maxBalance) {
      return BankAccountError.overBalance;
    } else if (depositPerDay + amount > maxDepositPerDay) {
      return BankAccountError.overMaxDepositPerDay;
    } else {
      depositPerDay += amount;
      balance += amount;
      history.add(BankAccountOperation.deposit);
      return null;
    }
  }

  BankAccountError? withdraw(int amount) {
    final charged = (amount + amount * chargeRate).toInt();
    if (locked) {
      return BankAccountError.locked;
    } else if (amount > maxWithdrawPerOnce) {
      return BankAccountError.overMaxWithdrawPerOnce;
    } else if (balance - charged < minBalance) {
      return BankAccountError.underBalance;
    } else if (withdrawPerDay + charged > maxWithdrawPerDay) {
      return BankAccountError.overMaxWithdrawPerDay;
    } else {
      withdrawPerDay += charged;
      balance -= charged;
      history.add(BankAccountOperation.withdraw);
      return null;
    }
  }
}

void main() {
  KiriCheck.verbosity = Verbosity.verbose;

  group('shrink', () {
    property('shrink', () {
      forAllStates(
        BankAccountBehavior(),
        (s) {
          // TODO
        },
      );
    });
  });
}
