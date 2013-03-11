part of higgins_server;

class GitRunner {
  void gitClone(String gitRepoUrl){
    List<String> args = new List<String>();
    args.addAll(["clone", gitRepoUrl]);
    _executeGitCommand(args);
  }

  void _executeGitCommand(List<String> args) {
    ProcessOptions processOptions = new ProcessOptions();
    Process.run('git', args, processOptions)
    .then((ProcessResult pr) {
      if(pr.exitCode == 0){
        print("Git clone success");
      }else {
        print("Git clone failed with error code ${pr.exitCode}, ${pr.stderr}");
      }
    });
  }
}

