import 'package:get/get.dart';

import '../data/stock_model.dart';
import '../services/stock_service.dart';


class StockController extends GetxController {
  final StockService _stockService = StockService();
  var stockList = <StockModel>[].obs;
  var isLoading = false.obs;

  Future<void> fetchStocks() async {
    try {
      isLoading.value = true;
      final stocks = await _stockService.getAllStocks();
      stockList.assignAll(stocks);
    } catch (e) {
      // Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addStock(StockModel stock) async {
    try {
      isLoading.value = true;
      final newStock = await _stockService.createStock(stock);
      stockList.add(newStock);
    } catch (e) {
      // Get.snackbar('Error', e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
