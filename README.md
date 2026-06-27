# axosc 🌌

An [Ambxst](https://github.com/Axenide/Ambxst) shell themed On-Screen Controller (OSC) for **mpv**.

`axosc` replaces the default stock mpv OSC with a modern, and funky OSC that fits with Ambxst shell.

---

## 🛠️ Prerequisites

To use `axosc`, the default OSC and native window dragging behaviors must be disabled.

Add the following lines to your `mpv.conf` file (typically located at `~/.config/mpv/mpv.conf`):

```ini
# Required settings for axosc
osc=no
window-dragging=no
osd-bar=no
```

---

## 📦 Installation

### ❄️ NixOS / Home Manager

`axosc` provides a native package exposed through an overlay which can be used in Home Manager configuration.

1. **Add this repo as a flake input:**

```nix
inputs = {
  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  
  axosc = {
    url = "github:Passeriform/axosc";
    inputs.nixpkgs.follows = "nixpkgs";
  }
};
```

2. **Pass the overlay provided by the flake into your `nixpkgs` configuration:**

```nix
outputs = { self, nixpkgs, axosc, ... }: {
  nixosConfigurations.yourHostname = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      {
        nixpkgs.overlays = [ axosc.overlays.default ];
      }
      ...
    ];
  };
};
```

3. **Apply the overlay and use overlaid `pkgs.mpvScripts` in `programs.mpv` module:**

```nix
programs.mpv = {
  enable = true;

  scripts = with pkgs.mpvScripts; [ axosc ];

  config = {
    osc = "no";
    window-dragging = "no";
    osd-bar = "no";
  };
};
```

---

### 🐧 Other Linux

To install `axosc` on other Linux distributions, clone the repository and link or copy the source scripts directly into your mpv scripts directory:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Passeriform/axosc.git
   cd axosc
   ```

2. **Create the mpv scripts directory:**
   ```bash
   mkdir -p ~/.config/mpv/scripts/
   ```

3. **Symlink or copy the contents of `src/` into your mpv scripts folder:**
   ```bash
   # Using symlinks (recommended for upstream version)
   ln -s src/* ~/.config/mpv/scripts/
   
   # Alternative: Direct copy
   # cp -r src/* ~/.config/mpv/scripts/
   ```

4. **Update mpv configuration to disable conflicting options:**
  ```bash
  osc=no
  window-dragging=no
  osd-bar=no
  ```

---

## 🎨 Customization

Configuration parameters can be tweaked under `Config` table in `main.lua`.

> Until I add script-opts support (>﹏<)...

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
