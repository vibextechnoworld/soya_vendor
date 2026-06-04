import 'package:flutter_test/flutter_test.dart';
import 'package:soya_app/features/home/controller/billing_controller.dart';
import 'package:soya_app/features/home/model/deduction_master_model.dart';
import 'package:soya_app/features/home/model/quality_rate_model.dart';
import 'package:soya_app/features/home/model/goni_type_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('BillingController Logic Tests', () {
    late BillingController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      controller = BillingController();
    });

    test('Fraction unitHint parsing (1/4 and 0.5)', () {
      final master = DeductionMaster(
        id: 'm1',
        name: 'Master 1',
        variables: [
          DeductionVariable(code: 'fm', label: 'FM', unitHint: '1/4'),
          DeductionVariable(
              code: 'moisture', label: 'Moisture', unitHint: '0.5'),
        ],
      );

      controller.setDeductionMasters([master]);

      expect(controller.getUnitHint('m1', 'fm'), 0.25);
      expect(controller.getUnitHint('m1', 'moisture'), 0.5);
    });

    test('allowedValueByCode parsing with + and *', () {
      final master = DeductionMaster(
        id: 'm_var',
        name: 'Variation Master',
        variables: [
          DeductionVariable(code: 'v1', label: 'V1'),
          DeductionVariable(code: 'v2', label: 'V2'),
        ],
      );

      controller.setDeductionMasters([master]);

      // Test with +
      controller.selectDeductionVariation('5+10', master);
      expect(controller.allowedValueByCode('v1'), 5.0);
      expect(controller.allowedValueByCode('v2'), 10.0);

      // Test with *
      controller.selectDeductionVariation('3*7', master);
      expect(controller.allowedValueByCode('v1'), 3.0);
      expect(controller.allowedValueByCode('v2'), 7.0);
    });

    test('Quality rate selection updates controller state', () {
      final rate = QualityRateData(quality: 'first_quality', rate: 5500);
      controller.selectQuality(rate);
      expect(controller.selectedQuality?.rate, 5500);
      expect(controller.selectedQuality?.quality, 'first_quality');
    });

    test('Goni type selection affects estimation logic', () {
      final goni = GoniType(id: 'g1', name: 'Plastic', weightPerBag: 0.5);
      controller.selectGoniType(goni);
      expect(controller.selectedGoniType?.weightPerBag, 0.5);
    });

    test('GoniType equality based on ID', () {
      final g1 = GoniType(id: '1', name: 'Type A');
      final g2 = GoniType(id: '1', name: 'Type A Updated');
      final g3 = GoniType(id: '2', name: 'Type A');

      expect(g1 == g2, true);
      expect(g1 == g3, false);
      expect(g1.hashCode == g2.hashCode, true);
    });

    test('DeductionMaster equality based on ID', () {
      final m1 = DeductionMaster(id: 'm1', name: 'Master A');
      final m2 = DeductionMaster(id: 'm1', name: 'Master A Updated');
      final m3 = DeductionMaster(id: 'm2', name: 'Master A');

      expect(m1 == m2, true);
      expect(m1 == m3, false);
      expect(m1.hashCode == m2.hashCode, true);
    });
  });
}
