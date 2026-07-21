import 'dart:typed_data';

import 'package:solar_erp_app/shared/models/paginated_result.dart';
import 'package:solar_erp_app/shared/models/party_address_model.dart';

import 'models/quotation_model.dart';
import 'quotation_api_service.dart';

class QuotationRepository {
  final QuotationApiService _api;

  QuotationRepository(this._api);

  Future<PaginatedResult<QuotationModel>> list({
    String? status,
    String? customerId,
    int page = 1,
    int limit = 20,
  }) =>
      _api.list(
        status: status,
        customerId: customerId,
        page: page,
        limit: limit,
      );

  Future<QuotationModel> getById(String id) => _api.getById(id);

  Future<List<QuotationModel>> listInvoiceable() => _api.listInvoiceable();

  Future<List<QuotationModel>> pendingApprovals() => _api.pendingApprovals();

  Future<QuotationModel> create({
    required String customerId,
    required List<QuotationItemModel> items,
    String? notes,
    String? quotationNumber,
    DateTime? validUntil,
    PartyAddressModel? billTo,
    PartyAddressModel? shipTo,
    bool shipSameAsBill = true,
    Map<String, dynamic>? fromParty,
  }) {
    final resolvedShip = shipSameAsBill ? billTo : shipTo;
    return _api.create({
      'customerId': customerId,
      'items': items.map((e) => e.toCreateJson()).toList(),
      if (notes != null) 'notes': notes,
      if (quotationNumber != null && quotationNumber.trim().isNotEmpty)
        'quotation_number': quotationNumber.trim(),
      if (validUntil != null)
        'validUntil': validUntil.toIso8601String().split('T').first,
      if (billTo != null) 'billTo': billTo.toJson(),
      if (resolvedShip != null) 'shipTo': resolvedShip.toJson(),
      'shipSameAsBill': shipSameAsBill,
      if (fromParty != null && fromParty.isNotEmpty) 'fromParty': fromParty,
    });
  }

  Future<QuotationModel> update({
    required String id,
    required String customerId,
    required List<QuotationItemModel> items,
    String? notes,
    String? quotationNumber,
    DateTime? validUntil,
    PartyAddressModel? billTo,
    PartyAddressModel? shipTo,
    bool shipSameAsBill = true,
    Map<String, dynamic>? fromParty,
  }) {
    final resolvedShip = shipSameAsBill ? billTo : shipTo;
    return _api.update(id, {
      'customerId': customerId,
      'items': items.map((e) => e.toCreateJson()).toList(),
      if (notes != null) 'notes': notes,
      if (quotationNumber != null && quotationNumber.trim().isNotEmpty)
        'quotation_number': quotationNumber.trim(),
      if (validUntil != null)
        'validUntil': validUntil.toIso8601String().split('T').first,
      if (billTo != null) 'billTo': billTo.toJson(),
      if (resolvedShip != null) 'shipTo': resolvedShip.toJson(),
      'shipSameAsBill': shipSameAsBill,
      if (fromParty != null && fromParty.isNotEmpty) 'fromParty': fromParty,
    });
  }

  Future<QuotationModel> submit(String id) => _api.submit(id);

  Future<QuotationModel> approve(String id) => _api.approve(id);

  Future<QuotationModel> reject(String id, String reason) =>
      _api.reject(id, reason);

  Future<Uint8List> downloadPdf(String id) => _api.downloadPdf(id);

  Future<void> sendEmail(String id, {String? email}) =>
      _api.sendEmail(id, email: email);
}
