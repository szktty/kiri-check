import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:test/test.dart';

enum BankAccountResult {
  success,
  locked,
  underMinDepositPerOnce,
  underMinWithdrawPerOnce,
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

// TODO: 完全な実装。すべて成功すべき
final class BankAccountFullBehavior extends Behavior<BankAccountState> {
  @override
  BankAccountState createState() {
    return BankAccountState();
  }

  @override
  List<Command<BankAccountState>> generateCommands(BankAccountState s) {
    return [
      Action0(
        'next day',
        (s) {
          s.nextDay();
        },
      ),
      Action(
        'under min deposit per once',
        integer(min: 0, max: s.minDepositPerOnce - 1),
        (s, amount) {
          expect(s.deposit(amount), BankAccountResult.underMinDepositPerOnce);
        },
      ),
      Action(
        'under deposit per once',
        integer(min: s.minDepositPerOnce, max: s.maxDepositPerOnce),
        (s, amount) {
          expect(
              s.deposit(amount),
              anyOf(
                BankAccountResult.success,
                BankAccountResult.overBalance,
                BankAccountResult.overMaxSameOperationsPerDay,
                BankAccountResult.overMaxOperationsPerDay,
              ));
        },
      ),
      Action(
        'under deposit per day',
        integer(min: s.maxDepositPerOnce, max: s.maxDepositPerDay),
        (s, amount) {
          expect(
              s.deposit(amount),
              anyOf(
                BankAccountResult.success,
                BankAccountResult.overBalance,
                BankAccountResult.overMaxDepositPerOnce,
                BankAccountResult.overMaxSameOperationsPerDay,
                BankAccountResult.overMaxOperationsPerDay,
              ));
        },
      ),
      Action(
        'over max deposit per day',
        integer(min: s.maxDepositPerDay + 1),
        (s, amount) {
          expect(
              s.deposit(amount),
              anyOf(
                BankAccountResult.overMaxDepositPerDay,
                BankAccountResult.overMaxSameOperationsPerDay,
                BankAccountResult.overMaxOperationsPerDay,
              ));
        },
      ),
      Action(
        'deposit under balance',
        integer(min: s.maxDepositPerDay + 1, max: s.maxBalance),
        (s, amount) {
          expect(
              s.deposit(amount),
              anyOf(
                BankAccountResult.success,
                BankAccountResult.overBalance,
              ));
        },
      ),
      Action(
        'deposit over balance',
        integer(min: s.maxBalance + 1),
        (s, amount) {
          expect(s.deposit(amount), BankAccountResult.overBalance);
        },
      ),
      Action(
        'under min withdraw per once',
        integer(min: 0, max: s.minWithdrawPerOnce - 1),
        (s, amount) {
          expect(s.withdraw(amount), BankAccountResult.underMinWithdrawPerOnce);
        },
      ),
      Action(
        'under max withdraw per once',
        integer(min: s.minWithdrawPerOnce, max: s.maxWithdrawPerOnce),
        (s, amount) {
          expect(s.withdraw(amount), BankAccountResult.overMaxWithdrawPerOnce);
        },
      ),
      Action(
        'under max withdraw per day',
        integer(min: s.minWithdrawPerOnce + 1, max: s.maxWithdrawPerDay),
        (s, amount) {
          expect(s.withdraw(amount), BankAccountResult.overMaxWithdrawPerDay);
        },
      ),
      Action(
        'over max withdraw per day',
        integer(min: s.maxWithdrawPerDay + 1),
        (s, amount) {
          expect(s.withdraw(amount), BankAccountResult.overMaxWithdrawPerDay);
        },
      ),
      Action(
        'withdraw under balance',
        integer(min: s.minWithdrawPerOnce + 1, max: s.maxWithdrawPerDay),
        (s, amount) {
          expect(
              s.withdraw(amount),
              anyOf(
                BankAccountResult.success,
                BankAccountResult.underBalance,
              ));
        },
      ),
      Action(
        'withdraw over balance',
        integer(min: s.maxWithdrawPerDay + 1),
        (s, amount) {
          expect(s.withdraw(amount), BankAccountResult.underBalance);
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

  int minDepositPerOnce = 1000;
  int minWithdrawPerOnce = 1000;

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

  void lock() {
    locked = true;
  }

  void unlock() {
    locked = false;
  }

  BankAccountResult deposit(int amount) {
    if (locked) {
      return BankAccountResult.locked;
    } else if (amount > maxDepositPerOnce) {
      return BankAccountResult.overMaxDepositPerOnce;
    } else if (balance + amount > maxBalance) {
      return BankAccountResult.overBalance;
    } else if (depositPerDay + amount > maxDepositPerDay) {
      return BankAccountResult.overMaxDepositPerDay;
    } else {
      depositPerDay += amount;
      balance += amount;
      history.add(BankAccountOperation.deposit);
      return BankAccountResult.success;
    }
  }

  BankAccountResult withdraw(int amount) {
    final charged = (amount + amount * chargeRate).toInt();
    if (locked) {
      return BankAccountResult.locked;
    } else if (amount > maxWithdrawPerOnce) {
      return BankAccountResult.overMaxWithdrawPerOnce;
    } else if (balance - charged < minBalance) {
      return BankAccountResult.underBalance;
    } else if (withdrawPerDay + charged > maxWithdrawPerDay) {
      return BankAccountResult.overMaxWithdrawPerDay;
    } else {
      withdrawPerDay += charged;
      balance -= charged;
      history.add(BankAccountOperation.withdraw);
      return BankAccountResult.success;
    }
  }
}

void main() {
  KiriCheck.verbosity = Verbosity.verbose;

  group('shrink', () {
    property('shrink', () {
      forAllStates(
        BankAccountFullBehavior(),
        (s) {
          // TODO
        },
      );
    });
  });
}
