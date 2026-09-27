cask "copystack" do
  version "1.0.1"
  sha256 "221e06f84a509ca5258475d1c3a82d66ab2fdefd26577ce5e70b4c0c668e5bc1"

  url "https://github.com/sharky-3/CopyStack/releases/download/v#{version}/CopyStack.zip"
  name "CopyStack"
  desc "Clipboard manager"
  homepage "https://github.com/sharky-3/CopyStack"

  auto_updates true

  app "CopyStack.app"
end
