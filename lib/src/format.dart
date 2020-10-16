import 'dart:io';

import 'program_runner.dart';
import 'task_error.dart';

class Format {
  final ProgramRunner runner;

  const Format(this.runner);

  Future<bool> call(File file) async {
    // final exitCode = await runner.run(
    //   "dart",
    //   [
    //     "format",
    //     "--fix",
    //     "--set-exit-if-changed",
    //     file.path,
    //   ],
    // );

    await runner.run("flutter", ['packages', 'pub', 'global', 'activate', "dartfix"]);

    final exitCode = await runner.run(
      "flutter",
      [
        "packages",
        'pub',
        "run",
        "dartfix",
        "--pedantic",
        "--fix=annotate_overrides",
        "--fix=avoid_annotating_with_dynamic",
        "--fix=avoid_empty_else",
        "--fix=avoid_init_to_null",
        "--fix=avoid_redundant_argument_values",
        "--fix=avoid_relative_lib_imports",
        "--fix=avoid_return_types_on_setters",
        "--fix=avoid_types_on_closure_parameters",
        "--fix=await_only_futures",
        "--fix=convert_class_to_mixin",
        "--fix=curly_braces_in_flow_control_structures",
        "--fix=no_duplicate_case_values",
        "--fix=omit_local_variable_types",
        "--fix=prefer_adjacent_string_concatenation",
        "--fix=prefer_collection_literals",
        "--fix=prefer_conditional_assignment",
        "--fix=prefer_const_constructors",
        "--fix=prefer_const_constructors_in_immutables",
        "--fix=prefer_const_declarations",
        "--fix=prefer_contains",
        "--fix=prefer_equal_for_default_values",
        "--fix=prefer_final_fields",
        "--fix=prefer_final_locals",
        "--fix=prefer_for_elements_to_map_fromIterable",
        "--fix=prefer_if_null_operators",
        "--fix=prefer_inlined_adds",
        "--fix=prefer_int_literals",
        "--fix=prefer_is_empty",
        "--fix=prefer_iterable_whereType",
        "--fix=prefer_null_aware_operators",
        "--fix=prefer_single_quotes",
        "--fix=prefer_spread_collections",
        "--fix=type_init_formals",
        "--fix=unnecessary_brace_in_string_interps",
        "--fix=unnecessary_const",
        "--fix=unnecessary_lambdas",
        "--fix=unnecessary_new",
        "--fix=unnecessary_overrides",
        "--fix=unnecessary_this",
        "--fix=use_function_type_syntax_for_parameters",
        "--fix=use_rethrow_when_possible",
        "--fix=wrong_number_of_type_arguments_constructor",
        '-w',
        '.',
      ],
    );
    switch (exitCode) {
      case 0:
        return false;
      case 1:
        return true;
      default:
        throw TaskError("dartfix failed to format the file", file);
    }
  }
}
