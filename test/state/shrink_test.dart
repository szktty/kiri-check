import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:test/test.dart';

enum BankAccountError {
  alreadyLocked,
  locked,
  overMaxDeposit,
  overMaxWithdraw,
  overMaxBalance,
  underMinBalance,
}

final class BankAccountBehavior extends Behavior<BankAccountState> {
  @override
  BankAccountState createState() {
    return BankAccountState();
  }

  @override
  List<Command<BankAccountState>> generateCommands(BankAccountState s) {
    return [
      Action(
        'deposit',
        integer(min: 0, max: s.maxDeposit * 2),
        (s, amount) {
          print('deposit: $amount');
          expect(s.deposit(amount), isNull);
        },
      ),
      Action(
        'withdraw',
        integer(min: 0, max: s.maxWithdraw * 2),
        (s, amount) {
          print('withdraw: $amount');
          expect(s.withdraw(amount), isNull);
        },
      ),
      /*
      Action0(
        'lock',
        (s) {
          expect(s.lock(), isTrue);
        },
      ),
       */
    ];
  }
}

final class BankAccountState extends State {
  int balance = 10000;
  int maxDeposit = 5000;
  int maxWithdraw = 5000;
  int maxBalance = 100000;
  int minBalance = 0;
  bool locked = false;
  double chargeRate = 0.03;

  BankAccountError? lock() {
    if (locked) {
      return BankAccountError.alreadyLocked;
    }
    locked = true;
    return null;
  }

  BankAccountError? deposit(int amount) {
    if (locked) {
      return BankAccountError.locked;
    } else if (amount > maxDeposit) {
      return BankAccountError.overMaxDeposit;
    } else if (balance + amount > maxBalance) {
      return BankAccountError.overMaxBalance;
    }
    balance += amount;
    return null;
  }

  BankAccountError? withdraw(int amount) {
    final charged = (amount + amount * chargeRate).toInt();
    if (locked) {
      return BankAccountError.locked;
    } else if (amount > maxWithdraw) {
      return BankAccountError.overMaxWithdraw;
    } else if (balance - charged < minBalance) {
      return BankAccountError.underMinBalance;
    }
    balance -= charged;
    return null;
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
