import 'package:flutter/material.dart';

// TextStyles
// 12px - fine print, captions, timestamps
const kTextCaptionL = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w300, fontSize: 14, color: Colors.black87);
const kTextCaptionR = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14, color: Colors.black87);

//14px - labels, secondary info, metadata
const kTextSmallL = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w300, fontSize: 14, color: Colors.black87);
const kTextSmallR = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 14, color: Colors.black87);

//16px - primary reading text
const kTextBodyL = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w300, fontSize: 16, color: Colors.black87);
const kTextBodyR = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 16, color: Colors.black87);

// 20px - introduction paragraphs, emphasized body
const kTextLeadL = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w300, fontSize: 20, color: Colors.black87);
const kTextLeadR = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 20, color: Colors.black87);

//24px - section subheadings, card titles
const kTextSubtitleL = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w300, fontSize: 24, color: Colors.black87);
const kTextSubtitleM = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 24, color: Colors.black87);

// 32px - tertiary headings
const kTextHeading3L = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w300, fontSize: 32, color: Colors.black87);
const kTextHeading3R = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 32, color: Colors.black87);

// 40px - secondary headings, page sections
const kTextHeading2L = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w300, fontSize: 40, color: Colors.black87);
const kTextHeading2R = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 40, color: Colors.black87);

//48px - primary headings, hero text
const kTextHeading1L = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w300, fontSize: 48, color: Colors.black87);
const kTextHeading1R = TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w400, fontSize: 48, color: Colors.black87);

//*************************************************************************************************

//Button dimensions
const double kButtonHeight = 40;

//Logo Scale
const double kLogoScale = 3.15;

// Button TextStyles
const kCallToActionButtonTextStyle = TextStyle(fontFamily: "OpenSans", fontWeight: FontWeight.w400, fontSize: 14, color: Colors.white);

const kPrimaryButtonTextStyle = TextStyle(fontFamily: "OpenSans", fontWeight: FontWeight.w400, fontSize: 14, color: Colors.white);

const kSecondaryButtonTextStyle = TextStyle(fontFamily: "OpenSans", fontWeight: FontWeight.w400, fontSize: 14, color: Colors.black);

const kSelectionButtonTexyStyle = TextStyle(fontFamily: "OpenSans", fontWeight: FontWeight.w400, fontSize: 14, color: Color.fromARGB(255, 0, 0, 0));

const kSidePanelButtonsTextStyle = TextStyle(fontFamily: "OpenSans", fontWeight: FontWeight.w400, fontSize: 18, color: Color.fromARGB(255, 0, 0, 0));

// BoxDecorations

BoxDecoration kAuthBoxDecoration = BoxDecoration(
  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
  color: Colors.white,
  borderRadius: BorderRadius.circular(24),
);

BoxDecoration kboxShadowNormal = BoxDecoration(
  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.20), blurRadius: 4)],
  color: Colors.white,
  borderRadius: BorderRadius.circular(12),
);

BoxDecoration kGrayBoxDecoration = BoxDecoration(
  color: Color(0xFFEBEBEB),
  borderRadius: BorderRadius.circular(6),
);

BoxDecoration kGreenBox = BoxDecoration(
  color: Color(0xFFB9D08F),
  borderRadius: BorderRadius.circular(8),
);

BoxDecoration kGrayBox = BoxDecoration(
  color: Color(0xFFEBEBEB),
  borderRadius: BorderRadius.circular(8),
);

BoxDecoration kRedBox = BoxDecoration(
  color: Color(0xFFF19C79),
  borderRadius: BorderRadius.circular(8),
);

BoxDecoration kYellowBox = BoxDecoration(
  color: Color(0xFFF2C479),
  borderRadius: BorderRadius.circular(8),
);

BoxDecoration kBlackOutline = BoxDecoration(
  color: Colors.white,
  border: Border.all(color: Colors.black38, width: 0.5),
  borderRadius: BorderRadius.circular(8),
);

Color kSageGreen = Color(0xFFA2B185);
