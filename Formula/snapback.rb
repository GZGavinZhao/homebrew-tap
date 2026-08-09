class Snapback < Formula
  desc "Run a command, capture its filesystem changes, then commit or roll back"
  homepage "https://github.com/GZGavinZhao/snapback"
  # The source repository is private, so the archive download needs GitHub
  # credentials. `GitHub::API.credentials` is Homebrew's own credential lookup:
  # it tries HOMEBREW_GITHUB_API_TOKEN, then the `gh` CLI login, then the macOS
  # keychain -- so most users need no extra setup.
  url "https://github.com/GZGavinZhao/snapback/archive/refs/tags/v0.0.1.tar.gz",
      headers: ["Authorization: Bearer #{GitHub::API.credentials}"]
  sha256 "637acdfabf3e827eea216791edc1668ff42a99ddc216226e9816ed1a5f32ad67"
  license :cannot_represent

  # Package.swift declares .macOS(.v13).
  depends_on macos: :ventura

  # The Swift compiler ships with the Command Line Tools, which Homebrew already
  # requires, and the package has no external dependencies -- so there is
  # nothing else to declare and the build needs no network access.

  def install
    system "swift", "build",
           "--disable-sandbox",
           "--configuration", "release",
           "--product", "snapback",
           "--scratch-path", buildpath/".build"
    bin.install ".build/release/snapback"
    # `try` is an alias for the same binary, matching the name of the Linux tool
    # snapback is modelled on.
    bin.install_symlink "snapback" => "try"
  end

  def caveats
    <<~EOS
      snapback creates APFS snapshots and reads Endpoint Security events, so it
      must run as root:

        sudo snapback -- <command>

      `try` is installed as an alias for `snapback`. If another `try` is already
      on your PATH, the one earlier in PATH wins; check with `which -a try`.

      The process that runs it also needs Full Disk Access:

        System Settings > Privacy & Security > Full Disk Access

      This is an early proof of concept. Read the repository README for which
      operations are captured and which are only partly reversible.
    EOS
  end

  test do
    assert_match "run a command", shell_output("#{bin}/snapback --help")
    # No command given is an input error (exit status 2).
    output = shell_output("#{bin}/snapback 2>&1", 2)
    assert_match "no command given", output

    assert_path_exists bin/"try"
    assert_match "run a command", shell_output("#{bin}/try --help")
  end
end
