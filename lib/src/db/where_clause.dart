class WhereClause {

  final String column;
  final String? whereOperator;
  final String argument;

  WhereClause(this.column, this.argument, { this.whereOperator });

  String get where => '$column ${whereOperator ?? '='} ?';

  String get arg => argument;
}

class MultiWhereClause {

  final String _where;
  final List<String> _arguments;

  const MultiWhereClause(this._where, this._arguments);

  String get where => _where;

  List<String> get args => _arguments;

  factory MultiWhereClause.fromConditions(List<WhereClause> clauses, List<String> unions) {
    String query = '';
    List<String> arguments = [];

    assert(unions.length == clauses.length - 1);

    for (int i = 0; i < clauses.length; ++i) {
      WhereClause clause = clauses[i];

      query += clause.where;
      arguments.add(clause.arg);

      if (i < unions.length) {
        query += ' ${unions[i]} ';
      }
    }

    return MultiWhereClause(query, arguments);
  }
}