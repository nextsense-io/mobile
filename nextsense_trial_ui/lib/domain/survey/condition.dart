import 'dart:core';

enum ConditionField {
  key,
  op,
  value
}

// Defines a parsable condition in text format.
// Format for one condition is key, operator, value.
// TSupported operators are '==', '!=', '>', '>=', '<' and '<='. More can be added later as needed.
// The value can be a string, number or boolean value.
// Example: "kss_1==true" and "kss_2!=not_much" are valid.
class Condition {
  static const String operatorEqual = "==";
  static const String operatorNotEqual = "!=";
  static const String operatorGreater = ">";
  static const String operatorGreaterOrEqual = ">=";
  static const String operatorLesser = "<";
  static const String operatorLesserOrEqual = "<=";
  static const List<String> validOperators = [operatorEqual, operatorNotEqual, operatorGreater,
    operatorGreaterOrEqual, operatorLesser, operatorLesserOrEqual];

  final String key;
  final String operator;
  final dynamic value;

  Condition(this.key, this.operator, this.value);

  static Condition fromMap(Map<String, dynamic> conditionFields) {
    for (ConditionField conditionField in ConditionField.values) {
      if (conditionFields[conditionField.name] == null) {
        throw FormatException("${conditionField.name} is missing in the fields.");
      }
    }
    String operator = conditionFields[ConditionField.op.name];
    if (!validOperators.contains(operator)) {
      throw FormatException("Unknown operator: $operator.");
    }
    dynamic value = conditionFields[ConditionField.value.name];
    if (value !is String && value !is bool && value !is int) {
      throw FormatException(
          "Value type not supported: $value. Needs to be a String, a book or an int.");
    }
    return Condition(conditionFields[ConditionField.key.name], operator, value);
  }

  bool isTrue(dynamic other) {
    switch (operator) {
      case operatorEqual:
        return value == other;
      case operatorNotEqual:
        return value != other;
      case operatorGreater:
        return int.parse(other) > int.parse(value);
      case operatorGreaterOrEqual:
        return int.parse(other) >= int.parse(value);
      case operatorLesser:
        return int.parse(other) < int.parse(value);
      case operatorLesserOrEqual:
        return int.parse(other) <= int.parse(value);
      default:
        throw FormatException("Invalid operator: $operator");
    }
  }

  @override
  String toString() {
    return "$key$operator$value";
  }
}

// Defines a parsable list of conditions in text format. See `Condition` for individual condition
// parse rules.
// Multiple conditions can be supported by separating them with ';'.
// Example: "kss_1==true;kss_2!=not_much" is valid and contains 2 conditions that need to be true.
class Conditions {
  List<Condition> conditions;

  Conditions(this.conditions);

  static Conditions fromArray(List<dynamic> conditionFieldsList) {
    List<Condition> conditions = [];
    for (Map<String, dynamic> conditionFields in conditionFieldsList) {
      conditions.add(Condition.fromMap(conditionFields));
    }
    return Conditions(conditions);
  }

  List<Condition>? getConditions() {
    return conditions;
  }
}