// Copyright 2026 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

/// Client-side validation of Python workflow scripts for `run_workflow`.
library;

/// Thrown when a workflow script fails validation.
class WorkflowException implements Exception {
  /// A description of the rule the script violates.
  final String message;

  WorkflowException(this.message);

  @override
  String toString() => 'WorkflowException: $message';
}

const _returnYieldMessage =
    'return/yield statements are not allowed in workflow scripts; use '
    'workflows.log(...) to emit output';

/// Validates Python workflow [source] against the `run_workflow` rules, so a
/// disallowed script fails before the model is asked to run it.
///
/// Rejects, with a [WorkflowException]:
/// - `import` and `from ... import` statements;
/// - `while` loops (use bounded `for` loops);
/// - attributes starting with `_` and names starting with `__`;
/// - `return` outside a nested `def`, and `yield` anywhere;
/// - unterminated strings, unbalanced brackets, and inconsistent indentation,
///   reported as `workflow syntax error`.
///
/// This is a lexical check, not a full Python parser: a script that passes may
/// still contain syntax errors, which the harness reports when it runs the
/// script. Expressions inside f-strings are not inspected.
void validateWorkflowSource(String source) {
  final lines = _PythonLexer(source).logicalLines();
  _checkIndentation(lines);
  _checkReturnAndYield(lines);
  for (final line in lines) {
    _checkLine(line);
  }
}

enum _Kind { name, op, string, number }

class _Token {
  final _Kind kind;
  final String text;
  const _Token(this.kind, this.text);

  bool isName(String value) => kind == _Kind.name && text == value;
  bool isOp(String value) => kind == _Kind.op && text == value;
}

class _LogicalLine {
  final int indent;
  final int lineNumber;
  final List<_Token> tokens;
  _LogicalLine(this.indent, this.lineNumber, this.tokens);

  bool get startsFunction =>
      tokens.first.isName('def') ||
      (tokens.first.isName('async') &&
          tokens.length > 1 &&
          tokens[1].isName('def'));

  bool get opensBlock => tokens.last.isOp(':');
}

WorkflowException _syntaxError(String detail, int line) =>
    WorkflowException('workflow syntax error: $detail (line $line)');

/// Splits Python source into logical lines of tokens, tracking indentation.
class _PythonLexer {
  final String _src;
  int _pos = 0;
  int _line = 1;

  _PythonLexer(this._src);

  static final _namePattern = RegExp(r'[^\W\d]\w*', unicode: true);
  static final _numberPattern = RegExp(
      r'(\d[\d_]*\.?[\d_]*|\.\d[\d_]*)([eE][+-]?\d+)?[jJ]?|0[xXoObB][\da-fA-F_]+');
  static final _stringPrefix =
      RegExp(r'([rRbBuUfF]{1,2})?("""|' "'''" r'''|"|')''');
  static const _operators = [
    '**=', '//=', '>>=', '<<=', '...', '->', ':=', //
    '**', '//', '<<', '>>', '<=', '>=', '==', '!=',
    '+=', '-=', '*=', '/=', '%=', '&=', '|=', '^=', '@=',
  ];

  List<_LogicalLine> logicalLines() {
    final lines = <_LogicalLine>[];
    final brackets = <String>[];
    var tokens = <_Token>[];
    var indent = 0;
    var lineStart = 1;
    var atLineStart = true;

    void endLine() {
      if (tokens.isNotEmpty) lines.add(_LogicalLine(indent, lineStart, tokens));
      tokens = <_Token>[];
      atLineStart = true;
    }

    while (_pos < _src.length) {
      if (atLineStart) {
        var width = 0;
        while (_pos < _src.length && (_peek == ' ' || _peek == '\t')) {
          width = _peek == '\t' ? (width ~/ 8 + 1) * 8 : width + 1;
          _pos++;
        }
        if (_pos >= _src.length) break;
        if (_peek == '\n' || _peek == '\r' || _peek == '#') {
          _skipToLineEnd();
          continue;
        }
        indent = width;
        lineStart = _line;
        atLineStart = false;
      }

      final c = _peek;
      if (c == '\n' || c == '\r') {
        _consumeNewline();
        if (brackets.isEmpty) endLine();
      } else if (c == ' ' || c == '\t' || c == '\f') {
        _pos++;
      } else if (c == '#') {
        _skipComment();
      } else if (c == r'\') {
        _pos++;
        if (_pos < _src.length && (_peek == '\n' || _peek == '\r')) {
          _consumeNewline();
        } else {
          throw _syntaxError(
              'unexpected character after line continuation', _line);
        }
      } else if (_stringPrefix.matchAsPrefix(_src, _pos) case final m?) {
        _pos = m.end;
        _readString(m.group(2)!);
        tokens.add(const _Token(_Kind.string, ''));
      } else if (_namePattern.matchAsPrefix(_src, _pos) case final m?) {
        _pos = m.end;
        tokens.add(_Token(_Kind.name, m.group(0)!));
      } else if (_numberPattern.matchAsPrefix(_src, _pos) case final m?
          when m.group(0)!.isNotEmpty && m.group(0) != '.') {
        _pos = m.end;
        tokens.add(_Token(_Kind.number, m.group(0)!));
      } else if ('([{'.contains(c)) {
        brackets.add(c);
        tokens.add(_Token(_Kind.op, c));
        _pos++;
      } else if (')]}'.contains(c)) {
        const pairs = {')': '(', ']': '[', '}': '{'};
        if (brackets.isEmpty || brackets.removeLast() != pairs[c]) {
          throw _syntaxError("unmatched '$c'", _line);
        }
        tokens.add(_Token(_Kind.op, c));
        _pos++;
      } else {
        final op = _operators.firstWhere((o) => _src.startsWith(o, _pos),
            orElse: () => c);
        tokens.add(_Token(_Kind.op, op));
        _pos += op.length;
      }
    }
    if (brackets.isNotEmpty) {
      throw _syntaxError("'${brackets.last}' was never closed", _line);
    }
    endLine();
    return lines;
  }

  String get _peek => _src[_pos];

  void _consumeNewline() {
    if (_peek == '\r' && _pos + 1 < _src.length && _src[_pos + 1] == '\n') {
      _pos++;
    }
    _pos++;
    _line++;
  }

  void _skipComment() {
    while (_pos < _src.length && _peek != '\n' && _peek != '\r') {
      _pos++;
    }
  }

  void _skipToLineEnd() {
    _skipComment();
    if (_pos < _src.length) _consumeNewline();
  }

  void _readString(String quote) {
    final start = _line;
    final triple = quote.length == 3;
    while (_pos < _src.length) {
      final c = _peek;
      if (c == r'\') {
        _pos++;
        if (_pos < _src.length) {
          if (_peek == '\n' || _peek == '\r') {
            _consumeNewline();
          } else {
            _pos++;
          }
        }
        continue;
      }
      if (_src.startsWith(quote, _pos)) {
        _pos += quote.length;
        return;
      }
      if (c == '\n' || c == '\r') {
        if (!triple) break;
        _consumeNewline();
        continue;
      }
      _pos++;
    }
    throw _syntaxError(
        triple
            ? 'unterminated triple-quoted string literal'
            : 'unterminated string literal',
        start);
  }
}

void _checkIndentation(List<_LogicalLine> lines) {
  final stack = [0];
  for (var i = 0; i < lines.length; i++) {
    final line = lines[i];
    final opened = i > 0 && lines[i - 1].opensBlock;
    if (opened) {
      if (line.indent <= stack.last) {
        throw _syntaxError('expected an indented block', line.lineNumber);
      }
      stack.add(line.indent);
      continue;
    }
    if (line.indent > stack.last) {
      throw _syntaxError('unexpected indent', line.lineNumber);
    }
    while (line.indent < stack.last) {
      stack.removeLast();
    }
    if (line.indent != stack.last) {
      throw _syntaxError('unindent does not match any outer indentation level',
          line.lineNumber);
    }
  }
  if (lines.isNotEmpty && lines.last.opensBlock) {
    throw _syntaxError('expected an indented block', lines.last.lineNumber + 1);
  }
}

/// Rejects `yield` anywhere and `return` outside a nested function body.
void _checkReturnAndYield(List<_LogicalLine> lines) {
  final functionIndents = <int>[];
  for (final line in lines) {
    while (functionIndents.isNotEmpty && line.indent <= functionIndents.last) {
      functionIndents.removeLast();
    }
    final inFunction = functionIndents.isNotEmpty || line.startsFunction;
    for (final token in line.tokens) {
      if (token.isName('yield') || (token.isName('return') && !inFunction)) {
        throw WorkflowException(_returnYieldMessage);
      }
    }
    if (line.startsFunction && line.opensBlock) {
      functionIndents.add(line.indent);
    }
  }
}

void _checkLine(_LogicalLine line) {
  final tokens = line.tokens;
  for (var i = 0; i < tokens.length; i++) {
    final token = tokens[i];
    if (token.kind != _Kind.name) continue;
    final previous = i > 0 ? tokens[i - 1] : null;
    final next = i + 1 < tokens.length ? tokens[i + 1] : null;
    if (previous != null && previous.isOp('.')) {
      if (token.text.startsWith('_')) {
        throw WorkflowException(
            "attribute '${token.text}' is not allowed in workflow scripts");
      }
      continue;
    }
    switch (token.text) {
      case 'import':
        throw WorkflowException(
            'import statements are not allowed in workflow scripts');
      case 'while':
        throw WorkflowException('while loops are not allowed in workflow '
            'scripts; use bounded for loops');
    }
    if (token.text.startsWith('__') &&
        !_isDefinitionName(previous) &&
        !_isParameterOrKeyword(line, previous, next)) {
      throw WorkflowException(
          "name '${token.text}' is not allowed in workflow scripts");
    }
  }
}

/// Whether a name follows `def` or `class` (a definition, not a reference).
bool _isDefinitionName(_Token? previous) =>
    previous != null && (previous.isName('def') || previous.isName('class'));

/// Whether a name is a call keyword argument or a function parameter, which
/// Python parses as an argument rather than a name reference.
bool _isParameterOrKeyword(_LogicalLine line, _Token? previous, _Token? next) {
  final afterSeparator = previous != null &&
      (previous.isOp('(') ||
          previous.isOp(',') ||
          previous.isOp('*') ||
          previous.isOp('**'));
  if (!afterSeparator || next == null) return false;
  if (next.isOp('=')) return true;
  return line.startsFunction &&
      (next.isOp(',') || next.isOp(')') || next.isOp(':'));
}
