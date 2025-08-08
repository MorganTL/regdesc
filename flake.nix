{
  description = "Pythonic register map descriptors";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # this builds regdesc-codegen, regdesc-serialize and regdesc-gen-rs-pac
      regdesc = pkgs.python3Packages.buildPythonPackage {
        pname = "regdesc";
        version = "unstable-2024-06-22";
        src = ./.;
        format = "pyproject";
        propagatedBuildInputs = with pkgs.python3Packages; [
          hatchling
          jinja2
          setuptools
        ];
      };

      artiq-reg-generator =
        { module-name }:
        pkgs.stdenv.mkDerivation {
          name = module-name;
          nativeBuildInputs = [
            regdesc
            pkgs.black # regdesc-codegen need black formatter
          ];
          src = ./.;
          installPhase = ''
            mkdir -p $out
            regdesc-codegen -t artiq_c_like.tpl.py -o ${module-name}.py ${module-name}
            cp ${module-name}.py $out
          '';
        };

    in
    {
      packages.${system} = {
        inherit regdesc;
        ad5781-reg = artiq-reg-generator { module-name = "ad5781"; };
        ad9910-reg = artiq-reg-generator { module-name = "ad9910"; };
        adf4002-reg = artiq-reg-generator { module-name = "adf4002"; };
        adf4360_8-reg = artiq-reg-generator { module-name = "adf4360_8"; };
        adf5356-reg = artiq-reg-generator { module-name = "adf5356"; };
        trf372017-reg = artiq-reg-generator { module-name = "trf372017"; };
      };
      devShells.${system} = {
        default = pkgs.mkShell {
          name = "regdesc-dev-shell";
          buildInputs = with pkgs; [
            regdesc
            pre-commit
            (python3.withPackages (
              ps: with ps; [
                hatchling
              ]
            ))
            # auto-formatter
            black
            clang-tools
            html-tidy
            rustfmt
          ];
        };
      };
    };
}
