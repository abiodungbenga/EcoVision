import 'package:get/get.dart';
import 'package:network_internet_checker/network_internet_checker.dart';

import '../../core/services/api_key_service.dart';
import '../../core/services/indexing_service.dart';
import '../../core/services/network_status_service.dart';
import '../../core/services/video_service.dart';
import '../../core/services/vmodal_service.dart';
import '../../core/services/discovery_service.dart';
import '../../core/services/research_service.dart';

class InitialBinding extends Bindings {
  InitialBinding({
    this.internetChecker,
    this.apiKeyService,
    this.vmodalService,
  });

  final InternetChecker? internetChecker;
  final ApiKeyService? apiKeyService;
  final VModalService? vmodalService;

  @override
  void dependencies() {
    Get.put<NetworkStatusService>(
      NetworkStatusService(checker: internetChecker),
      permanent: true,
    );
    final vmodal = Get.put<VModalService>(
      vmodalService ?? VModalService(),
      permanent: true,
    );
    final videos = Get.put<VideoService>(VideoService(), permanent: true);
    final apiKeys = Get.put<ApiKeyService>(
      apiKeyService ?? ApiKeyService(vmodalService: vmodal),
      permanent: true,
    );

    // Permanent so indexing keeps polling while the user navigates away from
    // the Upload screen.
    final indexing = Get.put<IndexingService>(
      IndexingService(
        vmodalService: vmodal,
        videoService: videos,
        apiKeyService: apiKeys,
      ),
      permanent: true,
    );
    apiKeys.onCredentialsChanged = indexing.stopPolling;
    Get.put<DiscoveryService>(DiscoveryService(), permanent: true);
    Get.put<ResearchService>(ResearchService(), permanent: true);
  }
}
