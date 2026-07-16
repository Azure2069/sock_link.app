import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';

String hashPin(String pin) => sha256.convert(utf8.encode('market-mate::$pin')).toString();
String money(num value) => NumberFormat.currency(symbol: 'GH₵ ', decimalDigits: 2).format(value);
String shortDate(DateTime value) => DateFormat('dd MMM yyyy, h:mm a').format(value);
