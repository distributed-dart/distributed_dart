// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of distributed_dart;

/**
 * Unicode (UTF-8) characters
 */
class _U {
  static const int $EOF = 0;
  static const int $STX = 2;
  static const int $BS  = 8;
  static const int $TAB = 9;
  static const int $LF = 10;
  static const int $VTAB = 11;
  static const int $FF = 12;
  static const int $CR = 13;
  static const int $SPACE = 32;
  static const int $BANG = 33;
  static const int $DQ = 34;
  static const int $HASH = 35;
  static const int $$ = 36;
  static const int $PERCENT = 37;
  static const int $AMPERSAND = 38;
  static const int $SQ = 39;
  static const int $OPEN_PAREN = 40;
  static const int $CLOSE_PAREN = 41;
  static const int $STAR = 42;
  static const int $PLUS = 43;
  static const int $COMMA = 44;
  static const int $MINUS = 45;
  static const int $PERIOD = 46;
  static const int $SLASH = 47;
  static const int $0 = 48;
  static const int $1 = 49;
  static const int $2 = 50;
  static const int $3 = 51;
  static const int $4 = 52;
  static const int $5 = 53;
  static const int $6 = 54;
  static const int $7 = 55;
  static const int $8 = 56;
  static const int $9 = 57;
  static const int $COLON = 58;
  static const int $SEMICOLON = 59;
  static const int $LT = 60;
  static const int $EQ = 61;
  static const int $GT = 62;
  static const int $QUESTION = 63;
  static const int $AT = 64;
  static const int $A = 65;
  static const int $B = 66;
  static const int $C = 67;
  static const int $D = 68;
  static const int $E = 69;
  static const int $F = 70;
  static const int $G = 71;
  static const int $H = 72;
  static const int $I = 73;
  static const int $J = 74;
  static const int $K = 75;
  static const int $L = 76;
  static const int $M = 77;
  static const int $N = 78;
  static const int $O = 79;
  static const int $P = 80;
  static const int $Q = 81;
  static const int $R = 82;
  static const int $S = 83;
  static const int $T = 84;
  static const int $U = 85;
  static const int $V = 86;
  static const int $W = 87;
  static const int $X = 88;
  static const int $Y = 89;
  static const int $Z = 90;
  static const int $OPEN_SQUARE_BRACKET = 91;
  static const int $BACKSLASH = 92;
  static const int $CLOSE_SQUARE_BRACKET = 93;
  static const int $CARET = 94;
  static const int $_ = 95;
  static const int $BACKPING = 96;
  static const int $a = 97;
  static const int $b = 98;
  static const int $c = 99;
  static const int $d = 100;
  static const int $e = 101;
  static const int $f = 102;
  static const int $g = 103;
  static const int $h = 104;
  static const int $i = 105;
  static const int $j = 106;
  static const int $k = 107;
  static const int $l = 108;
  static const int $m = 109;
  static const int $n = 110;
  static const int $o = 111;
  static const int $p = 112;
  static const int $q = 113;
  static const int $r = 114;
  static const int $s = 115;
  static const int $t = 116;
  static const int $u = 117;
  static const int $v = 118;
  static const int $w = 119;
  static const int $x = 120;
  static const int $y = 121;
  static const int $z = 122;
  static const int $OPEN_CURLY_BRACKET = 123;
  static const int $BAR = 124;
  static const int $CLOSE_CURLY_BRACKET = 125;
  static const int $TILDE = 126;
  static const int $DEL = 127;
  static const int $NBSP = 160;
  static const int $LS = 0x2028;
  static const int $PS = 0x2029;

  static const int $FIRST_SURROGATE = 0xd800;
  static const int $LAST_SURROGATE = 0xdfff;
  static const int $LAST_CODE_POINT = 0x10ffff;
}

/*
 * The following code has been removed as compared to the original code from
 * the Dart project:
 */

//bool isHexDigit(int characterCode) {
//  if (characterCode <= $9) return $0 <= characterCode;
//  characterCode |= $a ^ $A;
//  return ($a <= characterCode && characterCode <= $f);
//}
//
//int hexDigitValue(int hexDigit) {
//  assert(isHexDigit(hexDigit));
//  // hexDigit is one of '0'..'9', 'A'..'F' and 'a'..'f'.
//  if (hexDigit <= $9) return hexDigit - $0;
//  return (hexDigit | ($a ^ $A)) - ($a - 10);
//}
//
//bool isUnicodeScalarValue(int value) {
//  return value < $FIRST_SURROGATE ||
//      (value > $LAST_SURROGATE && value <= $LAST_CODE_POINT);
//}
//
//bool isUtf16LeadSurrogate(int value) {
//  return value >= 0xd800 && value <= 0xdbff;
//}
//
//bool isUtf16TrailSurrogate(int value) {
//  return value >= 0xdc00 && value <= 0xdfff;
//}
