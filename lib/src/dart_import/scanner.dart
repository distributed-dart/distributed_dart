part of distributed_dart;

/**
 * Simple scanner implementation to scan for imports and comments in Dart files.
 */
class Scanner {
  List<int> bytes;
  int byteOffset = -1;
  List<String> paths = new List<String>();
  
  /* This is a primitive way to simulate token system. Because we only need to 
   * know if the next string is an import, export or part operation is should 
   * be enough.
   */
  bool nextTokenIsImportant = false;
  
  Scanner(Runes sourcecode) {
    bytes = sourcecode.toList(growable: false);
  }
  
  int nextByte() => byteAt(++byteOffset);

  int peek() => byteAt(byteOffset + 1);

  int byteAt(int index) => bytes[index];
  
  int advance() => bytes[++byteOffset];
  
  void scan() {
    _log("Running scan()");
    int next = advance();
    while (!identical(next, _U.$EOF)) {
      next = bigSwitch(next);
      _log("bigSwich output = $next");
    }
  }
  
  int bigSwitch(int next) {
    _log("Running bigSwitch($next)");
    if (identical(next, _U.$SPACE) || identical(next, _U.$TAB)
        || identical(next, _U.$LF) || identical(next, _U.$CR)) {
      // Do nothing as we don't collect white space.
      next = advance();
      while (identical(next, _U.$SPACE)) {
        next = advance();
      }
      return next;
    }
    
    if (_U.$a <= next && next <= _U.$z) {
      if (identical(_U.$r, next)) {
        return tokenizeRawStringKeywordOrIdentifier(next);
      }
      return tokenizeKeywordOrIdentifier(next, true);
    }
    
    if (identical(next, _U.$DQ) || identical(next, _U.$SQ)) {
      return tokenizeString(next, byteOffset, false);
    }
    
    if (identical(next, _U.$SLASH)) {
      return tokenizeSlashOrComment(next);
    }
    
    if (identical(next, _U.$EOF)) {
      return _U.$EOF;
    }
    
    // We only need to check for chars we find important.
    return advance(); // Ignore and get next char
  }
  
  int tokenizeRawStringKeywordOrIdentifier(int next) {
    _log("Running tokenizeRawStringKeywordOrIdentifier($next)");
    
    int nextnext = peek();
    if (identical(nextnext, _U.$DQ) || identical(nextnext, _U.$SQ)) {
      int start = byteOffset;
      next = advance();
      return tokenizeString(next, start, true);
    }
    return tokenizeKeywordOrIdentifier(next, true);
  }
  
  int tokenizeKeywordOrIdentifier(int next, bool allowDollar) {
    _log("Running tokenizeKeywordOrIdentifier($next, $allowDollar)");
    
    StringBuffer state = new StringBuffer();
    int start = byteOffset;
    
    while (_U.$a <= next && next <= _U.$z) {
      state.writeCharCode(next);
      next = advance();
    }
    
    // BEGIN: Keyword check (we only need: import, part, export
    String keyword = state.toString();
    if (keyword == "import" || 
        keyword == "part" || 
        keyword == "library" ||
        keyword == "export" ||
        keyword == "as") {
      
      _log("'$keyword' is a keyword!");
      
      nextTokenIsImportant = true;
      return next;
    } else {
      /* This is not a keyword but an identifier. Because identifiers is not
       * allowed before an import, export or part statement we can assume we are
       * finish.
       */
      _log("'$keyword' is an identifier!");
      
      if (nextTokenIsImportant) {
        return next;
      } else {
        return _U.$EOF;  
      }
    }
    // END: Keyword check
  }

  int tokenizeString(int next, int start, bool raw) {
    _log("Running tokenizeString($next, $start, $raw)");
    
    int quoteChar = next;
    next = advance();
    if (identical(quoteChar, next)) {
      next = advance();
      if (identical(quoteChar, next)) {
        // Multiline string.
        return tokenizeMultiLineString(quoteChar, start, raw);
      } else {
        // Empty string.
        return appendPath(utf8String(start, -1), next);
      }
    }
    if (raw) {
      return tokenizeSingleLineRawString(next, quoteChar, start);
    } else {
      return tokenizeSingleLineString(next, quoteChar, start);
    }
  }
  
  int tokenizeSingleLineRawString(int next, int quoteChar, int start) {
    _log("Running tokenizeSingleLineRawString($next, $quoteChar, $start)");
    
    next = advance();
    while (next != _U.$EOF) {
      if (identical(next, quoteChar)) {
        return appendPath(utf8String(start, 0), advance());
      } else if (identical(next, _U.$LF) || identical(next, _U.$CR)) {
        return error("unterminated string literal");
      }
      next = advance();
    }
    return error("unterminated string literal");
  }
  
  int tokenizeSingleLineString(int next, int quoteChar, int start) {
    _log("Running tokenizeSingleLineString($next, $quoteChar, $start)");
    
    while (!identical(next, quoteChar)) {
      if (identical(next, _U.$BACKSLASH)) {
        next = advance();
      } else if (identical(next, _U.$$)) {
        // URI's can't use String Interpolation
        return error("uri's can't contain string interpolation");
      }
      if (next <= _U.$CR
          && (identical(next, _U.$LF) || 
              identical(next, _U.$CR) || 
              identical(next, _U.$EOF))) {
        return error("unterminated string literal");
      }
      next = advance();
    }
    return appendPath(utf8String(start, 0), advance());
  }
  
  int tokenizeSlashOrComment(int next) {
    _log("Running tokenizeSlashOrComment($next)");
    
    next = advance();
    if (identical(_U.$STAR, next)) {
      return tokenizeMultiLineComment(next);
    } else if (identical(_U.$SLASH, next)) {
      return tokenizeSingleLineComment(next);
    } else {
      // The rest of choices is /= and this is not allowed with imports.
      return _U.$EOF;
    }
  }
  
  int tokenizeMultiLineComment(int next) {
    _log("Running tokenizeMultiLineComment($next)");
    
    int nesting = 1;
    next = advance();
    while (true) {
      if (identical(_U.$EOF, next)) {
        // TODO(ahe): Report error.
        return next;
      } else if (identical(_U.$STAR, next)) {
        next = advance();
        if (identical(_U.$SLASH, next)) {
          --nesting;
          if (0 == nesting) {
            next = advance();
            appendComment();
            return next;
          } else {
            next = advance();
          }
        }
      } else if (identical(_U.$SLASH, next)) {
        next = advance();
        if (identical(_U.$STAR, next)) {
          next = advance();
          ++nesting;
        }
      } else {
        next = advance();
      }
    }
  }
  
  int tokenizeSingleLineComment(int next) {
    _log("Running tokenizeSingleLineComment($next)");
    
    while (true) {
      next = advance();
      if (identical(_U.$LF, next) || 
          identical(_U.$CR, next) || 
          identical(_U.$EOF, next)) {
        appendComment();
        return next;
      }
    }
  }
  
  int tokenizeMultiLineRawString(int quoteChar, int start) {
    _log("Running tokenizeMultiLineRawString($quoteChar, $start)");
    
    int next = advance();
    outer: while (!identical(next, _U.$EOF)) {
      while (!identical(next, quoteChar)) {
        next = advance();
        if (identical(next, _U.$EOF)) break outer;
      }
      next = advance();
      if (identical(next, quoteChar)) {
        next = advance();
        if (identical(next, quoteChar)) {
          // appendByteStringToken(STRING_INFO, utf8String(start, 0));
          // return advance();
          return appendPath(utf8String(start, 0), advance());
        }
      }
    }
    return error("unterminated string literal");
  }
  
  int tokenizeMultiLineString(int quoteChar, int start, bool raw) {
    _log("Running tokenizeMultiLineString($quoteChar, $start, $raw)");
    
    if (raw) return tokenizeMultiLineRawString(quoteChar, start);
    int next = advance();
    while (!identical(next, _U.$EOF)) {
      if (identical(next, _U.$$)) {
        start = byteOffset;
        continue;
      }
      if (identical(next, quoteChar)) {
        next = advance();
        if (identical(next, quoteChar)) {
          next = advance();
          if (identical(next, quoteChar)) {
            return appendPath(utf8String(start,0), advance());
          }
        }
        continue;
      }
      if (identical(next, _U.$BACKSLASH)) {
        next = advance();
        if (identical(next, _U.$EOF)) break;
      }
      next = advance();
    }
    return error("unterminated string literal");
  }
  
  String utf8String(int start, int offset) {
    _log("Running utf8String($start, $offset)");
    
    return new String.fromCharCodes(bytes.sublist(start,byteOffset+offset+1));
  }
  
  int error(String message) {
    _err("Running error($message)");
    
    throw message;
  }
  
  int appendPath(String path, int returnValueIfAppended) {
    _log("Running appendPath($path, $returnValueIfAppended)");
    
    if (nextTokenIsImportant) {
      paths.add(path);
      nextTokenIsImportant = false;
    }
    return returnValueIfAppended;
  }
  
  void appendComment() {
    _log("Running appendComment()");
    // Do Nothing
  }
}
