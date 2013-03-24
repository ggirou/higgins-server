part of higgins_server;

class GitRunner {
  String _gitExecutablePath;
  
  GitRunner({String gitExecutablePath: "git"}) {
    _gitExecutablePath = gitExecutablePath;
  }

  void gitClone(String gitRepoUrl){
    List<String> args = ["clone", gitRepoUrl];
    print("git clone $gitRepoUrl");
    _executeGitCommand(args);
  }

  void _executeGitCommand(List<String> args) {
    ProcessOptions processOptions = new ProcessOptions();
    Process.run(_gitExecutablePath, args, processOptions)
    .then((ProcessResult pr) {
      if(pr.exitCode == 0){
        print("Git clone success");
      }else {
        print("Git clone failed with error code ${pr.exitCode}, ${pr.stderr}");
      }
    });
  }
}
