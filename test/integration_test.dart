// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_pre_commit/src/hooks.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

void main() {
  Directory testDir;

  Future<void> _writeFile(String path, String contents) async {
    final file = File(join(testDir.path, path));
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }
    await file.writeAsString(contents);
  }

  Future<String> _readFile(String path) =>
      File(join(testDir.path, path)).readAsString();

  Future<int> _run(
    String program,
    List<String> arguments, {
    bool failOnError = true,
    Function(Stream<List<int>>) onStdout,
  }) async {
    print("\$ $program ${arguments.join(" ")}");
    final proc = await Process.start(
      program,
      arguments,
      workingDirectory: testDir.path,
    );
    if (onStdout != null) {
      onStdout(proc.stdout);
    } else {
      proc.stdout.listen(stdout.add);
    }
    proc.stderr.listen(stderr.add);
    final exitCode = await proc.exitCode;
    if (failOnError && exitCode != 0) {
      throw "Failed to run '$program ${arguments.join(" ")}' with exit code: $exitCode";
    }
    return exitCode;
  }

  Future<void> _git(List<String> arguments) async => _run("git", arguments);

  Future<int> _pub(
    List<String> arguments, {
    bool failOnError = true,
    Function(Stream<List<int>>) onStdout,
  }) async =>
      _run(
        Platform.isWindows ? "pub.bat" : "pub",
        arguments,
        failOnError: failOnError,
        onStdout: onStdout,
      );

  Future<int> _sut(
    List<String> arguments, {
    bool failOnError = true,
    Function(Stream<List<int>>) onStdout,
  }) async =>
      _pub(
        ["run", "dart_pre_commit", ...arguments],
        failOnError: failOnError,
        onStdout: onStdout,
      );

  setUp(() async {
    // create git repo
    testDir = await Directory.systemTemp.createTemp();
    await _git(const ["init"]);

    // create files
    await _writeFile("pubspec.yaml", """
name: test_project
version: 0.0.1

environment:
  sdk: ">=2.7.0 <3.0.0"

dependencies:
  meta: null
  dart_pre_commit:
    path: ${Directory.current.path}

dev_dependencies:
  lint: null
""");

    await _writeFile("lib/src/fix_imports.dart", """
// this is important
import "package:test_project/test_project.dart";
import "dart:io";
import "package:stuff/stuff.dart";

void main() {}
""");
    await _writeFile("bin/format.dart", """
import "package:test_project/test_project.dart";

void main() {
  final x = "this is a very very very very very very very very very very very very very very very very very very very very very very long string";
}
""");
    await _writeFile("lib/src/analyze.dart", """
void main() {
  var x = "constant";
}
""");

    // init dart
    await _pub(const ["get"]);
  });

  tearDown(() async {
    await testDir.delete(recursive: true);
  });

  test('fix imports', () async {
    await _git(const ["add", "lib/src/fix_imports.dart"]);
    await _sut(const ["--no-analyze"]);

    final data = await _readFile("lib/src/fix_imports.dart");
    expect(data, """
// this is important
import "dart:io";

import "package:stuff/stuff.dart";

import "../test_project.dart";

void main() {}
""");
  });

  test("format", () async {
    await _git(const ["add", "bin/format.dart"]);
    await _sut(const ["--no-analyze"]);

    final data = await _readFile("bin/format.dart");
    expect(data, """
import "package:test_project/test_project.dart";

void main() {
  final x =
      "this is a very very very very very very very very very very very very very very very very very very very very very very long string";
}
""");
  });

  test("analyze", () async {
    await _git(const ["add", "lib/src/analyze.dart"]);

    final lines = <String>[];
    final code = await _sut(
      const ["--no-fix-imports", "--no-format", "--detailed-exit-code"],
      failOnError: false,
      onStdout: (stream) => stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) => lines.add(line)),
    );
    expect(code, HookResult.linter.index);
    expect(lines.length, 4);
    expect(lines[2],
        "  info - The value of the local variable 'x' isn't used at lib${separator}src${separator}analyze.dart:2:7 - (unused_local_variable)");
  });
}
