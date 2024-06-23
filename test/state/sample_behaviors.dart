import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:test/test.dart';

import 'sample_model.dart';
import 'sample_system.dart';

class BankAccountBehavior
    extends Behavior<BankAccountModel, BankAccountSystem> {
  BankAccountManager? manager;

  @override
  void setUp() {
    manager = BankAccountManager();
  }

  @override
  BankAccountModel initialState() {
    return BankAccountModel();
  }

  @override
  BankAccountSystem createSystem(BankAccountModel state) {
    return manager!.register(state.id);
  }

  Action0<BankAccountModel, BankAccountSystem, bool> nextDayAction() {
    return Action0(
      'next day',
      nextState: (s) => s.nextDay(),
      run: (system) {
        system.nextDay();
        return system.frozen;
      },
      postcondition: (s, frozen) {
        return frozen == false;
      },
    );
  }

  List<Action0<BankAccountModel, BankAccountSystem, bool>> freezeActions() {
    return [
      Action0(
        'freeze',
        nextState: (s) => s.freeze(),
        run: (system) {
          system.freeze();
          return system.frozen;
        },
        postcondition: (s, frozen) {
          return frozen == true;
        },
      ),
      Action0(
        'unfreeze',
        nextState: (s) => s.unfreeze(),
        run: (system) {
          system.unfreeze();
          return system.frozen;
        },
        postcondition: (s, frozen) {
          return frozen == false;
        },
      ),
    ];
  }

  Command<BankAccountModel, BankAccountSystem> depositAction(
    String description, {
    int min = 0,
    int? max,
  }) =>
      Action(
        description,
        integer(min: min, max: max),
        nextState: (s, amount) => s.deposit(amount),
        run: (system, amount) {
          system.deposit(amount);
          return system.balance;
        },
        postcondition: (s, amount, balance) {
          return s.balance + amount == balance;
        },
      );

  Command<BankAccountModel, BankAccountSystem> withdrawAction(
    String description, {
    int min = 0,
    int? max,
  }) =>
      Action(
        description,
        integer(min: min, max: max),
        nextState: (s, amount) => s.withdraw(amount),
        run: (system, amount) {
          system.withdraw(amount);
          return system.balance;
        },
        postcondition: (s, amount, balance) {
          return s.balance - amount == balance;
        },
      );

  List<Command<BankAccountModel, BankAccountSystem>> basicDepositActions(
    BankAccountModel s,
  ) =>
      [
        depositAction(
          'valid deposit per once',
          max: s.settings.maxDepositPerDay,
        ),
        depositAction(
          'over max deposit per day',
          min: s.settings.maxDepositPerDay + 1,
        ),
      ];

  List<Command<BankAccountModel, BankAccountSystem>> basicWithdrawActions(
    BankAccountModel s,
  ) =>
      [
        withdrawAction(
          'valid withdraw per once',
          max: s.settings.maxWithdrawPerDay,
        ),
        withdrawAction(
          'over max withdraw per day',
          min: s.settings.maxWithdrawPerDay + 1,
        ),
      ];

  @override
  List<Command<BankAccountModel, BankAccountSystem>> generateCommands(
    BankAccountModel s,
  ) {
    return [
      nextDayAction(),
      ...freezeActions(),
      ...basicDepositActions(s),
      ...basicWithdrawActions(s),
    ];
  }

  @override
  void destroySystem(BankAccountSystem system) {}
}
