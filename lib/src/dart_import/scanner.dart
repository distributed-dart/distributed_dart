part of distributed_dart;

/**
 * Simple scanner implementation to scan for dependencies in Dart files. The
 * scanner will automatically stop when no more import statements is possible.
 * More information can be found in the
 * [Dart Language Specification](http://goo.gl/rhiyX).
 * 
 * _Highly inspired by the Dart project's own 
 * [scanner.dart](http://goo.gl/Ut5w7). The main difference is we don't need to
 * scan for the whole language but only need a small subset. Also we want to
 * make it easy to get details like import statements directly without need of
 * parsing tokens._
 */
class Scanner {
  List<int> _bytes;
  int _byteOffset;
  List<String> _dependencies;
  
  /* This is a primitive way to simulate token system. Because we only need to 
   * know if the next string is an import, export or part operation is should 
   * be enough.
   * 
   * If nextTokenIsImportant is true we need to take the next string. Also, if
   * we find a String and nextTokenIsImportant is false we can stop the scan.
   */
  bool _nextTokenIsImportant;
  String _keywordBefore;
  
  /**
   * Create new instance of [Scanner] to parse a instance of [Runes]. The 
   * instance of [Runes] should contain the content of a syntax valid Dart file.
   */
  Scanner(Runes sourcecode) {
    _bytes = sourcecode.toList(growable: false);
  }
  
  /**
   * Scan instance of [Runes] given on initialization. Returns a list of Strings
   * where each string is the URI from an import statement. Please notice the
   * possibility to get URI's like 'dart:async'.
   */
  List<String> getDependencies() {
    _log("Running _getDependencies()");
    
    // Reset scanner instance (if someone want to call getDependencies() twice.
    _dependencies = new List<String>();
    _byteOffset = -1;
    _nextTokenIsImportant = false;
    _keywordBefore = "";
    
    int next = _advance();
    while (!identical(next, _U.$EOF)) {
      try {
        next = _bigSwitch(next);
      } on RangeError {
        next = _U.$EOF;
      }
      _log("bigSwich output = $next");
    }
    
    _log("Return value from _getDependencies() = $_dependencies");
    return _dependencies;
  }
  
  int _peek() => _byteAt(_byteOffset + 1);

  int _byteAt(int index) => _bytes[index];
  
  int _advance() => _bytes[++_byteOffset];

  int _bigSwitch(int next) {
    _log("Running _bigSwitch($next)");
    if (identical(next, _U.$SPACE) || identical(next, _U.$TAB)
        || identical(next, _U.$LF) || identical(next, _U.$CR)) {
      // Do nothing as we don't collect white space.
      next = _advance();
      while (identical(next, _U.$SPACE)) {
        next = _advance();
      }
      return next;
    }
    
    if ((_U.$a <= next && next <= _U.$z) ||
        (_U.$A <= next && next <= _U.$Z)) {
      if (identical(_U.$r, next)) {
        return _tokenizeRawStringKeywordOrIdentifier(next);
      }
      return _tokenizeKeywordOrIdentifier(next, true);
    }
    
    if (identical(next, _U.$DQ) || identical(next, _U.$SQ)) {
      return _tokenizeString(next, _byteOffset, false);
    }
    
    if (identical(next, _U.$SLASH)) {
      return _tokenizeSlashOrComment(next);
    }
    
    if (identical(next, _U.$EOF)) {
      return _U.$EOF;
    }
    
    if (identical(next, _U.$SEMICOLON)) {
      _nextTokenIsImportant = false;
    }
    
    if (identical(next, _U.$AT)) {
      return _tokenizeAt(next);
    }
    
    if (identical(next, _U.$HASH)) {
      return _tokenizeTag(next);
    }
    
    // We only need to check for chars we find important.
    return _advance(); // Ignore and get next char
  }
  
  int _tokenizeRawStringKeywordOrIdentifier(int next) {
    _log("Running _tokenizeRawStringKeywordOrIdentifier($next)");
    
    int nextnext = _peek();
    if (identical(nextnext, _U.$DQ) || identical(nextnext, _U.$SQ)) {
      int start = _byteOffset;
      next = _advance();
      return _tokenizeString(next, start, true);
    }
    return _tokenizeKeywordOrIdentifier(next, true);
  }
  
  int _tokenizeKeywordOrIdentifier(int next, bool allowDollar) {
    _log("Running _tokenizeKeywordOrIdentifier($next, $allowDollar)");
    
    StringBuffer state = new StringBuffer();
    int start = _byteOffset;
    
    while ((_U.$a <= next && next <= _U.$z) || 
           (_U.$A <= next && next <= _U.$Z)) {
      state.writeCharCode(next);
      next = _advance();
    }
    
    // BEGIN: Keyword check (we only need: import, part, export, as)
    String keyword = state.toString();
    if (keyword == "import" || 
        keyword == "part" || 
        keyword == "library" ||
        keyword == "export" ||
        keyword == "as" ||
        keyword == "show" || 
        keyword == "hide") {
      
      _log("'$keyword' is a keyword!");
      
      _nextTokenIsImportant = true;
      _keywordBefore = keyword;
      return next;
    } else {
      /* This is not a keyword but an identifier. Because identifiers is not
       * allowed before an import, export or part statement we can assume we are
       * finish.
       */
      _log("'$keyword' is an identifier!");
      _log("     and _nextTokenIsImportant = $_nextTokenIsImportant");
      _log("     and _keywordBefore = $_keywordBefore");
      
      if (_nextTokenIsImportant) {
        return (_keywordBefore == "part" && keyword == "of") ? _U.$EOF : next;
      } else {
        return _U.$EOF;
      }
    }
    // END: Keyword check
  }

  int _tokenizeString(int next, int start, bool raw) {
    _log("Running _tokenizeString($next, $start, $raw)");
    
    int quoteChar = next;
    next = _advance();
    if (identical(quoteChar, next)) {
      next = _advance();
      if (identical(quoteChar, next)) {
        // Multiline string.
        return _tokenizeMultiLineString(quoteChar, start, raw);
      } else {
        // Empty string.
        return _appendPath(_utf8String(start, -1), next);
      }
    }
    if (raw) {
      return _tokenizeSingleLineRawString(next, quoteChar, start);
    } else {
      return _tokenizeSingleLineString(next, quoteChar, start);
    }
  }
  
  int _tokenizeSingleLineRawString(int next, int quoteChar, int start) {
    _log("Running _tokenizeSingleLineRawString($next, $quoteChar, $start)");
    
    next = _advance();
    while (next != _U.$EOF) {
      if (identical(next, quoteChar)) {
        return _appendPath(_utf8String(start, 0), _advance());
      } else if (identical(next, _U.$LF) || identical(next, _U.$CR)) {
        return _error("unterminated string literal");
      }
      next = _advance();
    }
    return _error("unterminated string literal");
  }
  
  int _tokenizeSingleLineString(int next, int quoteChar, int start) {
    _log("Running _tokenizeSingleLineString($next, $quoteChar, $start)");
    
    while (!identical(next, quoteChar)) {
      if (identical(next, _U.$BACKSLASH)) {
        next = _advance();
      } else if (identical(next, _U.$$)) {
        // URI's can't use String Interpolation
        return _error("uri's can't contain string interpolation");
      }
      if (next <= _U.$CR
          && (identical(next, _U.$LF) || 
              identical(next, _U.$CR) || 
              identical(next, _U.$EOF))) {
        return _error("unterminated string literal");
      }
      next = _advance();
    }
    return _appendPath(_utf8String(start + 1, -1), _advance());
  }
  
  int _tokenizeSlashOrComment(int next) {
    _log("Running _tokenizeSlashOrComment($next)");
    
    next = _advance();
    if (identical(_U.$STAR, next)) {
      return _tokenizeMultiLineComment(next);
    } else if (identical(_U.$SLASH, next)) {
      return _tokenizeSingleLineComment(next);
    } else {
      // The rest of choices is /= and this is not allowed with imports.
      return _U.$EOF;
    }
  }
  
  int _tokenizeMultiLineComment(int next) {
    _log("Running _tokenizeMultiLineComment($next)");
    
    int nesting = 1;
    next = _advance();
    while (true) {
      if (identical(_U.$EOF, next)) {
        // TODO(ahe): Report error.
        return next;
      } else if (identical(_U.$STAR, next)) {
        next = _advance();
        if (identical(_U.$SLASH, next)) {
          --nesting;
          if (0 == nesting) {
            next = _advance();
            _appendComment();
            return next;
          } else {
            next = _advance();
          }
        }
      } else if (identical(_U.$SLASH, next)) {
        next = _advance();
        if (identical(_U.$STAR, next)) {
          next = _advance();
          ++nesting;
        }
      } else {
        next = _advance();
      }
    }
  }
  
  int _tokenizeSingleLineComment(int next) {
    _log("Running _tokenizeSingleLineComment($next)");
    
    while (true) {
      next = _advance();
      if (identical(_U.$LF, next) || 
          identical(_U.$CR, next) || 
          identical(_U.$EOF, next)) {
        _appendComment();
        return next;
      }
    }
  }
  
  int _tokenizeMultiLineRawString(int quoteChar, int start) {
    _log("Running _tokenizeMultiLineRawString($quoteChar, $start)");
    
    int next = _advance();
    outer: while (!identical(next, _U.$EOF)) {
      while (!identical(next, quoteChar)) {
        next = _advance();
        if (identical(next, _U.$EOF)) break outer;
      }
      next = _advance();
      if (identical(next, quoteChar)) {
        next = _advance();
        if (identical(next, quoteChar)) {
          // appendByteStringToken(STRING_INFO, utf8String(start, 0));
          // return advance();
          return _appendPath(_utf8String(start, 0), _advance());
        }
      }
    }
    return _error("unterminated string literal");
  }
  
  int _tokenizeMultiLineString(int quoteChar, int start, bool raw) {
    _log("Running _tokenizeMultiLineString($quoteChar, $start, $raw)");
    
    if (raw) return _tokenizeMultiLineRawString(quoteChar, start);
    int next = _advance();
    while (!identical(next, _U.$EOF)) {
      if (identical(next, _U.$$)) {
        start = _byteOffset;
        continue;
      }
      if (identical(next, quoteChar)) {
        next = _advance();
        if (identical(next, quoteChar)) {
          next = _advance();
          if (identical(next, quoteChar)) {
            return _appendPath(_utf8String(start,0), _advance());
          }
        }
        continue;
      }
      if (identical(next, _U.$BACKSLASH)) {
        next = _advance();
        if (identical(next, _U.$EOF)) break;
      }
      next = _advance();
    }
    return _error("unterminated string literal");
  }
  
  int _tokenizeAt(int next) {
    _log("Running _tokenizeAt($next");
    next = _advance();
    bool partOfMetaData = true;
        
    while(true) {
      while ((_U.$a <= next && next <= _U.$z) ||
            (_U.$A <= next && next <= _U.$Z) ||
            (_U.$0 <= next && next <= _U.$9) ||
            (identical(next, _U.$_)) ){
        if (partOfMetaData) {
          next = _advance();  
        } else {
          return next;
        }
      }
      
      if (identical(next, _U.$SPACE) || identical(next, _U.$TAB)
          || identical(next, _U.$LF) || identical(next, _U.$CR)) {
        // Do nothing as we don't collect white space.
        next = _advance();
        while (identical(next, _U.$SPACE)) {
          next = _advance();
        }
        partOfMetaData = false;
      } else if (identical(next, _U.$OPEN_PAREN)) {
        int paranCount = 0;
        
        do {
          if (identical(next, _U.$OPEN_PAREN)) {
            paranCount++;
          } else if (identical(next, _U.$CLOSE_PAREN)) {
            paranCount--;
          }
          next = _advance();
        } while (paranCount != 0);
        
        partOfMetaData = false;
      } else if (!identical(next, _U.$PERIOD)){
        partOfMetaData = true;
        next = _advance();
      } else {
        next = _advance();
      }
    }
    return next;
  }
  
  int _tokenizeTag(int next) {
    _log("Running _tokenizeTag($next");
    // # or #!.*[\n\r]
    if (_byteOffset == 0) {
      if (identical(_peek(), _U.$BANG)) {
        do {
          next = _advance();
        } while (!identical(next, _U.$LF) && 
                 !identical(next, _U.$CR) && 
                 !identical(next, _U.$EOF));
        return next;
      }
    }
    return _advance();
  }
  
  String _utf8String(int start, int offset) {
    _log("Running _utf8String($start, $offset)");
    
    return new String.fromCharCodes(_bytes.sublist(start,_byteOffset+offset+1));
  }
  
  int _error(String message) {
    _err("Running _error($message)");
    throw new ScannerException(message);
  }
  
  int _appendPath(String path, int returnValueIfAppended) {
    _log("Running _appendPath($path, $returnValueIfAppended)");
    
    if (_nextTokenIsImportant) {
      _dependencies.add(path);
      _nextTokenIsImportant = false;
    }
    return returnValueIfAppended;
  }
  
  void _appendComment() {
    _log("Running _appendComment()");
    // Comments is not important for us so just ignore.
  }
}
