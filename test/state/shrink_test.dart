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
      Action(
        'under min deposit per once',
        integer(min: 0, max: s.minDepositPerOnce - 1),
        (s, amount) {
          if (s.locked) {
            expect(s.deposit(amount), BankAccountResult.locked);
          } else {
            expect(
                s.deposit(amount),
                anyOf(
                  BankAccountResult.underMinDepositPerOnce,
                  BankAccountResult.overMaxSameOperationsPerDay,
                  BankAccountResult.overMaxOperationsPerDay,
                ));
          }
        },
      ),
      Action(
        'under max deposit per once',
        integer(min: s.minDepositPerOnce, max: s.maxDepositPerOnce),
        (s, amount) {
          if (s.locked) {
            expect(s.deposit(amount), BankAccountResult.locked);
          } else {
            expect(
                s.deposit(amount),
                anyOf(
                  BankAccountResult.success,
                  BankAccountResult.overMaxDepositPerDay,
                  BankAccountResult.overBalance,
                  BankAccountResult.overMaxSameOperationsPerDay,
                  BankAccountResult.overMaxOperationsPerDay,
                ));
          }
        },
      ),
      Action(
        'under deposit per day',
        integer(min: s.maxDepositPerOnce + 1, max: s.maxDepositPerDay),
        (s, amount) {
          if (s.locked) {
            expect(s.deposit(amount), BankAccountResult.locked);
          } else {
            expect(
                s.deposit(amount),
                anyOf(
                  BankAccountResult.overMaxDepositPerOnce,
                  BankAccountResult.overMaxSameOperationsPerDay,
                  BankAccountResult.overMaxOperationsPerDay,
                ));
          }
        },
      ),
      Action(
        'over max deposit per day',
        integer(min: s.maxDepositPerDay + 1),
        (s, amount) {
          if (s.locked) {
            expect(s.deposit(amount), BankAccountResult.locked);
          } else {
            expect(
                s.deposit(amount),
                anyOf(
                  BankAccountResult.overMaxDepositPerOnce,
                  BankAccountResult.overMaxSameOperationsPerDay,
                  BankAccountResult.overMaxOperationsPerDay,
                ));
          }
        },
      ),
      Action(
        'under min withdraw per once',
        integer(min: 0, max: s.minWithdrawPerOnce - 1),
        (s, amount) {
          if (s.locked) {
            expect(s.deposit(amount), BankAccountResult.locked);
          } else {
            expect(
                s.withdraw(amount),
                anyOf(
                  BankAccountResult.underMinWithdrawPerOnce,
                  BankAccountResult.overMaxSameOperationsPerDay,
                  BankAccountResult.overMaxOperationsPerDay,
                ));
          }
        },
      ),
      Action(
        'under max withdraw per once',
        integer(min: s.minWithdrawPerOnce, max: s.maxWithdrawPerOnce),
        (s, amount) {
          if (s.locked) {
            expect(s.deposit(amount), BankAccountResult.locked);
          } else {
            expect(
                s.withdraw(amount),
                anyOf(
                  BankAccountResult.success,
                  BankAccountResult.overMaxWithdrawPerDay,
                  BankAccountResult.underBalance,
                  BankAccountResult.overMaxSameOperationsPerDay,
                  BankAccountResult.overMaxOperationsPerDay,
                ));
          }
        },
      ),
      Action(
        'under max withdraw per day',
        integer(min: s.maxWithdrawPerOnce + 1, max: s.maxWithdrawPerDay),
        (s, amount) {
          if (s.locked) {
            expect(s.deposit(amount), BankAccountResult.locked);
          } else {
            expect(
                s.withdraw(amount),
                anyOf(
                  BankAccountResult.overMaxWithdrawPerOnce,
                  BankAccountResult.overMaxSameOperationsPerDay,
                  BankAccountResult.overMaxOperationsPerDay,
                ));
          }
        },
      ),
      Action(
        'over max withdraw per day',
        integer(min: s.maxWithdrawPerDay + 1),
        (s, amount) {
          if (s.locked) {
            expect(s.deposit(amount), BankAccountResult.locked);
          } else {
            expect(
                s.withdraw(amount),
                anyOf(
                  BankAccountResult.overMaxWithdrawPerOnce,
                  BankAccountResult.overMaxSameOperationsPerDay,
                  BankAccountResult.overMaxOperationsPerDay,
                ));
          }
        },
      ),
    ];
  }
}

final class BankAccountState extends State {
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
    if (locked) {
      return BankAccountResult.locked;
    } else if (amount > maxDepositPerOnce) {
      return BankAccountResult.overMaxDepositPerOnce;
    } else if (amount < minDepositPerOnce) {
      return BankAccountResult.underMinDepositPerOnce;
    } else if (depositPerDay + amount > maxDepositPerDay) {
      return BankAccountResult.overMaxDepositPerDay;
    } else if (balance + amount > maxBalance) {
      return BankAccountResult.overBalance;
    } else if (countOfLastOperationPerDay(BankAccountOperation.deposit) >
        maxSameOperationsPerDay) {
      return BankAccountResult.overMaxSameOperationsPerDay;
    } else if (history.length > maxOperationsPerDay) {
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
    if (locked) {
      return BankAccountResult.locked;
    } else if (amount > maxWithdrawPerOnce) {
      return BankAccountResult.overMaxWithdrawPerOnce;
    } else if (amount < minWithdrawPerOnce) {
      return BankAccountResult.underMinWithdrawPerOnce;
    } else if (amount > maxWithdrawPerDay) {
      return BankAccountResult.overMaxWithdrawPerDay;
    } else if (balance - charged < minBalance) {
      return BankAccountResult.underBalance;
    } else if (countOfLastOperationPerDay(BankAccountOperation.deposit) >
        maxSameOperationsPerDay) {
      return BankAccountResult.overMaxSameOperationsPerDay;
    } else if (history.length > maxOperationsPerDay) {
      return BankAccountResult.overMaxOperationsPerDay;
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
