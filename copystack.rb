cask "copystack" do
  version "1.0.1"
  sha256 "..."

  url "https://github.com/sharky-3/CopyStack/releases/download/v#{version}/CopyStack.zip"
  name "CopyStack"
  desc "Clipboard manager"
  homepage "https://github.com/sharky-3/CopyStack"

  auto_updates true
  app "CopyStack.app"
end
