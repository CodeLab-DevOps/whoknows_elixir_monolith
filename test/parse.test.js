const assert = require('assert');
const { parse } = require('../lib/parse');

describe('parse', function() {
  describe('Basic Parsing', function() {
    it('should parse simple key-value pairs', function() {
      const input = 'key1=value1\nkey2=value2';
      const result = parse(input);
      assert.deepStrictEqual(result, {
        key1: 'value1',
        key2: 'value2'
      });
    });

    it('should handle empty input', function() {
      const result = parse('');
      assert.deepStrictEqual(result, {});
    });

    it('should handle whitespace-only input', function() {
      const result = parse('   \n  \t  \n  ');
      assert.deepStrictEqual(result, {});
    });

    it('should handle single key-value pair', function() {
      const result = parse('single=value');
      assert.deepStrictEqual(result, {
        single: 'value'
      });
    });
  });

  describe('Whitespace Handling', function() {
    it('should trim whitespace around keys', function() {
      const input = '  key  =value';
      const result = parse(input);
      assert.deepStrictEqual(result, { key: 'value' });
    });

    it('should trim whitespace around values', function() {
      const input = 'key=  value  ';
      const result = parse(input);
      assert.deepStrictEqual(result, { key: 'value' });
    });

    it('should handle tabs and spaces', function() {
      const input = '\tkey\t=\tvalue\t';
      const result = parse(input);
      assert.deepStrictEqual(result, { key: 'value' });
    });

    it('should handle multiple spaces', function() {
      const input = 'key     =     value';
      const result = parse(input);
      assert.deepStrictEqual(result, { key: 'value' });
    });

    it('should preserve internal spaces in values', function() {
      const input = 'key=hello world';
      const result = parse(input);
      assert.deepStrictEqual(result, { key: 'hello world' });
    });
  });

  describe('Line Handling', function() {
    it('should handle multiple lines with different separators', function() {
      const input = 'key1=value1\nkey2=value2\rkey3=value3\r\nkey4=value4';
      const result = parse(input);
      assert.deepStrictEqual(result, {
        key1: 'value1',
        key2: 'value2',
        key3: 'value3',
        key4: 'value4'
      });
    });

    it('should skip empty lines', function() {
      const input = 'key1=value1\n\nkey2=value2\n\n\nkey3=value3';
      const result = parse(input);
      assert.deepStrictEqual(result, {
        key1: 'value1',
        key2: 'value2',
        key3: 'value3'
      });
    });

    it('should handle lines with only whitespace', function() {
      const input = 'key1=value1\n   \nkey2=value2\n\t\nkey3=value3';
      const result = parse(input);
      assert.deepStrictEqual(result, {
        key1: 'value1',
        key2: 'value2',
        key3: 'value3'
      });
    });

    it('should handle trailing newlines', function() {
      const input = 'key1=value1\nkey2=value2\n\n\n';
      const result = parse(input);
      assert.deepStrictEqual(result, {
        key1: 'value1',
        key2: 'value2'
      });
    });

    it('should handle leading newlines', function() {
      const input = '\n\n\nkey1=value1\nkey2=value2';
      const result = parse(input);
      assert.deepStrictEqual(result, {
        key1: 'value1',
        key2: 'value2'
      });
    });
  });

  describe('Comment Handling', function() {
    it('should ignore lines starting with #', function() {
      const input = '# This is a comment\nkey=value';
      const result = parse(input);
      assert.deepStrictEqual(result, { key: 'value' });
    });

    it('should ignore lines starting with # after whitespace', function() {
      const input = '  # This is a comment\nkey=value';
      const result = parse(input);
      assert.deepStrictEqual(result, { key: 'value' });
    });

    it('should handle multiple comment lines', function() {
      const input = '# Comment 1\n# Comment 2\nkey=value\n# Comment 3';
      const result = parse(input);
      assert.deepStrictEqual(result, { key: 'value' });
    });

    it('should handle inline comments (# in value is treated as part of value)', function() {
      const input = 'key=value # not a comment';
      const result = parse(input);
      assert.deepStrictEqual(result, { key: 'value # not a comment' });
    });

    it('should handle mixed comments and valid lines', function() {
      const input = '# Header comment\nkey1=value1\n# Middle comment\nkey2=value2\n# Footer comment';
      const result = parse(input);
      assert.deepStrictEqual(result, {
        key1: 'value1',
        key2: 'value2'
      });
    });
  });

  describe('Equal Sign Handling', function() {
    it('should handle key without value (equals at end)', function() {
      const input = 'key=';
      const result = parse(input);
      assert.deepStrictEqual(result, { key: '' });
    });

    it('should handle multiple equal signs in value', function() {
      const input = 'key=value=with=equals';
      const result = parse(input);
      assert.deepStrictEqual(result, { key: 'value=with=equals' });
    });

    it('should handle value with equation', function() {
      const input = 'formula=x=y+z';
      const result = parse(input);
      assert.deepStrictEqual(result, { formula: 'x=y+z' });
    });

    it('should skip lines without equal sign', function() {
      const input = 'key1=value1\ninvalidline\nkey2=value2';
      const result = parse(input);
      assert.deepStrictEqual(result, {
        key1: 'value1',
        key2: 'value2'
      });
    });

    it('should handle key with spaces and equals', function() {
      const input = 'my key = my value';
      const result = parse(input);
      assert.deepStrictEqual(result, { 'my key': 'my value' });
    });
  });

  describe('Special Characters', function() {
    it('should handle underscores in keys', function() {
      const input = 'my_key=value';
      const result = parse(input);
      assert.deepStrictEqual(result, { my_key: 'value' });
    });

    it('should handle dots in keys', function() {
      const input = 'my.key=value';
      const result = parse(input);
      assert.deepStrictEqual(result, { 'my.key': 'value' });
    });

    it('should handle hyphens in keys', function() {
      const input = 'my-key=value';
      const result = parse(input);
      assert.deepStrictEqual(result, { 'my-key': 'value' });
    });

    it('should handle numbers in keys', function() {
      const input = 'key123=value';
      const result = parse(input);
      assert.deepStrictEqual(result, { key123: 'value' });
    });

    it('should handle special characters in values', function() {
      const input = 'key=!@#$%^&*()';
      const result = parse(input);
      assert.deepStrictEqual(result, { key: '!@#$%^&*()' });
    });

    it('should handle unicode characters', function() {
      const input = 'key=Hello 世界 🌍';
      const result = parse(input);
      assert.deepStrictEqual(result, { key: 'Hello 世界 🌍' });
    });

    it('should handle quotes in values', function() {
      const input = 'key="quoted value"';
      const result = parse(input);
      assert.deepStrictEqual(result, { key: '"quoted value"' });
    });

    it('should handle single quotes in values', function() {
      const input = "key='single quoted'";
      const result = parse(input);
      assert.deepStrictEqual(result, { key: "'single quoted'" });
    });
  });

  describe('Duplicate Keys', function() {
    it('should use last value when key is duplicated', function() {
      const input = 'key=value1\nkey=value2\nkey=value3';
      const result = parse(input);
      assert.deepStrictEqual(result, { key: 'value3' });
    });

    it('should handle duplicates with different cases (case-sensitive)', function() {
      const input = 'key=value1\nKey=value2\nKEY=value3';
      const result = parse(input);
      assert.deepStrictEqual(result, {
        key: 'value1',
        Key: 'value2',
        KEY: 'value3'
      });
    });
  });

  describe('Edge Cases', function() {
    it('should handle very long lines', function() {
      const longValue = 'a'.repeat(10000);
      const input = `key=${longValue}`;
      const result = parse(input);
      assert.deepStrictEqual(result, { key: longValue });
    });

    it('should handle many key-value pairs', function() {
      const lines = [];
      for (let i = 0; i < 1000; i++) {
        lines.push(`key${i}=value${i}`);
      }
      const input = lines.join('\n');
      const result = parse(input);
      assert.strictEqual(Object.keys(result).length, 1000);
      assert.strictEqual(result.key0, 'value0');
      assert.strictEqual(result.key999, 'value999');
    });

    it('should handle empty key (just equals sign)', function() {
      const input = '=value';
      const result = parse(input);
      assert.deepStrictEqual(result, { '': 'value' });
    });

    it('should handle only equals sign', function() {
      const input = '=';
      const result = parse(input);
      assert.deepStrictEqual(result, { '': '' });
    });

    it('should handle line with only spaces and equals', function() {
      const input = '   =   ';
      const result = parse(input);
      assert.deepStrictEqual(result, { '': '' });
    });

    it('should handle backslashes in values', function() {
      const input = 'path=C:\\Users\\test\\file.txt';
      const result = parse(input);
      assert.deepStrictEqual(result, { path: 'C:\\Users\\test\\file.txt' });
    });

    it('should handle forward slashes in values', function() {
      const input = 'url=/path/to/resource';
      const result = parse(input);
      assert.deepStrictEqual(result, { url: '/path/to/resource' });
    });

    it('should handle URL-like values', function() {
      const input = 'url=https://example.com:8080/path?query=value';
      const result = parse(input);
      assert.deepStrictEqual(result, { url: 'https://example.com:8080/path?query=value' });
    });

    it('should handle JSON-like values (as strings)', function() {
      const input = 'config={"key":"value","nested":{"a":1}}';
      const result = parse(input);
      assert.deepStrictEqual(result, { config: '{"key":"value","nested":{"a":1}}' });
    });

    it('should handle values with newline escape sequences (as literal strings)', function() {
      const input = 'key=line1\\nline2';
      const result = parse(input);
      assert.deepStrictEqual(result, { key: 'line1\\nline2' });
    });
  });

  describe('Real-world Scenarios', function() {
    it('should parse .env file format', function() {
      const input = `
# Database configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=myapp
DB_USER=admin
DB_PASS=secret123

# API Keys
API_KEY=abc123xyz
SECRET_KEY=super_secret_key

# Feature Flags
FEATURE_X_ENABLED=true
DEBUG_MODE=false
`;
      const result = parse(input);
      assert.deepStrictEqual(result, {
        DB_HOST: 'localhost',
        DB_PORT: '5432',
        DB_NAME: 'myapp',
        DB_USER: 'admin',
        DB_PASS: 'secret123',
        API_KEY: 'abc123xyz',
        SECRET_KEY: 'super_secret_key',
        FEATURE_X_ENABLED: 'true',
        DEBUG_MODE: 'false'
      });
    });

    it('should handle configuration with various formats', function() {
      const input = `
# Application Settings
app.name=MyApp
app.version=1.0.0
app_environment=production

# Server Configuration
server-host=0.0.0.0
server-port=8080
serverTimeout=30000
`;
      const result = parse(input);
      assert.strictEqual(result['app.name'], 'MyApp');
      assert.strictEqual(result['app.version'], '1.0.0');
      assert.strictEqual(result['app_environment'], 'production');
      assert.strictEqual(result['server-host'], '0.0.0.0');
      assert.strictEqual(result['server-port'], '8080');
      assert.strictEqual(result['serverTimeout'], '30000');
    });

    it('should handle mixed valid and invalid lines gracefully', function() {
      const input = `
valid1=value1
this line has no equals sign
valid2=value2
# This is a comment
another invalid line
valid3=value3
`;
      const result = parse(input);
      assert.deepStrictEqual(result, {
        valid1: 'value1',
        valid2: 'value2',
        valid3: 'value3'
      });
    });
  });

  describe('Type Safety and Null Handling', function() {
    it('should handle null input gracefully', function() {
      assert.throws(() => parse(null), {
        name: 'TypeError'
      });
    });

    it('should handle undefined input gracefully', function() {
      assert.throws(() => parse(undefined), {
        name: 'TypeError'
      });
    });

    it('should handle non-string input gracefully', function() {
      assert.throws(() => parse(123), {
        name: 'TypeError'
      });
    });

    it('should handle object input gracefully', function() {
      assert.throws(() => parse({}), {
        name: 'TypeError'
      });
    });

    it('should handle array input gracefully', function() {
      assert.throws(() => parse([]), {
        name: 'TypeError'
      });
    });
  });

  describe('Performance Characteristics', function() {
    it('should handle input with many comments efficiently', function() {
      const lines = [];
      for (let i = 0; i < 500; i++) {
        lines.push(`# Comment ${i}`);
      }
      for (let i = 0; i < 500; i++) {
        lines.push(`key${i}=value${i}`);
      }
      const input = lines.join('\n');
      const result = parse(input);
      assert.strictEqual(Object.keys(result).length, 500);
    });

    it('should handle input with many empty lines efficiently', function() {
      const lines = [];
      for (let i = 0; i < 100; i++) {
        lines.push(`key${i}=value${i}`);
        lines.push('');
        lines.push('   ');
        lines.push('\t');
      }
      const input = lines.join('\n');
      const result = parse(input);
      assert.strictEqual(Object.keys(result).length, 100);
    });
  });

  describe('Boundary Value Analysis', function() {
    it('should handle single character key and value', function() {
      const input = 'a=b';
      const result = parse(input);
      assert.deepStrictEqual(result, { a: 'b' });
    });

    it('should handle key with maximum typical length', function() {
      const longKey = 'k'.repeat(255);
      const input = `${longKey}=value`;
      const result = parse(input);
      assert.deepStrictEqual(result, { [longKey]: 'value' });
    });

    it('should handle value with zero length', function() {
      const input = 'key=';
      const result = parse(input);
      assert.deepStrictEqual(result, { key: '' });
    });

    it('should handle only whitespace between keys and values', function() {
      const input = 'key     =     ';
      const result = parse(input);
      assert.deepStrictEqual(result, { key: '' });
    });
  });
});