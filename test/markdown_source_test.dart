import 'package:flutter_test/flutter_test.dart';
import 'package:para_workspace/ui/markdown_source.dart';

void main() {
  group('front matter', () {
    test('valid map preserves BOM, CRLF, comments and unknown fields', () {
      const source =
          '\uFEFF---\r\ntype: recipe\r\ntags:\r\n  - pasta\r\n'
          '# retain this comment\r\ncustom: {nested: yes}\r\n---\r\n\r\n# Title\r\n';
      final metadata = MarkdownFrontMatter.tryParse(source)!;
      expect(metadata.summary, 'recipe · pasta');
      final blocks = markdownBlocks(source);
      expect(blocks.map((b) => b.kind), [
        MarkdownBlockKind.metadata,
        MarkdownBlockKind.heading,
      ]);
      expect(metadata.block.text(source), startsWith('\uFEFF---\r\n'));
      expect(source.substring(metadata.block.end), '\r\n\r\n# Title\r\n');
      expect(
        metadata.block.text(source),
        contains('# retain this comment\r\n'),
      );
    });
    test(
      'rules, invalid YAML and unclosed headers remain ordinary Markdown',
      () {
        for (final source in [
          '---\n\nText\n---\nEnd',
          '---\ntags: [broken\n---\n# Title',
          '---\ntype: recipe\n# Title',
          '\n---\ntype: recipe\n---',
          '---\n- item\n---',
        ]) {
          expect(MarkdownFrontMatter.tryParse(source), isNull);
          expect(
            markdownBlocks(
              source,
            ).any((b) => b.kind == MarkdownBlockKind.metadata),
            isFalse,
          );
        }
      },
    );
    test('metadata link definitions cannot leak into document rendering', () {
      const source =
          '---\ncustom: |\n  [fake]: https://wrong.test\n---\n\n'
          '[real]: https://right.test\n';
      final definitions = markdownReferenceDefinitions(source);
      expect(definitions, contains('https://right.test'));
      expect(definitions, isNot(contains('https://wrong.test')));
    });
  });
  group('source blocks', () {
    test(
      'all ranges point into original CRLF Unicode source without rewriting',
      () {
        const source =
            '\r\n# Äpfel 🍎\r\n\r\nAbsatz  eins\r\nFortsetzung\r\n\r\n'
            '```dart\r\n- [ ] code\r\n\r\nprint("x");\r\n```\r\n\r\nEnde\r\n';
        final blocks = markdownBlocks(source);
        expect(blocks.map((b) => b.kind), [
          MarkdownBlockKind.heading,
          MarkdownBlockKind.paragraph,
          MarkdownBlockKind.code,
          MarkdownBlockKind.paragraph,
        ]);
        expect(blocks[1].text(source), 'Absatz  eins\r\nFortsetzung');
        expect(blocks[2].text(source), contains('\r\n\r\n'));
        var offset = 0;
        final roundtrip = StringBuffer();
        for (final block in blocks) {
          roundtrip.write(source.substring(offset, block.start));
          roundtrip.write(block.text(source));
          offset = block.end;
        }
        roundtrip.write(source.substring(offset));
        expect(roundtrip.toString(), source);
      },
    );

    test(
      'unterminated fences, indented code, nested lists remain coherent',
      () {
        const source =
            '    code\n\n    more\n\n- one\n  - nested\n\n  continuation\n\n'
            'Title\n=====\n\n~~~js\n# not a heading\n\nstill code';
        final blocks = markdownBlocks(source);
        expect(blocks.map((b) => b.kind), [
          MarkdownBlockKind.code,
          MarkdownBlockKind.list,
          MarkdownBlockKind.heading,
          MarkdownBlockKind.code,
        ]);
        expect(blocks[1].text(source), '- one\n  - nested\n\n  continuation');
        expect(blocks.last.text(source), endsWith('still code'));
      },
    );

    test(
      'safe tables are units and malformed tables never become cell models',
      () {
        const source =
            'Before\n\n| A | B |\n| --- | :---: |\n| x | y |\n\nAfter';
        final blocks = markdownBlocks(source);
        expect(blocks[1].kind, MarkdownBlockKind.table);
        expect(
          MarkdownSourceTable.tryParse('| A | B |\n| --- | --- |\n| x |'),
          isNull,
        );
      },
    );
  });

  group('checkbox source association', () {
    test('only rendered GFM tasks, including nested/quoted/ordered tasks', () {
      const source =
          '- [ ] live\r\n  - [x] nested\r\n\r\n'
          '> - [X] quoted\r\n\r\n1. [ ] ordered\r\n\r\n'
          '```md\r\n- [ ] fenced\r\n```\r\n\r\n'
          '    - [ ] indented\r\n\r\n\\- [ ] escaped\r\n\r\n'
          '<pre>\r\n- [ ] html\r\n</pre>\r\n';
      final checks = markdownCheckboxes(source);
      expect(checks.map((c) => c.checked), [false, true, true, false]);
      expect(checks.map((c) => source.substring(c.offset - 1, c.offset + 2)), [
        '[ ]',
        '[x]',
        '[X]',
        '[ ]',
      ]);
      final changed = source.replaceRange(
        checks[0].offset,
        checks[0].offset + 1,
        'x',
      );
      expect(
        changed.substring(0, checks[0].offset),
        source.substring(0, checks[0].offset),
      );
      expect(
        changed.substring(checks[0].offset + 1),
        source.substring(checks[0].offset + 1),
      );
    });

    test('code inside lists never gets a task source offset', () {
      const source =
          '- [ ] actual\n\n  ```md\n  - [ ] code\n  ```\n\n- [x] last';
      final checks = markdownCheckboxes(source);
      expect(checks.length, 2);
      expect(checks.map((c) => c.offset), [
        source.indexOf('[ ]') + 1,
        source.lastIndexOf('[x]') + 1,
      ]);
    });

    test('user marker-looking text and duplicate labels are safe', () {
      const source = '- [ ] same \uE000para-task-0\uE001\n- [x] same';
      final checks = markdownCheckboxes(source);
      expect(checks.length, 2);
      expect(checks[0].offset, source.indexOf('[ ]') + 1);
      expect(checks[1].offset, source.indexOf('[x]') + 1);
    });
  });

  group('safe table mutations', () {
    const source =
        '|  Name  | Value |\r\n| :--- | ---: |\r\n'
        '|  old  | `a\\|b` |\r\n| last | c\\|d |';

    test('cell mutation preserves surrounding bytes, alignment and CRLF', () {
      final table = MarkdownSourceTable.tryParse(source)!;
      expect(table.cells, [
        ['Name', 'Value'],
        ['old', '`a\\|b`'],
        ['last', 'c\\|d'],
      ]);
      expect(table.newline, '\r\n');
      expect(
        table.replaceCell(1, 0, 'new 🍎'),
        source.replaceFirst('old', 'new 🍎'),
      );
      expect(
        table.replaceCell(1, 1, '`a|z`'),
        source.replaceFirst('`a\\|b`', '`a\\|z`'),
      );
      expect(table.replaceCell(2, 1, 'c\\|d'), source);
    });

    test('empty cells and header-only tables retain their shape', () {
      final created = MarkdownSourceTable.create(3, 4, newline: '\r\n');
      final table = MarkdownSourceTable.tryParse(created)!;
      expect(table.cells.length, 4);
      expect(table.cells.every((r) => r.length == 3), isTrue);
      final header = MarkdownSourceTable.tryParse(
        MarkdownSourceTable.create(1, 1),
      )!;
      expect(header.cells.length, 1);
      final inserted = MarkdownSourceTable.tryParse(header.insertRow(0))!;
      expect(inserted.cells.length, 2);
      expect(inserted.deleteRow(1), header.source);
    });

    test('row insertion/deletion preserve existing rows and final newline', () {
      final table = MarkdownSourceTable.tryParse(source)!;
      final inserted = table.insertRow(0);
      expect(inserted, source.replaceFirst('|  old', '|  |  |\r\n|  old'));
      expect(MarkdownSourceTable.tryParse(inserted)!.deleteRow(1), source);
      final appended = table.insertRow(2);
      expect(appended.endsWith('\r\n|  |  |'), isTrue);
      expect(MarkdownSourceTable.tryParse(appended)!.deleteRow(3), source);
      final ended = MarkdownSourceTable.tryParse('$source\r\n')!;
      expect(
        MarkdownSourceTable.tryParse(ended.insertRow(2))!.deleteRow(3),
        '$source\r\n',
      );
    });

    test('columns retain other cell raw formatting and alignment', () {
      final table = MarkdownSourceTable.tryParse(source)!;
      final inserted = table.insertColumn(0);
      expect(inserted, contains('| :--- | --- | ---: |'));
      final model = MarkdownSourceTable.tryParse(inserted)!;
      expect(model.cells.first.length, 3);
      expect(model.deleteColumn(1), source);
    });

    test('bounds/unsafe inputs rejected without changing source', () {
      final table = MarkdownSourceTable.tryParse(source)!;
      expect(() => table.deleteRow(0), throwsArgumentError);
      expect(() => table.replaceCell(1, 0, 'multi\nline'), throwsArgumentError);
      expect(() => table.insertColumn(8), throwsRangeError);
      expect(
        () => MarkdownSourceTable.tryParse('| A |\n| --- |')!.deleteColumn(0),
        throwsArgumentError,
      );
      expect(
        MarkdownSourceTable.tryParse('| A | B |\n| --- | --- |\n| `a|b` | c |'),
        isNull,
      );
      expect(
        MarkdownSourceTable.tryParse('| A |\n| --- |\n| incomplete ` |'),
        isNull,
      );
      expect(MarkdownSourceTable.tryParse('    | A |\n    | --- |'), isNull);
      expect(table.source, source);
    });
  });

  test(
    'render-only link definitions include destination and title continuation',
    () {
      const source =
          '[ref]: https://example.org "Title"\n\nText [link][ref].\n\n'
          '[other]:\nhttps://example.net\n  "Other"\n\nAfter';
      expect(
        markdownReferenceDefinitions(source),
        '[ref]: https://example.org "Title"\n[other]:\nhttps://example.net\n  "Other"\n',
      );
      expect(source, contains('Text [link][ref].'));
    },
  );
  test('definition collection ignores code and preserves multiline titles', () {
    const source =
        '```md\n[bad]: https://bad.example\n```\n\n'
        '    [also-bad]: https://bad.example\n\n'
        '[good]: https://good.example\n  "A title\n  on two lines"\n\n'
        '> [quote]: https://quote.example\n';
    final definitions = markdownReferenceDefinitions(source);
    expect(definitions, isNot(contains('[bad]')));
    expect(definitions, isNot(contains('[also-bad]')));
    expect(
      definitions,
      contains('[good]: https://good.example\n  "A title\n  on two lines"'),
    );
    expect(definitions, contains('[quote]: https://quote.example'));
  });
  test(
    'reference collector does not retry ordinary bracket paragraphs forever',
    () {
      const source =
          '# Titel\r\n\r\n\r\nAlpha  \r\nBeta\r\n\r\n'
          '[x][ref]\r\n\r\n[ref]: https://example.com\r\n';
      expect(
        markdownReferenceDefinitions(source),
        '[ref]: https://example.com\n',
      );
      expect(
        markdownReferenceDefinitions('[invalid]: not valid url\n\n[x]'),
        '',
      );
    },
  );
}
