import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:openfoodfacts/openfoodfacts.dart';
import 'package:smooth_app/database/product_query.dart';

/// Abstract helper for Simple Input Page.
///
/// * we retrieve the initial list of terms.
/// * we add a term to the list.
/// * we remove a term from the list.
abstract class AbstractSimpleInputPageHelper {
  /// Product we are about to edit.
  late Product product;

  /// Terms as they were initially then edited by the user.
  late List<String> _terms;

  /// "Have the terms been changed?"
  late bool _changed;

  /// Starts from scratch with a new (or refreshed) [Product].
  void reInit(final Product product) {
    this.product = product;
    _terms = initTerms();
    _changed = false;
  }

  final String _separator = ',';

  /// Returns the terms as they were initially in the product.
  @protected
  List<String> initTerms();

  /// Returns the current terms to be displayed.
  List<String> get terms => _terms;

  /// Returns true if the term was not in the list and then was added.
  bool addTerm(String term) {
    term = term.trim();
    if (term.isEmpty) {
      return false;
    }
    if (_terms.contains(term)) {
      return false;
    }
    _terms.add(term);
    _changed = true;
    return true;
  }

  /// Returns true if the term was in the list and then was removed.
  ///
  /// The things we build the interface, very unlikely to return false,
  /// as we remove existing items.
  bool removeTerm(final String term) {
    if (_terms.remove(term)) {
      _changed = true;
      return true;
    }
    return false;
  }

  /// Returns the title on the main "edit product" page.
  String getTitle(final AppLocalizations appLocalizations);

  /// Returns the subtitle on the main "edit product" page.
  String? getSubtitle(final AppLocalizations appLocalizations) => null;

  /// Returns the hint of the "add" text field.
  String getAddHint(final AppLocalizations appLocalizations);

  /// Returns additional examples about the "add" text field.
  String? getAddExplanations(final AppLocalizations appLocalizations) => null;

  /// Impacts a product in order to take the changes into account.
  @protected
  void changeProduct(final Product changedProduct);

  /// Returns null is no change was made, or a Product to be saved on the BE.
  Product? getChangedProduct() {
    if (!_changed) {
      return null;
    }
    final Product changedProduct = Product(barcode: product.barcode);
    changeProduct(changedProduct);
    return changedProduct;
  }

  @protected
  List<String> splitString(String? input) {
    if (input == null) {
      return <String>[];
    }
    input = input.trim();
    if (input.isEmpty) {
      return <String>[];
    }
    return input.split(_separator);
  }
}

/// Implementation for "Stores" of an [AbstractSimpleInputPageHelper].
class SimpleInputPageStoreHelper extends AbstractSimpleInputPageHelper {
  @override
  List<String> initTerms() => splitString(product.stores);

  @override
  void changeProduct(final Product changedProduct) =>
      changedProduct.stores = terms.join(_separator);

  @override
  String getTitle(final AppLocalizations appLocalizations) =>
      appLocalizations.edit_product_form_item_stores_title;

  @override
  String getAddHint(final AppLocalizations appLocalizations) =>
      appLocalizations.edit_product_form_item_stores_hint;
}

/// Implementation for "Emb Code" of an [AbstractSimpleInputPageHelper].
class SimpleInputPageEmbCodeHelper extends AbstractSimpleInputPageHelper {
  @override
  List<String> initTerms() => splitString(product.embCodes);

  @override
  void changeProduct(final Product changedProduct) =>
      changedProduct.embCodes = terms.join(_separator);

  @override
  String getTitle(final AppLocalizations appLocalizations) =>
      appLocalizations.edit_product_form_item_emb_codes_title;

  @override
  String getAddHint(final AppLocalizations appLocalizations) =>
      appLocalizations.edit_product_form_item_emb_codes_hint;

  @override
  String getAddExplanations(final AppLocalizations appLocalizations) =>
      appLocalizations.edit_product_form_item_emb_codes_explanations;
}

/// Abstraction, for "in language" field, of an [AbstractSimpleInputPageHelper].
abstract class AbstractSimpleInputPageInLanguageHelper
    extends AbstractSimpleInputPageHelper {
  final Map<String, String> _termToTags = <String, String>{};

  /// Returns the value of the tags list of field for a product.
  ///
  /// E.g. `product.categoriesTags`
  @protected
  List<String>? getTags();

  /// Returns the value of the translations of a field for a product.
  ///
  /// E.g. `product.categoriesTagsInLanguages`
  @protected
  Map<OpenFoodFactsLanguage, List<String>>? getInLanguages();

  /// Sets the value of a field for a product.
  ///
  /// e.g. `product.categories = value`
  @protected
  void setValue(final Product changedProduct, final String value);

  @override
  List<String> initTerms() {
    final List<String>? tags = getTags();
    final Map<OpenFoodFactsLanguage, List<String>>? inLanguages =
        getInLanguages();
    if (tags != null && inLanguages != null) {
      final List<String>? translations = inLanguages[_getLanguage()];
      if (translations != null && translations.length == tags.length) {
        for (int i = 0; i < translations.length; i++) {
          _termToTags[translations[i]] = tags[i];
        }
        return List<String>.from(translations);
      }
    }
    return <String>[];
  }

  @override
  void changeProduct(final Product changedProduct) {
    final StringBuffer result = StringBuffer();
    for (int i = 0; i < terms.length; i++) {
      final String term = terms[i];
      String? tag = _termToTags[term];
      tag ??= '${_getLanguage().code}:$term';
      if (i > 0) {
        result.write(_separator);
      }
      result.write(tag);
    }
    setValue(changedProduct, result.toString());
  }

  OpenFoodFactsLanguage _getLanguage() => ProductQuery.getLanguage()!;
}

/// Implementation for "Labels" of an [AbstractSimpleInputPageHelper].
class SimpleInputPageLabelHelper
    extends AbstractSimpleInputPageInLanguageHelper {
  @override
  List<String>? getTags() => product.labelsTags;

  @override
  Map<OpenFoodFactsLanguage, List<String>>? getInLanguages() =>
      product.labelsTagsInLanguages;

  @override
  void setValue(final Product changedProduct, final String value) =>
      changedProduct.labels = value;

  @override
  String getTitle(final AppLocalizations appLocalizations) =>
      appLocalizations.edit_product_form_item_labels_title;

  @override
  String getSubtitle(final AppLocalizations appLocalizations) =>
      appLocalizations.edit_product_form_item_labels_subtitle;

  @override
  String getAddHint(final AppLocalizations appLocalizations) =>
      appLocalizations.edit_product_form_item_labels_hint;
}

/// Implementation for "Categories" of an [AbstractSimpleInputPageHelper].
class SimpleInputPageCategoryHelper
    extends AbstractSimpleInputPageInLanguageHelper {
  @override
  List<String>? getTags() => product.categoriesTags;

  @override
  Map<OpenFoodFactsLanguage, List<String>>? getInLanguages() =>
      product.categoriesTagsInLanguages;

  @override
  void setValue(final Product changedProduct, final String value) =>
      changedProduct.categories = value;

  @override
  String getTitle(final AppLocalizations appLocalizations) =>
      appLocalizations.edit_product_form_item_categories_title;

  @override
  String getAddHint(final AppLocalizations appLocalizations) =>
      appLocalizations.edit_product_form_item_categories_hint;
}

/// Implementation for "Countries" of an [AbstractSimpleInputPageHelper].
class SimpleInputPageCountryHelper
    extends AbstractSimpleInputPageInLanguageHelper {
  @override
  List<String>? getTags() => product.countriesTags;

  @override
  Map<OpenFoodFactsLanguage, List<String>>? getInLanguages() =>
      product.countriesTagsInLanguages;

  @override
  void setValue(final Product changedProduct, final String value) =>
      changedProduct.countries = value;

  @override
  String getTitle(final AppLocalizations appLocalizations) =>
      appLocalizations.edit_product_form_item_countries_title;

  @override
  String getAddHint(final AppLocalizations appLocalizations) =>
      appLocalizations.edit_product_form_item_countries_hint;

  @override
  String getAddExplanations(final AppLocalizations appLocalizations) =>
      appLocalizations.edit_product_form_item_countries_explanations;
}