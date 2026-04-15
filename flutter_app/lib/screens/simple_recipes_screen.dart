import 'package:flutter/material.dart';

import '../services/navigation_service.dart';
import '../components/common/unified_content_list.dart';
import '../components/common/content_item_card.dart';
import '../components/app_header.dart';

class SimpleRecipesScreen extends StatefulWidget {
  const SimpleRecipesScreen({Key? key}) : super(key: key);

  @override
  State<SimpleRecipesScreen> createState() => _SimpleRecipesScreenState();
}

class _SimpleRecipesScreenState extends State<SimpleRecipesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const AppHeader(
        title: 'Recettes',
        showNotifications: false,
        showProfile: false,
      ),
      body: UnifiedContentList(
        contentType: 'recipe',
        apiEndpoint: 'https://new.dinorapp.com/api/v1/recipes',
        itemsPerPage: 4,
        enableSearch: true,
        enableFilters: true,
        useGridView: false,
        itemBuilder: (item) => ContentItemCard(
          contentType: 'recipe',
          item: item,
          onTap: () => _navigateToRecipeDetail(item['id']?.toString() ?? ''),
        ),
        titleExtractor: (item) => item['title']?.toString() ?? '',
        imageExtractor: (item) => item['featured_image_url']?.toString() ?? '',
        descriptionExtractor: (item) => item['description']?.toString() ?? '',
        onItemTap: (item) => () => _navigateToRecipeDetail(item['id']?.toString() ?? ''),
      ),
    );
  }

  void _navigateToRecipeDetail(String recipeId) {
    if (recipeId.isNotEmpty) {
      NavigationService.pushNamed('/recipe-detail-unified/$recipeId');
    }
  }
}