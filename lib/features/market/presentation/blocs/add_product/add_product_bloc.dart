import 'package:asoud/core/helper/enum_changer.dart';
import 'package:asoud/features/market/data/model/product_model.dart';
import 'package:asoud/features/market/data/model/theme_model_model.dart';
import 'package:asoud/core/ui/ui_status.dart';
import 'package:bloc/bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:asoud/features/market/domain/repository/product_repository.dart';
import 'package:asoud/core/network/app_result.dart';
import 'package:asoud/core/models/dto/product_dto.dart';

part 'add_product_event.dart';
part 'add_product_state.dart';

class AddProductBloc extends Bloc<AddProductEvent, AddProductState> {
  final ProductRepository productRepository;
  AddProductBloc(this.productRepository) : super(AddProductState.initial()) {
    on<ResetDataEvent>((event, emit) => emit(AddProductState.initial()));
    on<AddProductEvent>((event, emit) {});
    on<ProductTypeEvent>(_changeProductType);
    on<SetIsMarketerEvent>(_changeMarketerType);
    on<SetIsRequirementEvent>(_changeIsRequirementType);
    on<SetCategoryEvent>(_changeCategory);
    on<ProductPriceStockEvent>(_changeProductPriceStockExtra);
    on<ChangeProductStockEvent>(_changeProductStock);
    on<DiscountTypeEvent>(_changeDiscountType);
    on<DiscountValuesEvent>(_changeDiscountValues);
    on<ProductExtraEvent>(_changeProductExtra);
    on<LoadProductListEvent>(_loadProductList);
    on<ChangeProductGiftAndRequiredEvent>(_changeProductRequiredGifted);
    on<ProductTagSaleEvent>(_changeProductTgSale);
    on<AddTagsEvent>(_addTags);
    on<AddKeywordsEvent>(_addKeywords);
    on<RemoveKeywordsEvent>(_removeKeywords);
    on<SubmitNewProductEvent>(_submitNewProduct);
    on<UpdatePublishStatusEvent>(_updatePublishStatus);
    on<UpdateProductDetailEvent>(_updateProductDetail);
    on<UpdateCategoryImageEvent>(_updateCategoryImage);
    on<SubmitThemeWithProductEvent>(_submitAndUpdatewithProduct);
  }

  _changeProductType(ProductTypeEvent event, Emitter<AddProductState> emit) {
    emit(state.copyWith(productType: event.type));
  }

  _changeMarketerType(SetIsMarketerEvent event, Emitter<AddProductState> emit) {
    emit(state.copyWith(isMarketer: event.isMarketer));
  }

  _changeIsRequirementType(
    SetIsRequirementEvent event,
    Emitter<AddProductState> emit,
  ) {
    emit(state.copyWith(isRequirement: event.isRequirement));
  }

  _changeCategory(SetCategoryEvent event, Emitter<AddProductState> emit) {
    emit(
      state.copyWith(
        selectedCategoryName: event.selectedCategoryName,
        selectedCategoryId: event.selectedCategoryId,
      ),
    );
  }

  _changeProductStock(
    ChangeProductStockEvent event,
    Emitter<AddProductState> emit,
  ) {
    emit(state.copyWith(productStock: event.stock));
  }

  _changeProductPriceStockExtra(
    ProductPriceStockEvent event,
    Emitter<AddProductState> emit,
  ) {
    emit(
      state.copyWith(
        productStockEnable: event.stockEnable,
        productPriceEnable: event.priceEnable,
      ),
    );
  }

  _changeDiscountType(DiscountTypeEvent event, Emitter<AddProductState> emit) {
    emit(state.copyWith(discountType: event.type));
  }

  _changeDiscountValues(
    DiscountValuesEvent event,
    Emitter<AddProductState> emit,
  ) {
    emit(
      state.copyWith(
        discountPercentage: event.percentage,
        discountPeople: event.peopleNumber,
        discountDays: event.daysNumber,
        discountPosition: event.position,
      ),
    );
  }

  _changeProductExtra(ProductExtraEvent event, Emitter<AddProductState> emit) {
    emit(state.copyWith(productGift: event.gift, productExtra: event.extra));
  }

  _changeProductRequiredGifted(
    ChangeProductGiftAndRequiredEvent event,
    Emitter<AddProductState> emit,
  ) {
    emit(
      state.copyWith(
        selectedProductGift: event.selectedProductGift,
        selectedProductExtra: event.selectedProductExtra,
      ),
    );
  }

  _changeProductTgSale(
    ProductTagSaleEvent event,
    Emitter<AddProductState> emit,
  ) {
    emit(
      state.copyWith(
        productTag: event.tag,
        productPosition: event.position,
        productSellType: event.sellType,
        productSendPrice: event.sendPrice,
      ),
    );
  }

  _addTags(AddTagsEvent event, Emitter<AddProductState> emit) {
    emit(state.copyWith(tags: [...state.tags, event.tag]));
  }

  _addKeywords(AddKeywordsEvent event, Emitter<AddProductState> emit) {
    emit(state.copyWith(keywords: [...state.keywords, event.keyword]));
  }

  _removeKeywords(RemoveKeywordsEvent event, Emitter<AddProductState> emit) {
    emit(
      state.copyWith(
        keywords:
            state.keywords
                .where((element) => element != event.keyword)
                .toList(),
      ),
    );
  }

  _loadProductList(LoadProductListEvent event, Emitter<AddProductState> emit) async {
    emit(state.copyWith(giftStatus: const UiLoading()));
    final res = await productRepository.listOwner(event.marketId);
    if (res is Success<List<ProductListItemDto>>) {
      final product = res.data.map((e) => ThemeProductModel.fromJson(e.toJson())).toList();
      emit(state.copyWith(giftStatus: const UiSuccess(), productList: product));
    } else {
      emit(state.copyWith(giftStatus: UiError(res.error.message)));
    }
  }

  _updateCategoryImage(
    UpdateCategoryImageEvent event,
    Emitter<AddProductState> emit,
  ) {
    final currentImages = state.selectedCategoryImage ?? [];
    final currentImageFiles = state.selectedCategoryImageFile ?? [];

    emit(
      state.copyWith(
        selectedCategoryImage: [...currentImages, event.selectedCategoryImage],
        selectedCategoryImageFile: [
          ...currentImageFiles,
          event.selectedCategoryImageFile!,
        ],
      ),
    );
  }

  _updatePublishStatus(
    UpdatePublishStatusEvent event,
    Emitter<AddProductState> emit,
  ) {
    emit(state.copyWith(publishStatus: event.publishStatus));
  }

  _updateProductDetail(
    UpdateProductDetailEvent event,
    Emitter<AddProductState> emit,
  ) {
    emit(
      state.copyWith(
        productName: event.productName ?? state.productName,
        productDescription:
            event.productDescription ?? state.productDescription,
        productTechnicalDescription:
            event.productTechnicalDescription ??
            state.productTechnicalDescription,
      ),
    );
  }

  _submitAndUpdatewithProduct(
    SubmitThemeWithProductEvent event,
    Emitter<AddProductState> emit,
  ) async {}
  _submitNewProduct(SubmitNewProductEvent event, Emitter<AddProductState> emit) async {
    emit(state.copyWith(status: const UiLoading()));
    try {
      if (state.discountType != DiscountType.none) {
        final discountRes = await productRepository.createDiscount({
          'productId': event.market,
          'position': tagPositionEnumChanger(state.discountPosition),
          'percentage': state.discountPercentage,
          'duration': state.discountDays,
        });
        if (discountRes is Failure<bool>) {
          emit(state.copyWith(status: UiError(discountRes.error.message)));
          return;
        }
      }
      final dto = ProductCreateDto(
        market: event.market,
        type: state.productType.name,
        name: event.name,
        description: event.description,
        technicalDetails: event.technicalDetail,
        subCategory: state.selectedCategoryId,
        keywords: state.keywords,
        stock: state.productStock,
        price: state.productPrice,
        mainPrice: state.productPrice,
        colleaguePrice: state.productPrice,
        marketerPrice: state.productPrice,
        maximumSellPrice: state.productPrice,
        status: publishStatusEnumChanger(state.publishStatus),
        requiredProduct: state.selectedProductGift?.id ?? '',
        giftProduct: state.selectedProductGift?.id ?? '',
        isMarketer: state.isMarketer,
        isRequirement: state.isRequirement,
        tag: tagEnumChanger(state.productTag),
        tagPosition: tagPositionEnumChanger(state.productPosition),
        sellType: sellTypeEnumChanger(state.productSellType),
        shipCost: 2000,
        shipCostPayType: state.productSendPrice.name,
      );
      final createRes = await productRepository.create(dto);
      if (createRes is Success<ProductDto>) {
        emit(state.copyWith(status: const UiSuccess()));
      } else {
        emit(state.copyWith(status: UiError(createRes.error.message)));
      }
    } catch (e) {
      emit(state.copyWith(status: UiError(e.toString())));
    } finally {
      emit(state.copyWith(status: const UiIdle()));
    }
  }
}
