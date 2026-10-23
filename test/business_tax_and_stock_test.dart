import 'package:flutter_test/flutter_test.dart';
import 'package:laci/data/models/business_model.dart';
import 'package:laci/data/models/product_model.dart';
import 'package:laci/domain/entities/business_entity.dart';
import 'package:laci/domain/entities/product_entity.dart';

void main() {
  group('Business Tax & Service Charge Entity and Model Tests', () {
    test('BusinessInfo defaults tax and service charge to disabled and zero', () {
      final now = DateTime.now();
      final business = BusinessInfo(
        id: 'biz-1',
        businessName: 'Warung Kopi Laci',
        createdAt: now,
        updatedAt: now,
      );

      expect(business.isTaxEnabled, false);
      expect(business.taxRate, 0.0);
      expect(business.taxName, 'Pajak');
      expect(business.isServiceChargeEnabled, false);
      expect(business.serviceChargeRate, 0.0);
      expect(business.isPriceInclusiveTax, false);
    });

    test('BusinessInfo copyWith updates tax and service charge correctly', () {
      final now = DateTime.now();
      final business = BusinessInfo(
        id: 'biz-1',
        businessName: 'Warung Kopi Laci',
        createdAt: now,
        updatedAt: now,
      );

      final updated = business.copyWith(
        isTaxEnabled: true,
        taxRate: 11.0,
        taxName: 'PPN',
        isServiceChargeEnabled: true,
        serviceChargeRate: 5.0,
        isPriceInclusiveTax: true,
      );

      expect(updated.isTaxEnabled, true);
      expect(updated.taxRate, 11.0);
      expect(updated.taxName, 'PPN');
      expect(updated.isServiceChargeEnabled, true);
      expect(updated.serviceChargeRate, 5.0);
      expect(updated.isPriceInclusiveTax, true);
    });

    test('BusinessInfoModel serialization and deserialization roundtrip', () {
      final now = DateTime.now();
      final model = BusinessInfoModel(
        id: 'biz-1',
        businessName: 'Resto Enak',
        address: 'Jl. Sudirman 1',
        phone: '08123456789',
        email: 'info@resto.com',
        createdAt: now,
        updatedAt: now,
        isTaxEnabled: true,
        taxRate: 10.0,
        taxName: 'PB1',
        isServiceChargeEnabled: true,
        serviceChargeRate: 5.0,
        isPriceInclusiveTax: false,
      );

      final json = model.toJson();
      expect(json['isTaxEnabled'], true);
      expect(json['taxRate'], 10.0);
      expect(json['taxName'], 'PB1');
      expect(json['isServiceChargeEnabled'], true);
      expect(json['serviceChargeRate'], 5.0);
      expect(json['isPriceInclusiveTax'], false);

      final fromJson = BusinessInfoModel.fromJson(json);
      expect(fromJson.isTaxEnabled, true);
      expect(fromJson.taxRate, 10.0);
      expect(fromJson.taxName, 'PB1');
      expect(fromJson.isServiceChargeEnabled, true);
      expect(fromJson.serviceChargeRate, 5.0);
      expect(fromJson.isPriceInclusiveTax, false);

      final entity = fromJson.toEntity();
      expect(entity.isTaxEnabled, true);
      expect(entity.taxRate, 10.0);
      expect(entity.taxName, 'PB1');

      final fromEntity = BusinessInfoModel.fromEntity(entity);
      expect(fromEntity.isTaxEnabled, true);
      expect(fromEntity.taxRate, 10.0);
      expect(fromEntity.taxName, 'PB1');
    });
  });

  group('Product Track Stock Entity and Model Tests', () {
    test('Product defaults trackStock to true', () {
      final now = DateTime.now();
      final product = Product(
        id: 'p-1',
        categoryId: 'c-1',
        name: 'Nasi Goreng Spesial',
        price: 25000,
        costPrice: 15000,
        stock: 0,
        createdAt: now,
        updatedAt: now,
      );

      expect(product.trackStock, true);
    });

    test('Product supports trackStock set to false (e.g. freshly made F&B / services)', () {
      final now = DateTime.now();
      final product = Product(
        id: 'p-2',
        categoryId: 'c-1',
        name: 'Es Teh Manis',
        price: 5000,
        costPrice: 1500,
        stock: 0,
        trackStock: false,
        createdAt: now,
        updatedAt: now,
      );

      expect(product.trackStock, false);

      final copied = product.copyWith(trackStock: true);
      expect(copied.trackStock, true);
    });

    test('ProductModel serialization and deserialization preserves trackStock', () {
      final now = DateTime.now();
      final model = ProductModel(
        id: 'p-3',
        categoryId: 'c-1',
        name: 'Jasa Desain Menu',
        price: 100000,
        costPrice: 0,
        stock: 0,
        trackStock: false,
        createdAt: now,
        updatedAt: now,
      );

      final json = model.toJson();
      expect(json['trackStock'], false);

      final fromJson = ProductModel.fromJson(json);
      expect(fromJson.trackStock, false);

      final entity = fromJson.toEntity();
      expect(entity.trackStock, false);

      final fromEntity = ProductModel.fromEntity(entity);
      expect(fromEntity.trackStock, false);
    });
  });

  group('Tax & Service Charge Calculation Formula Tests', () {
    test('Tax Exclusive calculation adds tax and service charge on top of net subtotal', () {
      const subtotal = 100000.0;
      const discount = 10000.0; // Net = 90,000
      const netSubtotal = subtotal - discount;

      const taxRate = 10.0; // 10%
      const serviceRate = 5.0; // 5%

      final taxAmount = netSubtotal * (taxRate / 100); // 9,000
      final serviceAmount = netSubtotal * (serviceRate / 100); // 4,500
      final grandTotal = netSubtotal + taxAmount + serviceAmount; // 103,500

      expect(taxAmount, 9000.0);
      expect(serviceAmount, 4500.0);
      expect(grandTotal, 103500.0);
    });

    test('Tax Inclusive calculation extracts tax from price and calculates grand total', () {
      const subtotal = 110000.0; // inclusive of 10% tax
      const discount = 0.0;
      const netSubtotal = subtotal - discount;

      const taxRate = 10.0; // 10%
      const serviceRate = 5.0; // 5%

      // Net without tax = 110,000 / 1.10 = 100,000
      // Tax amount = 110,000 - 100,000 = 10,000
      final taxAmount = netSubtotal - (netSubtotal / (1 + (taxRate / 100)));
      final serviceAmount = (netSubtotal - taxAmount) * (serviceRate / 100); // 5% of base = 5,000
      final grandTotal = netSubtotal + serviceAmount; // 115,000

      expect(taxAmount, closeTo(10000.0, 0.01));
      expect(serviceAmount, closeTo(5000.0, 0.01));
      expect(grandTotal, closeTo(115000.0, 0.01));
    });

    test('Disabled tax and service charge produces 0 tax and total equals net subtotal', () {
      const subtotal = 50000.0;
      const discount = 5000.0;
      const netSubtotal = subtotal - discount;

      double computeTax(bool isEnabled, double amount) =>
          isEnabled ? amount * 0.1 : 0.0;
      double computeService(bool isEnabled, double amount) =>
          isEnabled ? amount * 0.05 : 0.0;

      final taxAmount = computeTax(false, netSubtotal);
      final serviceAmount = computeService(false, netSubtotal);
      final grandTotal = netSubtotal + taxAmount + serviceAmount;

      expect(taxAmount, 0.0);
      expect(serviceAmount, 0.0);
      expect(grandTotal, 45000.0);
    });
  });
}
