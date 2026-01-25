#!/bin/bash
set -e

echo "🛠️  Setting up macOS Development Environment..."

# 1. Install Homebrew if not found
if ! command -v brew &> /dev/null; then
    echo "🍺 Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add to PATH based on architecture
    if [[ $(uname -m) == 'arm64' ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
        eval "$(/usr/local/bin/brew shellenv)"
    fi
else
    echo "✅ Homebrew is already installed."
fi

# 2. Update Homebrew
echo "🔄 Updating Homebrew..."
brew update

# 3. Install Modern Ruby
echo "💎 Installing Ruby 3.3..."
brew install ruby
# Link brew ruby to be first in path
if [[ -d "/opt/homebrew/opt/ruby/bin" ]]; then
  export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
  echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.zshrc
  echo 'export PATH="/opt/homebrew/opt/ruby/bin:$PATH"' >> ~/.bash_profile
elif [[ -d "/usr/local/opt/ruby/bin" ]]; then
  export PATH="/usr/local/opt/ruby/bin:$PATH"
  echo 'export PATH="/usr/local/opt/ruby/bin:$PATH"' >> ~/.zshrc
   echo 'export PATH="/usr/local/opt/ruby/bin:$PATH"' >> ~/.bash_profile
fi

# 4. Verify Ruby Version
RUBY_VERSION=$(ruby -v)
echo "✅ Using Ruby: $RUBY_VERSION"

# 5. Install CocoaPods
echo "📦 Installing CocoaPods..."
gem install cocoapods

echo "🎉 Setup Complete! Please restart your terminal."
