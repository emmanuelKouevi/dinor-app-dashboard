import 'package:flutter/material.dart';

import '../services/navigation_service.dart';
import '../components/common/unified_content_list.dart';
import '../components/common/content_item_card.dart';
import '../components/app_header.dart';

class SimpleTipsScreen extends StatefulWidget {
  const SimpleTipsScreen({Key? key}) : super(key: key);

  @override
  State<SimpleTipsScreen> createState() => _SimpleTipsScreenState();
}

class _SimpleTipsScreenState extends State<SimpleTipsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const AppHeader(
        title: 'Astuces',
        showNotifications: false,
        showProfile: false,
      ),
      body: UnifiedContentList(
        contentType: 'tip',
        apiEndpoint: 'https://new.dinorapp.com/api/v1/tips',
        itemsPerPage: 4,
        enableSearch: true,
        enableFilters: true,
        useGridView: false,
        itemBuilder: (item) => ContentItemCard(
          contentType: 'tip',
          item: item,
          onTap: () => _navigateToTipDetail(item['id']?.toString() ?? ''),
        ),
        titleExtractor: (item) => item['title']?.toString() ?? '',
        imageExtractor: (item) => item['featured_image_url']?.toString() ?? '',
        descriptionExtractor: (item) => item['description']?.toString() ?? item['content']?.toString() ?? '',
        onItemTap: (item) => () => _navigateToTipDetail(item['id']?.toString() ?? ''),
      ),
    );
  }

  void _navigateToTipDetail(String tipId) {
    if (tipId.isNotEmpty) {
      NavigationService.pushNamed('/tip-detail-unified/$tipId');
    }
  }
}