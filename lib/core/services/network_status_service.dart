import 'package:get/get.dart';
import 'package:network_internet_checker/network_internet_checker.dart';

class NetworkStatusService extends GetxService {
  NetworkStatusService({InternetChecker? checker})
    : checker = checker ?? InternetChecker.instance;

  final InternetChecker checker;
}
