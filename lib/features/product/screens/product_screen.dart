import 'dart:async';

import 'package:asood/core/constants/constants.dart';
import 'package:asood/core/router/app_routers.dart';
import 'package:asood/core/widgets/custom_bottom_navbar.dart';
import 'package:asood/features/market/data/model/theme_model_model.dart';
import 'package:asood/features/market/domain/repository/product_repository.dart';
import 'package:asood/features/product/blocs/product_detail_cubit.dart';
import 'package:asood/features/product/widgets/product_app_bar.dart';
import 'package:asood/features/vendor/presentation/bloc/vendor/vendor_bloc.dart';
import 'package:asood/locator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

class ProductScreen extends StatefulWidget {
  final ThemeProductModel productDetails;
  const ProductScreen({super.key, required this.productDetails});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  String userMessage = '';

  String replyMessage = '';

  int replyId = -1;

  late final ProductDetailCubit _cubit;
  StreamSubscription<ProductDetailState>? _cubitSub;

  Map<String, dynamic> get _detail => _cubit.state.detail;
  String get name => _detail['name']?.toString() ?? '';
  String get description => _detail['description']?.toString() ?? '';
  String get technicalDetail => _detail['technical_detail']?.toString() ?? '';
  String get mainPrice => _detail['main_price']?.toString() ?? '';
  String get primaryImage {
    final images = _detail['images'];
    if (images is! List || images.isEmpty || images.first is! Map) {
      return '';
    }
    return (images.first as Map)['image']?.toString() ?? '';
  }

  String get tag {
    switch (_detail['tag']?.toString()) {
      case 'new':
        return 'جدید';
      case 'special_offer':
        return 'ویژه';
      case 'coming_soon':
        return 'به زودی';
      default:
        return '';
    }
  }

  Map<String, dynamic>? get giftWidget =>
      _detail['gift_product'] is Map
          ? Map<String, dynamic>.from(_detail['gift_product'])
          : null;
  Map<String, dynamic>? get reqProductWidget =>
      _detail['required_product'] is Map
          ? Map<String, dynamic>.from(_detail['required_product'])
          : null;

  String get giftProduct => giftWidget?['name']?.toString() ?? '';
  String get requiredProduct => reqProductWidget?['name']?.toString() ?? '';
  String get giftImage => _firstImage(giftWidget);
  String get requiredImage => _firstImage(reqProductWidget);

  List<Map<String, dynamic>> get comments => _cubit.state.comments;

  static String _firstImage(Map<String, dynamic>? product) {
    final images = product?['images'];
    if (images is! List || images.isEmpty) {
      return '';
    }
    final first = images.first;
    return first is Map ? (first['image']?.toString() ?? '') : '';
  }

  TextEditingController messageController = TextEditingController();

  TextEditingController replyMessageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = ProductDetailCubit(repo: locator<ProductRepository>())
      ..load(widget.productDetails.id.toString());
    // Rebuild on cubit changes and reset the comment forms after a
    // successful submit (the build tree predates bloc wiring).
    _cubitSub = _cubit.stream.listen((pdState) {
      if (!mounted) {
        return;
      }
      if (pdState.commentSent) {
        userMessage = '';
        replyMessage = '';
        replyId = -1;
        messageController.clear();
        replyMessageController.clear();
      }
      if (pdState.status == ProductDetailStatus.ready &&
          pdState.error != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(pdState.error!)));
        });
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _cubitSub?.cancel();
    _cubit.close();
    messageController.dispose();
    replyMessageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VendorBloc, VendorState>(
      builder: (context, state) {
        // if (state.secondColor == state.topColor) {
        //   newSecondColor = state.topColor.withValues(alpha: 0.8);
        // } else {
        //   newSecondColor = state.secondColor;
        // }
        return Container(
          color: state.topColor,
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: state.topColor,
              systemStatusBarContrastEnforced: true,
              systemNavigationBarColor: state.topColor,
              systemNavigationBarDividerColor: state.topColor,
              systemNavigationBarIconBrightness: Brightness.light,
              statusBarIconBrightness: Brightness.light,
            ),
            child: SafeArea(
              child: Scaffold(
                body:
                    _cubit.state.status == ProductDetailStatus.loading
                        ? Column(
                          children: [
                            ProductAppBar(
                              title: widget.productDetails.name,
                              appBarColor: state.topColor,
                            ),
                            const Expanded(
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ],
                        )
                        : _cubit.state.status == ProductDetailStatus.failure
                        ? Column(
                          children: [
                            ProductAppBar(
                              title: widget.productDetails.name,
                              appBarColor: state.topColor,
                            ),
                            Expanded(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        _cubit.state.error ??
                                            'دریافت محصول ناموفق بود',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(color: state.topColor),
                                      ),
                                      const SizedBox(height: 12),
                                      OutlinedButton(
                                        onPressed:
                                            () => _cubit.load(
                                              widget.productDetails.id,
                                            ),
                                        child: const Text('تلاش دوباره'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                        : Stack(
                          children: [
                            SingleChildScrollView(
                              child: Column(
                                children: [
                                  //for app bar
                                  SizedBox(height: Dimensions.height * 0.08),

                                  //image
                                  SizedBox(
                                    height: Dimensions.height * 0.27,
                                    child: Stack(
                                      children: [
                                        AspectRatio(
                                          aspectRatio: 16 / 9,
                                          child: Container(
                                            padding: EdgeInsets.only(
                                              bottom: Dimensions.height * 0.015,
                                            ),
                                            decoration: BoxDecoration(
                                              color: state.topColor,
                                              borderRadius: BorderRadius.only(
                                                bottomRight: Radius.circular(
                                                  32,
                                                ),
                                                bottomLeft: Radius.circular(32),
                                              ),
                                            ),
                                            child: Stack(
                                              children: [
                                                //image
                                                Positioned(
                                                  bottom: 0,
                                                  top: 0,
                                                  width: Dimensions.width,
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        const BorderRadius.only(
                                                          bottomRight:
                                                              Radius.circular(
                                                                32,
                                                              ),
                                                          bottomLeft:
                                                              Radius.circular(
                                                                32,
                                                              ),
                                                        ),
                                                    child:
                                                        primaryImage.isNotEmpty
                                                            ? CachedNetworkImage(
                                                              imageUrl:
                                                                  primaryImage,
                                                              fit: BoxFit.cover,
                                                            )
                                                            : ColoredBox(
                                                              color: state
                                                                  .secondColor
                                                                  .withValues(
                                                                    alpha: 0.2,
                                                                  ),
                                                              child: Center(
                                                                child: Icon(
                                                                  Icons
                                                                      .image_not_supported_outlined,
                                                                  color:
                                                                      state
                                                                          .topColor,
                                                                  size: 48,
                                                                ),
                                                              ),
                                                            ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  //base
                                  Container(
                                    width: Dimensions.width,
                                    margin: EdgeInsets.symmetric(
                                      vertical: Dimensions.height * 0.01,
                                      horizontal: Dimensions.width * 0.05,
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: state.secondColor,
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    child: Column(
                                      children: [
                                        //title
                                        Container(
                                          width: Dimensions.width,
                                          padding: EdgeInsets.symmetric(
                                            vertical: Dimensions.height * 0.01,
                                          ),
                                          decoration: BoxDecoration(
                                            color: state.topColor,
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topLeft: Radius.circular(26),
                                                  topRight: Radius.circular(26),
                                                ),
                                            border: Border(
                                              bottom: BorderSide(
                                                color: state.secondColor,
                                              ),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              name,
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: Colora.scaffold,
                                                fontFamily: state.fontFamily,
                                              ),
                                            ),
                                          ),
                                        ),

                                        //price
                                        Container(
                                          width: Dimensions.width,
                                          padding: EdgeInsets.symmetric(
                                            vertical: Dimensions.height * 0.01,
                                          ),
                                          decoration: BoxDecoration(
                                            color: state.topColor,
                                            border: Border(
                                              bottom: BorderSide(
                                                color: state.secondColor,
                                                width: 6,
                                              ),
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              mainPrice,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: Colora.scaffold,
                                                fontFamily: state.fontFamily,
                                              ),
                                            ),
                                          ),
                                        ),

                                        Container(
                                          width: Dimensions.width,
                                          padding: EdgeInsets.symmetric(
                                            vertical: Dimensions.height * 0.01,
                                            horizontal: Dimensions.width * 0.05,
                                          ),
                                          decoration: BoxDecoration(
                                            color: state.topColor,
                                          ),
                                          child: Text(
                                            // 'جدید - سیم پیچی',
                                            tag,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colora.scaffold,
                                              fontFamily: state.fontFamily,
                                            ),
                                          ),
                                        ),

                                        Container(
                                          width: Dimensions.width,
                                          padding: EdgeInsets.symmetric(
                                            vertical: Dimensions.height * 0.01,
                                            horizontal: Dimensions.width * 0.05,
                                          ),
                                          decoration: BoxDecoration(
                                            color: state.topColor,
                                            border: Border(
                                              bottom: BorderSide(
                                                color: state.secondColor,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            // 'سه نظام',
                                            description,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colora.scaffold,
                                              fontFamily: state.fontFamily,
                                            ),
                                          ),
                                        ),

                                        //gift - title
                                        Container(
                                          width: Dimensions.width,
                                          padding: EdgeInsets.symmetric(
                                            vertical: Dimensions.height * 0.01,
                                            horizontal: Dimensions.width * 0.05,
                                          ),
                                          decoration: BoxDecoration(
                                            color: state.topColor,
                                          ),
                                          child: Text(
                                            'هدایا :',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colora.scaffold,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: state.fontFamily,
                                            ),
                                          ),
                                        ),

                                        //gift
                                        Container(
                                          width: Dimensions.width,
                                          padding: EdgeInsets.symmetric(
                                            vertical: Dimensions.height * 0.01,
                                            horizontal: Dimensions.width * 0.05,
                                          ),
                                          decoration: BoxDecoration(
                                            color: state.topColor,
                                            border: Border(
                                              bottom: BorderSide(
                                                color: state.secondColor,
                                              ),
                                            ),
                                          ),
                                          child:
                                              giftWidget == null
                                                  ? Text(
                                                    // 'دریل برقی شارژی',
                                                    // giftProduct == 'null'
                                                    // ?
                                                    'ندارد',
                                                    // : giftProduct,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colora.scaffold,
                                                    ),
                                                  )
                                                  : SizedBox(
                                                    height:
                                                        Dimensions.height * 0.1,
                                                    child: ListView.builder(
                                                      itemCount: 1,
                                                      shrinkWrap: true,
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      itemBuilder:
                                                          (
                                                            context,
                                                            index,
                                                          ) => InkWell(
                                                            onTap: () {
                                                              ThemeProductModel
                                                              productGift = ThemeProductModel(
                                                                id:
                                                                    giftWidget!['id'],
                                                                name:
                                                                    giftWidget!['name'],
                                                                description:
                                                                    giftWidget!['description'],
                                                                mainPrice:
                                                                    giftWidget!['main_price'],
                                                                stock:
                                                                    giftWidget!['stock']
                                                                        .toString(),
                                                                images: [
                                                                  ProductImage(
                                                                    id: '',
                                                                    image:
                                                                        giftImage,
                                                                  ),
                                                                ],
                                                              );
                                                              context.push(
                                                                AppRoutes
                                                                    .product,
                                                                extra: [
                                                                  productGift,
                                                                ],
                                                              );
                                                            },
                                                            child: Container(
                                                              margin: EdgeInsets.symmetric(
                                                                horizontal:
                                                                    Dimensions
                                                                        .width *
                                                                    0.01,
                                                                vertical:
                                                                    Dimensions
                                                                        .height *
                                                                    0.005,
                                                              ),
                                                              child: AspectRatio(
                                                                aspectRatio: 1,
                                                                child: Container(
                                                                  padding:
                                                                      const EdgeInsets.all(
                                                                        5,
                                                                      ),
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        Colora
                                                                            .scaffold,
                                                                    shape:
                                                                        BoxShape
                                                                            .rectangle,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          10,
                                                                        ),
                                                                  ),
                                                                  child: Column(
                                                                    children: [
                                                                      //image
                                                                      AspectRatio(
                                                                        aspectRatio:
                                                                            4 /
                                                                            3,
                                                                        child: Container(
                                                                          decoration: BoxDecoration(
                                                                            borderRadius: BorderRadius.circular(
                                                                              10,
                                                                            ),
                                                                            border: Border.all(
                                                                              color:
                                                                                  state.topColor,
                                                                            ),
                                                                          ),
                                                                          child:
                                                                              giftImage ==
                                                                                      ''
                                                                                  ? Container()
                                                                                  : ClipRRect(
                                                                                    borderRadius: BorderRadius.circular(
                                                                                      10,
                                                                                    ),
                                                                                    child: CachedNetworkImage(
                                                                                      imageUrl:
                                                                                          giftImage,
                                                                                      fit:
                                                                                          BoxFit.fill,
                                                                                    ),
                                                                                  ),
                                                                        ),
                                                                      ),

                                                                      //text
                                                                      Padding(
                                                                        padding: EdgeInsets.only(
                                                                          top:
                                                                              2,
                                                                        ),
                                                                        child: FittedBox(
                                                                          fit:
                                                                              BoxFit.scaleDown,
                                                                          child: Text(
                                                                            giftProduct,
                                                                            // '${giftProduct['name']}',
                                                                            // 'ویزیت دکتر',
                                                                            style: TextStyle(
                                                                              fontSize:
                                                                                  8,
                                                                              color:
                                                                                  state.topColor,
                                                                              fontFamily:
                                                                                  state.fontFamily,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                    ),
                                                  ),
                                        ),

                                        //spec - title
                                        Container(
                                          width: Dimensions.width,
                                          padding: EdgeInsets.symmetric(
                                            vertical: Dimensions.height * 0.01,
                                            horizontal: Dimensions.width * 0.05,
                                          ),
                                          decoration: BoxDecoration(
                                            color: state.topColor,
                                          ),
                                          child: Text(
                                            'مشخصات فنی :',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colora.scaffold,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: state.fontFamily,
                                            ),
                                          ),
                                        ),

                                        //spec
                                        Container(
                                          width: Dimensions.width,
                                          padding: EdgeInsets.symmetric(
                                            vertical: Dimensions.height * 0.01,
                                            horizontal: Dimensions.width * 0.05,
                                          ),
                                          decoration: BoxDecoration(
                                            color: state.topColor,
                                            borderRadius: BorderRadius.only(
                                              bottomLeft: Radius.circular(26),
                                              bottomRight: Radius.circular(26),
                                            ),
                                            border: Border(
                                              bottom: BorderSide(
                                                color: state.secondColor,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            // '100w',
                                            technicalDetail,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colora.scaffold,
                                              fontFamily: state.fontFamily,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  //gift
                                  Container(
                                    width: Dimensions.width,
                                    margin: EdgeInsets.symmetric(
                                      vertical: Dimensions.height * 0.01,
                                      horizontal: Dimensions.width * 0.05,
                                    ),
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: state.topColor,
                                      borderRadius: BorderRadius.circular(26),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'کالاهای همراه :',
                                          style: TextStyle(
                                            color: Colora.scaffold,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),

                                        Container(
                                          width: Dimensions.width,
                                          padding: EdgeInsets.symmetric(
                                            vertical: Dimensions.height * 0.01,
                                            horizontal: Dimensions.width * 0.05,
                                          ),
                                          decoration: BoxDecoration(
                                            color: state.topColor,
                                            border: Border(
                                              bottom: BorderSide(
                                                color: state.secondColor,
                                              ),
                                            ),
                                          ),
                                          child:
                                              reqProductWidget == null
                                                  ? Text(
                                                    // 'دریل برقی شارژی',
                                                    // giftProduct == 'null'
                                                    // ?
                                                    'ندارد',
                                                    // : giftProduct,
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: Colora.scaffold,
                                                    ),
                                                  )
                                                  : SizedBox(
                                                    height:
                                                        Dimensions.height * 0.1,
                                                    child: ListView.builder(
                                                      itemCount: 1,
                                                      shrinkWrap: true,
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      itemBuilder:
                                                          (
                                                            context,
                                                            index,
                                                          ) => InkWell(
                                                            onTap: () {
                                                              ThemeProductModel
                                                              productRequired = ThemeProductModel(
                                                                id:
                                                                    reqProductWidget!['id'],
                                                                name:
                                                                    reqProductWidget!['name'],
                                                                description:
                                                                    reqProductWidget!['description'],
                                                                mainPrice:
                                                                    reqProductWidget!['main_price'],
                                                                stock:
                                                                    reqProductWidget!['stock']
                                                                        .toString(),
                                                                images: [
                                                                  ProductImage(
                                                                    id: '',
                                                                    image:
                                                                        requiredImage,
                                                                  ),
                                                                ],
                                                              );
                                                              context.push(
                                                                AppRoutes
                                                                    .product,
                                                                extra: [
                                                                  productRequired,
                                                                ],
                                                              );
                                                            },
                                                            child: Container(
                                                              margin: EdgeInsets.symmetric(
                                                                horizontal:
                                                                    Dimensions
                                                                        .width *
                                                                    0.01,
                                                                vertical:
                                                                    Dimensions
                                                                        .height *
                                                                    0.005,
                                                              ),
                                                              child: AspectRatio(
                                                                aspectRatio: 1,
                                                                child: Container(
                                                                  padding:
                                                                      const EdgeInsets.all(
                                                                        5,
                                                                      ),
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        Colora
                                                                            .scaffold,
                                                                    shape:
                                                                        BoxShape
                                                                            .rectangle,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          10,
                                                                        ),
                                                                  ),
                                                                  child: Column(
                                                                    children: [
                                                                      //image
                                                                      AspectRatio(
                                                                        aspectRatio:
                                                                            4 /
                                                                            3,
                                                                        child: Container(
                                                                          decoration: BoxDecoration(
                                                                            borderRadius: BorderRadius.circular(
                                                                              10,
                                                                            ),
                                                                            border: Border.all(
                                                                              color:
                                                                                  state.topColor,
                                                                            ),
                                                                          ),
                                                                          child:
                                                                              requiredImage ==
                                                                                      ''
                                                                                  ? Container()
                                                                                  : ClipRRect(
                                                                                    borderRadius: BorderRadius.circular(
                                                                                      10,
                                                                                    ),
                                                                                    child: CachedNetworkImage(
                                                                                      imageUrl:
                                                                                          requiredImage,
                                                                                      fit:
                                                                                          BoxFit.fill,
                                                                                    ),
                                                                                  ),
                                                                        ),
                                                                      ),

                                                                      //text
                                                                      Padding(
                                                                        padding: EdgeInsets.only(
                                                                          top:
                                                                              2,
                                                                        ),
                                                                        child: FittedBox(
                                                                          fit:
                                                                              BoxFit.scaleDown,
                                                                          child: Text(
                                                                            requiredProduct,
                                                                            // '${giftProduct['name']}',
                                                                            // 'ویزیت دکتر',
                                                                            style: TextStyle(
                                                                              fontSize:
                                                                                  8,
                                                                              color:
                                                                                  state.topColor,
                                                                              fontFamily:
                                                                                  state.fontFamily,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                    ),
                                                  ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  //comment title
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: Dimensions.height * 0.01,
                                    ),
                                    child: Text(
                                      'نظرات کاربران',
                                      style: TextStyle(
                                        color: state.topColor,
                                        fontSize: 17,
                                        fontFamily: state.fontFamily,
                                      ),
                                    ),
                                  ),

                                  Divider(
                                    color: state.secondColor,
                                    indent: Dimensions.width * 0.1,
                                    endIndent: Dimensions.width * 0.1,
                                  ),

                                  //input
                                  replyId != -1
                                      ? Container()
                                      : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Container(
                                            width: Dimensions.width,
                                            margin: EdgeInsets.symmetric(
                                              vertical:
                                                  Dimensions.height * 0.01,
                                              horizontal:
                                                  Dimensions.width * 0.05,
                                            ),
                                            padding: const EdgeInsets.all(15),
                                            decoration: BoxDecoration(
                                              color: state.secondColor,
                                              borderRadius:
                                                  BorderRadius.circular(26),
                                            ),
                                            child: Column(
                                              children: [
                                                TextField(
                                                  controller: messageController,
                                                  maxLines: 3,
                                                  style: TextStyle(
                                                    color: Colora.scaffold_,
                                                    fontSize: 14,
                                                  ),
                                                  decoration: InputDecoration(
                                                    border:
                                                        UnderlineInputBorder(
                                                          borderSide:
                                                              BorderSide.none,
                                                        ),
                                                    hintText: 'پیام شما ...',
                                                    hintStyle: TextStyle(
                                                      color: Colora.scaffold_,
                                                      fontSize: 14,
                                                      fontFamily:
                                                          state.fontFamily,
                                                    ),
                                                  ),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      userMessage = value;
                                                    });
                                                  },
                                                ),

                                                //send button
                                                Align(
                                                  alignment:
                                                      Alignment.centerLeft,
                                                  child: InkWell(
                                                    onTap:
                                                        _cubit.state.sendingComment ||
                                                                userMessage
                                                                    .trim()
                                                                    .isEmpty
                                                            ? null
                                                            : () => _cubit
                                                                .sendComment(
                                                                  userMessage,
                                                                ),
                                                    child: Container(
                                                      width:
                                                          Dimensions.width *
                                                          0.2,
                                                      height:
                                                          Dimensions.height *
                                                          0.04,
                                                      margin:
                                                          const EdgeInsets.only(
                                                            top: 15,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: state.topColor,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              36,
                                                            ),
                                                      ),
                                                      child: Center(
                                                        child: Text(
                                                          'ارسال',
                                                          style: TextStyle(
                                                            color:
                                                                Colora.scaffold,
                                                            fontFamily:
                                                                state
                                                                    .fontFamily,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                  // comments part:
                                  comments.isEmpty
                                      ? SizedBox(
                                        height: Dimensions.height * 0.1,
                                        width: Dimensions.width,
                                        child: Center(
                                          child: Container(
                                            width: Dimensions.width * 0.8,
                                            height: Dimensions.height * 0.08,
                                            decoration: BoxDecoration(
                                              color: state.topColor,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'هنوز نظری برای این محصول ثبت نشده است',
                                                style: TextStyle(
                                                  color: Colora.scaffold,
                                                  fontFamily: state.fontFamily,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                      : Container(),
                                  SizedBox(
                                    height:
                                        comments.isEmpty
                                            ? 0
                                            : Dimensions.height * 0.4,
                                    width: Dimensions.width,
                                    child: ListView.builder(
                                      itemCount: comments.length,
                                      itemBuilder: (context, index) {
                                        return Column(
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Column(
                                                  children: [
                                                    SizedBox(
                                                      width:
                                                          Dimensions.width *
                                                          0.15,
                                                      child: AspectRatio(
                                                        aspectRatio: 1,
                                                        child: Container(
                                                          decoration: BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color:
                                                                Colora.scaffold,
                                                            border: Border.all(
                                                              color:
                                                                  state
                                                                      .secondColor,
                                                              width: 2,
                                                            ),
                                                          ),
                                                          child: SvgPicture.asset(
                                                            'assets/images/logo_svg.svg',
                                                            colorFilter:
                                                                ColorFilter.mode(
                                                                  state
                                                                      .secondColor,
                                                                  BlendMode
                                                                      .srcIn,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                        top: 4.0,
                                                      ),
                                                      child: Text(
                                                        'کاربر ${comments[index]['user']}',
                                                        style: TextStyle(
                                                          color: state.topColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Container(
                                                  width:
                                                      Dimensions.width * 0.74,
                                                  margin: EdgeInsets.only(
                                                    right:
                                                        Dimensions.width * 0.01,
                                                    top: 10,
                                                  ),
                                                  padding: const EdgeInsets.all(
                                                    10,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: state.secondColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Text(
                                                        comments[index]['comment'],
                                                        textAlign:
                                                            TextAlign.justify,
                                                        style: TextStyle(
                                                          color:
                                                              Colora.scaffold,
                                                          fontSize: 12,
                                                        ),
                                                      ),

                                                      // send reply part:
                                                      SizedBox(
                                                        height:
                                                            replyId ==
                                                                    comments[index]['id']
                                                                ? Dimensions
                                                                        .height *
                                                                    0.31
                                                                : 0,
                                                        child: AnimatedOpacity(
                                                          duration: Duration(
                                                            milliseconds: 250,
                                                          ),
                                                          opacity:
                                                              replyId ==
                                                                      comments[index]['id']
                                                                  ? 1
                                                                  : 0,
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceEvenly,
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              // reply message part:
                                                              Container(
                                                                width:
                                                                    Dimensions
                                                                        .width *
                                                                    0.6,
                                                                height:
                                                                    Dimensions
                                                                        .height *
                                                                    0.12,
                                                                margin: EdgeInsets.only(
                                                                  left:
                                                                      Dimensions
                                                                          .width *
                                                                      0.05,
                                                                ),
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          15,
                                                                    ),
                                                                decoration: BoxDecoration(
                                                                  color:
                                                                      state
                                                                          .topColor,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        26,
                                                                      ),
                                                                ),
                                                                child: TextField(
                                                                  controller:
                                                                      replyMessageController,
                                                                  maxLines: 1,
                                                                  style: TextStyle(
                                                                    color:
                                                                        Colora
                                                                            .scaffold_,
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                  decoration: InputDecoration(
                                                                    border: UnderlineInputBorder(
                                                                      borderSide:
                                                                          BorderSide
                                                                              .none,
                                                                    ),
                                                                    hintText:
                                                                        'پاسخ شما ...',
                                                                    hintStyle: TextStyle(
                                                                      color:
                                                                          Colora
                                                                              .scaffold_,
                                                                      fontSize:
                                                                          14,
                                                                      fontFamily:
                                                                          state
                                                                              .fontFamily,
                                                                    ),
                                                                  ),
                                                                  onChanged: (
                                                                    value,
                                                                  ) {
                                                                    setState(() {
                                                                      replyMessage =
                                                                          value;
                                                                    });
                                                                  },
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),

                                                      //send button
                                                      Align(
                                                        alignment:
                                                            Alignment
                                                                .centerLeft,
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            AnimatedOpacity(
                                                              opacity:
                                                                  replyId ==
                                                                          comments[index]['id']
                                                                      ? 1
                                                                      : 0,
                                                              duration: Duration(
                                                                milliseconds:
                                                                    250,
                                                              ),
                                                              child: InkWell(
                                                                onTap: () {
                                                                  setState(() {
                                                                    replyId =
                                                                        -1;
                                                                    replyMessageController
                                                                        .clear();
                                                                  });
                                                                },
                                                                child: Container(
                                                                  width:
                                                                      Dimensions
                                                                          .width *
                                                                      0.2,
                                                                  height:
                                                                      Dimensions
                                                                          .height *
                                                                      0.04,
                                                                  decoration: BoxDecoration(
                                                                    color:
                                                                        state
                                                                            .topColor,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                          36,
                                                                        ),
                                                                  ),
                                                                  child: const Center(
                                                                    child: Text(
                                                                      'بازگشت',
                                                                      style: TextStyle(
                                                                        color:
                                                                            Colora.scaffold,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(width: 10),
                                                            InkWell(
                                                              onTap: () {
                                                                if (replyId ==
                                                                    -1) {
                                                                  setState(() {
                                                                    replyId =
                                                                        comments[index]['id'];
                                                                  });
                                                                } else if (!_cubit
                                                                        .state
                                                                        .sendingComment &&
                                                                    replyMessage
                                                                        .trim()
                                                                        .isNotEmpty) {
                                                                  _cubit.sendComment(
                                                                    replyMessage,
                                                                    parentId:
                                                                        comments[index]['id'],
                                                                  );
                                                                }
                                                              },
                                                              child: Container(
                                                                width:
                                                                    Dimensions
                                                                        .width *
                                                                    0.2,
                                                                height:
                                                                    Dimensions
                                                                        .height *
                                                                    0.04,
                                                                decoration: BoxDecoration(
                                                                  color:
                                                                      state
                                                                          .topColor,
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        36,
                                                                      ),
                                                                ),
                                                                child: const Center(
                                                                  child: Text(
                                                                    'پاسخ',
                                                                    style: TextStyle(
                                                                      color:
                                                                          Colora
                                                                              .scaffold,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),

                                            // replies part:
                                            comments[index]['children'].isEmpty
                                                ? Container()
                                                : Column(
                                                  children: [
                                                    ...comments[index]['children'].map((
                                                      element,
                                                    ) {
                                                      return Container(
                                                        margin: EdgeInsets.only(
                                                          right:
                                                              Dimensions.width *
                                                              0.1,
                                                          top:
                                                              Dimensions
                                                                  .height *
                                                              0.01,
                                                        ),
                                                        child: Row(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Column(
                                                              children: [
                                                                SizedBox(
                                                                  width:
                                                                      Dimensions
                                                                          .width *
                                                                      0.15,
                                                                  child: AspectRatio(
                                                                    aspectRatio:
                                                                        1,
                                                                    child: Container(
                                                                      decoration: BoxDecoration(
                                                                        shape:
                                                                            BoxShape.circle,
                                                                        color:
                                                                            Colora.scaffold,
                                                                        border: Border.all(
                                                                          color:
                                                                              state.secondColor,
                                                                          width:
                                                                              2,
                                                                        ),
                                                                      ),
                                                                      child: SvgPicture.asset(
                                                                        'assets/images/logo_svg.svg',
                                                                        colorFilter: ColorFilter.mode(
                                                                          state
                                                                              .secondColor,
                                                                          BlendMode
                                                                              .srcIn,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                Padding(
                                                                  padding:
                                                                      EdgeInsets.only(
                                                                        top:
                                                                            4.0,
                                                                      ),
                                                                  child: Text(
                                                                    'کاربر ${comments[index]['user']}',
                                                                    style: TextStyle(
                                                                      color:
                                                                          state
                                                                              .topColor,
                                                                      fontSize:
                                                                          12,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            Container(
                                                              width:
                                                                  Dimensions
                                                                      .width *
                                                                  0.64,
                                                              margin: EdgeInsets.only(
                                                                right:
                                                                    Dimensions
                                                                        .width *
                                                                    0.01,
                                                              ),
                                                              padding:
                                                                  const EdgeInsets.all(
                                                                    10,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    state
                                                                        .topColor,
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      20,
                                                                    ),
                                                              ),
                                                              child: Column(
                                                                children: [
                                                                  Text(
                                                                    element['comment']
                                                                        .toString(),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .justify,
                                                                    style: TextStyle(
                                                                      color:
                                                                          Colora
                                                                              .scaffold,
                                                                      fontSize:
                                                                          12,
                                                                    ),
                                                                  ),

                                                                  //send button
                                                                  Align(
                                                                    alignment:
                                                                        Alignment
                                                                            .centerLeft,
                                                                    child: Container(
                                                                      width:
                                                                          Dimensions
                                                                              .width *
                                                                          0.2,
                                                                      height:
                                                                          Dimensions
                                                                              .height *
                                                                          0.04,
                                                                      decoration: BoxDecoration(
                                                                        color:
                                                                            state.secondColor,
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              36,
                                                                            ),
                                                                      ),
                                                                      child: const Center(
                                                                        child: Text(
                                                                          'پاسخ',
                                                                          style: TextStyle(
                                                                            color:
                                                                                Colora.scaffold,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    }),
                                                  ],
                                                ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),

                                  SizedBox(height: Dimensions.height * 0.1),
                                ],
                              ),
                            ),

                            ProductAppBar(
                              title: name,
                              appBarColor: state.topColor,
                            ),

                            //bottom settings
                            Positioned(
                              bottom: 0,
                              child: CustomBottomNavigationBar(
                                marketId:
                                    'ProductID=${widget.productDetails.id}',
                                initTopColor: state.topColor,
                                initBackColor: state.backColor,
                                initSecondColor: state.secondColor,
                                initFont: state.fontFamily,
                                initFontColor: state.fontColor,
                                initFontSecondColor: state.secondFontColor,
                                userMode: true,
                              ),
                            ),
                          ],
                        ),
              ),
            ),
          ),
        );
      },
    );
  }
}
