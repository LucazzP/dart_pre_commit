
import 'program_runner.dart';
import 'task_error.dart';

class BuildRunner {
  final ProgramRunner runner;

  const BuildRunner(this.runner);

  Future<bool> call() async {
    final exitCode = await runner.run(
      "flutter",
      [
        'pub',
        "run",
        "build_runner",
        "build",
        "--delete-conflicting-outputs",
      ],
    );
    switch (exitCode) {
      case 0:
        return false;
      case 1:
        return true;
      default:
        throw const TaskError("build_runner failed to build the files");
    }
  }
}
