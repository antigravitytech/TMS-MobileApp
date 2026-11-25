import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_fonts.dart';
import '../../core/extensions/context_extensions.dart';

@immutable
class TMSTexts {
  const TMSTexts._();

  static Widget displayLarge32(
    BuildContext context, {
    required String text,
    bool center = false,
    bool isTextWidget = false,
    TextOverflow? overflow,
    int? maxLines,
    double? textScaleFactor,
    FontWeight? fontWeight,
    String? fontFamily,
    Color? color,
    double? fontSize,
    List<Shadow>? shadows,
  }) {
    return isTextWidget
        ? Text(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: context.textTheme.displayLarge?.copyWith(
              fontWeight: fontWeight,
              color: color,
              fontFamily: fontFamily ?? AppFonts.none,
              fontSize: fontSize,
              shadows: shadows,
            ),
            textScaler: TextScaler.linear(textScaleFactor ?? 1.0),
          )
        : AutoSizeText(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            overflow: overflow,
            maxLines: maxLines,
            style: context.textTheme.displayLarge?.copyWith(
              fontWeight: fontWeight,
              color: color,
              fontFamily: fontFamily ?? AppFonts.none,
              fontSize: fontSize,
              fontVariations: [
                FontVariation.weight(fontWeight?.value.toDouble() ?? 700),
              ],
              shadows: shadows,
            ),
            textScaleFactor: textScaleFactor,
          );
  }

  static Widget displayMedium28(
    BuildContext context, {
    required String text,
    bool center = false,
    bool isTextWidget = false,
    TextOverflow? overflow,
    int? maxLines,
    double? textScaleFactor,
    FontWeight? fontWeight,
    String? fontFamily,
    Color? color,
    double? fontSize,
    List<Shadow>? shadows,
  }) {
    return isTextWidget
        ? Text(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: context.textTheme.displayMedium?.copyWith(
              fontWeight: fontWeight,
              color: color,
              fontFamily: fontFamily ?? AppFonts.none,
              fontSize: fontSize,
              shadows: shadows,
            ),
            textScaler: TextScaler.linear(textScaleFactor ?? 1.0),
          )
        : AutoSizeText(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            overflow: overflow,
            maxLines: maxLines,
            style: context.textTheme.displayMedium?.copyWith(
              fontWeight: fontWeight,
              color: color,
              fontFamily: fontFamily ?? AppFonts.none,
              fontSize: fontSize,
              fontVariations: [
                FontVariation.weight(fontWeight?.value.toDouble() ?? 700),
              ],
              shadows: shadows,
            ),
            textScaleFactor: textScaleFactor,
          );
  }

  static Widget displaySmall24(
    BuildContext context, {
    required String text,
    bool center = false,
    bool isTextWidget = false,
    TextOverflow? overflow,
    int? maxLines,
    double? textScaleFactor,
    FontWeight? fontWeight,
    String? fontFamily,
    Color? color,
    double? fontSize,
    double? letterSpacing,
  }) {
    return isTextWidget
        ? Text(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: context.textTheme.displaySmall?.copyWith(
              fontWeight: fontWeight,
              color: color,
              fontFamily: fontFamily ?? AppFonts.none,
              fontSize: fontSize,
              letterSpacing: letterSpacing,
            ),
            textScaler: TextScaler.linear(textScaleFactor ?? 1.0),
          )
        : AutoSizeText(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            overflow: overflow,
            maxLines: maxLines,
            style: context.textTheme.displaySmall?.copyWith(
              fontWeight: fontWeight,
              color: color,
              fontFamily: fontFamily ?? AppFonts.none,
              fontSize: fontSize,
              fontVariations: [
                FontVariation.weight(fontWeight?.value.toDouble() ?? 700),
              ],
              letterSpacing: letterSpacing,
            ),
            textScaleFactor: textScaleFactor,
          );
  }

  static Widget headlineMedium20(
    BuildContext context, {
    required String text,
    bool center = false,
    bool isTextWidget = false,
    TextOverflow? overflow,
    int? maxLines,
    double? textScaleFactor,
    FontWeight? fontWeight,
    String? fontFamily,
    Color? color,
    double? fontSize,
    double? letterSpacing,
  }) {
    return isTextWidget
        ? Text(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: fontWeight,
              color: color,
              fontFamily: fontFamily ?? AppFonts.none,
              fontSize: fontSize,
              letterSpacing: letterSpacing,
            ),
            textScaler: TextScaler.linear(textScaleFactor ?? 1.0),
          )
        : AutoSizeText(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            overflow: overflow,
            maxLines: maxLines,
            style: context.textTheme.headlineMedium?.copyWith(
              fontWeight: fontWeight,
              color: color,
              fontFamily: fontFamily ?? AppFonts.none,
              fontSize: fontSize,
              letterSpacing: letterSpacing,
              fontVariations: [
                FontVariation.weight(fontWeight?.value.toDouble() ?? 700),
              ],
            ),
            textScaleFactor: textScaleFactor,
          );
  }

  static Widget titleLarge18(
    BuildContext context, {
    required String text,
    bool isTextWidget = false,
    bool center = false,
    TextOverflow? overflow,
    int? maxLines,
    double? textScaleFactor,
    FontWeight? fontWeight,
    String? fontFamily,
    Color? color,
    double? fontSize,
    TextAlign? textAlign,
  }) {
    return isTextWidget
        ? Text(
            text,
            textAlign: center
                ? TextAlign.center
                : (textAlign ?? TextAlign.start),
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: fontWeight,
              color: color,
              fontFamily: fontFamily ?? AppFonts.none,
              fontSize: fontSize,
            ),
            textScaler: TextScaler.linear(textScaleFactor ?? 1.0),
          )
        : AutoSizeText(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            overflow: overflow,
            maxLines: maxLines,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: fontWeight,
              color: color,
              fontFamily: fontFamily ?? AppFonts.none,
              fontSize: fontSize,
              fontVariations: [
                FontVariation.weight(fontWeight?.value.toDouble() ?? 500),
              ],
            ),
            textScaleFactor: textScaleFactor,
          );
  }

  static Widget bodyLarge16(
    BuildContext context, {
    required String text,
    bool isTextWidget = false,
    bool center = false,
    TextOverflow? overflow,
    int? maxLines,
    double? textScaleFactor,
    FontWeight? fontWeight,
    String? fontFamily,
    Color? color,
    TextDecoration? textDecoration,
    bool isResponsive = true,
    double? fontSize,
    TextStyle? style,
    bool isGreyText = false,
    double? letterSpacing,
  }) {
    return isTextWidget
        ? Text(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            maxLines: maxLines,
            style:
                style ??
                context.textTheme.bodyLarge?.copyWith(
                  fontWeight: fontWeight,
                  // color: isGreyText ? context.greyTextColor : color,
                  fontFamily: fontFamily ?? AppFonts.none,
                  fontSize: fontSize,
                  overflow: overflow,
                  letterSpacing: letterSpacing,
                ),
            textScaler: TextScaler.linear(textScaleFactor ?? 1.0),
          )
        : AutoSizeText(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            overflow: overflow,
            maxLines: maxLines,
            style:
                style ??
                context.textTheme.bodyLarge?.copyWith(
                  fontWeight: fontWeight,
                  // color: isGreyText ? context.greyTextColor : color,
                  fontFamily: fontFamily ?? AppFonts.none,
                  decoration: textDecoration,
                  decorationColor: color,
                  fontVariations: [
                    FontVariation.weight(fontWeight?.value.toDouble() ?? 500),
                  ],
                  fontSize: fontSize,
                  letterSpacing: letterSpacing,
                ),
            textScaleFactor: textScaleFactor,
          );
  }

  static Widget bodyMedium14(
    BuildContext context, {
    required String text,
    bool center = false,
    bool isTextWidget = false,
    TextOverflow? overflow,
    int? maxLines,
    double? textScaleFactor,
    FontWeight? fontWeight,
    String? fontFamily,
    Color? color,
    TextDecoration? textDecoration,
    double? fontSize,
    bool isGreyText = false,
    double? letterSpacing,
    double? height,
  }) {
    return isTextWidget
        ? Text(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            maxLines: maxLines,
            overflow: overflow,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: fontWeight,
              // color: isGreyText ? context.greyTextColor : color,
              fontFamily: fontFamily ?? AppFonts.none,
              fontSize: fontSize,
              letterSpacing: letterSpacing,
              height: height,
            ),
            textScaler: TextScaler.linear(textScaleFactor ?? 1.0),
          )
        : AutoSizeText(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            overflow: overflow,
            maxLines: maxLines,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: fontWeight,
              // color: isGreyText ? context.greyTextColor : color,
              fontFamily: fontFamily ?? AppFonts.none,
              decoration: textDecoration,
              fontSize: fontSize,
              letterSpacing: letterSpacing,
              height: height,
              fontVariations: [
                FontVariation.weight(fontWeight?.value.toDouble() ?? 700),
              ],
            ),
            textScaleFactor: textScaleFactor,
          );
  }

  static Widget bodySmall12(
    BuildContext context, {
    required String text,
    bool isTextWidget = false,
    bool center = false,
    TextOverflow? overflow,
    int? maxLines,
    double? textScaleFactor,
    FontWeight? fontWeight,
    String? fontFamily,
    Color? color,
    double? height = 1.0,
    double? fontSize,
    TextDecoration? textDecoration,
    bool isGreyText = false,
    FontStyle? fontStyle,
    double? letterSpacing,
  }) {
    return isTextWidget
        ? Text(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: context.textTheme.bodySmall?.copyWith(
              fontWeight: fontWeight,
              // color: isGreyText ? context.greyTextColor : color,
              fontFamily: fontFamily ?? AppFonts.none,
              fontSize: fontSize,
              fontStyle: fontStyle,
              letterSpacing: letterSpacing,
              decoration: textDecoration,
              // decorationColor: context.greyTextColor,
              height: height,
              fontVariations: [
                FontVariation.weight(fontWeight?.value.toDouble() ?? 400),
              ],
            ),
            textScaler: TextScaler.linear(textScaleFactor ?? 1.0),
            maxLines: maxLines,
            overflow: overflow,
          )
        : AutoSizeText(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            overflow: overflow,
            maxLines: maxLines,
            style: context.textTheme.bodySmall?.copyWith(
              fontWeight: fontWeight,
              // color: isGreyText ? context.greyTextColor : color,
              fontFamily: fontFamily ?? AppFonts.none,
              decoration: textDecoration,
              // decorationColor: context.greyTextColor,
              height: height,
              fontSize: fontSize,
              fontStyle: fontStyle,
              fontVariations: [
                FontVariation.weight(fontWeight?.value.toDouble() ?? 400),
              ],
            ),
            textScaleFactor: textScaleFactor,
            softWrap: true,
          );
  }

  static Widget richText(
    BuildContext context, {
    required String text,
    Widget? textWidget,
    TextOverflow? overflow,
    int? maxLines,
    FontWeight? fontWeight,
    bool center = false,
    List<InlineSpan> textChildren = const [],
    required TextStyle textStyle,
    Function(PointerEnterEvent)? onEnter,
  }) {
    return AutoSizeText.rich(
      TextSpan(
        text: text,
        style: textStyle,
        children: textChildren,
        onEnter: onEnter,
      ),
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      textAlign: center ? TextAlign.center : TextAlign.start,
    );
  }
}
