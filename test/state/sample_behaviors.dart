import 'package:kiri_check/kiri_check.dart';
import 'package:kiri_check/stateful_test.dart';
import 'package:test/test.dart';

import 'sample_model.dart';
import 'sample_system.dart';

class BankAccountBehavior extends Behavior<BankAccountModel, BankSystem> {
  @override
  BankAccountModel createState() {
    return BankAccountModel();
  }

  @override
  BankSystem createSystem(BankAccountModel state) {
    return BankSystem()..register(state.id);
  }

  Action0<BankAccountModel, BankSystem> nextDayAction() {
    return Action0(
      'next day',
      (s, system) {
        s.nextDay();
      },
    );
  }

  List<Action0<BankAccountModel, BankSystem>> freezeActions() {
    return [
      Action0(
        'freeze',
        (s, system) {
          expect(s.freeze(), system.freeze(s.id));
        },
        postcondition: (s, system) {
          return s.frozen && system.frozen(s.id);
        },
      ),
      Action0(
        'unfreeze',
        (s, system) {
          expect(s.unfreeze(), system.unfreeze(s.id));
        },
        postcondition: (s, system) {
          return !s.frozen && !system.frozen(s.id);
        },
      ),
    ];
  }

  Action<BankAccountModel, BankSystem, int> amountAction(
    String description,
    void Function(BankAccountModel, BankSystem, int) action, {
    String? reason,
    int min = 0,
    int? max,
  }) {
    return Action(
      description,
      integer(min: min, max: max),
      action,
      postcondition: (s, system) {
        return s.frozen == system.frozen(s.id) &&
            s.balance == system.getBalance(s.id);
      },
    );
  }

  Action<BankAccountModel, BankSystem, int> depositAction(
    String description, {
    String? reason,
    int min = 0,
    int? max,
  }) =>
      amountAction(
        description,
        (s, system, amount) =>
            expect(s.deposit(amount), system.deposit(s.id, amount)),
        reason: reason,
        min: min,
        max: max,
      );

  Action<BankAccountModel, BankSystem, int> withdrawAction(
    String description, {
    String? reason,
    int min = 0,
    int? max,
  }) =>
      amountAction(
        description,
        (s, system, amount) =>
            expect(s.withdraw(amount), system.withdraw(s.id, amount)),
        reason: reason,
        min: min,
        max: max,
      );

  List<Command<BankAccountModel, BankSystem>> basicDepositActions(
          BankAccountModel s) =>
      [
        depositAction(
          'over max deposit per once',
          max: s.settings.maxDepositPerDay,
        ),
        depositAction(
          'over max deposit per day',
          min: s.settings.maxDepositPerDay + 1,
        ),
      ];

  List<Command<BankAccountModel, BankSystem>> basicWithdrawActions(
          BankAccountModel s) =>
      [
        withdrawAction(
          'over max withdraw per once',
          max: s.settings.maxWithdrawPerDay,
        ),
        withdrawAction(
          'over max withdraw per day',
          min: s.settings.maxWithdrawPerDay + 1,
        ),
      ];

  @override
  List<Command<BankAccountModel, BankSystem>> generateCommands(
      BankAccountModel s) {
    return [
      nextDayAction(),
      ...freezeActions(),
      ...basicDepositActions(s),
      ...basicWithdrawActions(s),
    ];
  }
}

/*
final class BankAccountFreezeNotWorkingBehavior extends BankAccountBehavior {
  @override
  BankAccountModel createState() => BankAccountFreezeNotWorking();
}

final class BankAccountFreezeNotWorking extends BankAccountModel {
  @override
  bool validateFrozen() => false;
}


 */
