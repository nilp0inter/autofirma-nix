# autofirma-nix

[![release-24.11](https://github.com/nilp0inter/autofirma-nix/actions/workflows/build-and-cache-24-11-on-schedule.yml/badge.svg)](https://github.com/nilp0inter/autofirma-nix/actions/workflows/build-and-cache-24-11-on-schedule.yml)
[![unstable](https://github.com/nilp0inter/autofirma-nix/actions/workflows/build-and-cache-unstable-on-schedule.yml/badge.svg)](https://github.com/nilp0inter/autofirma-nix/actions/workflows/build-and-cache-unstable-on-schedule.yml)

This repository provides a suite of tools needed to interact with Spain’s public administration,
alongside NixOS and Home Manager modules for easy integration. These tools include:

- **AutoFirma** for digitally signing documents  
- **DNIeRemote** for using an NFC-based national ID with an Android device as an NFC reader  
- **Configurador FNMT-RCM** for securely requesting the personal certificate from the Spanish Royal Mint (**Fábrica Nacional de Moneda y Timbre**)  

## Usage Example

```console
$ nix run --accept-flake-config github:nilp0inter/autofirma-nix#dnieremote
```

## AutoFirma on NixOS and Home Manager

A NixOS module is provided to enable AutoFirma on NixOS and another one for Home Manager.
You only need to enable one of them, depending on whether you want AutoFirma
system-wide or at the user level.

Once you have enabled one of these modules, if you want to use AutoFirma in Firefox,
you must run the `autofirma-setup` command (see below).

### Home Manager Configuration

The integration of AutoFirma in Home Manager enables the `autofirma` command for
signing PDF documents and configures the Firefox browser (if enabled through
`programs.firefox.enable`) to use AutoFirma on websites that require it.

Additionally, you can enable DNIe integration, including NFC-based DNIe from an
Android mobile via DNIeRemote.

`autofirma-nix` provides a Home Manager module that you should import in your Home
Manager configuration file. The setup may vary slightly depending on your Home
Manager installation method. Below are examples for a standalone configuration.

```nix
# flake.nix

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    autofirma-nix = {
      url = "github:nilp0inter/autofirma-nix";  # If you're tracking NixOS unstable
      # url = "github:nilp0inter/autofirma-nix/release-24.11";  # If you're tracking NixOS 24.11
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      "https://autofirma-nix.cachix.org"
    ];
    extra-trusted-public-keys = [
      "autofirma-nix.cachix.org-1:cDC9Dtee+HJ7QZcM8s36836scXyRToqNX/T+yvjiI0E="
    ];
  };

  outputs = {nixpkgs, home-manager, autofirma-nix, ...}: {
    homeConfigurations."miusuario" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;

      modules = [
        autofirma-nix.homeManagerModules.default
        ./home.nix
      ];
    };
  };
}
```

```nix
# home.nix
{ pkgs, config, ... }: {
  config = {
    programs.autofirma.enable = true;
    programs.autofirma.firefoxIntegration.profiles = {
      myprofile = {  # The name of the Firefox profile where AutoFirma will be enabled
        enable = true;
      };
    };
    programs.dnieremote.enable = true;

    programs.configuradorfnmt.enable = true;
    programs.configuradorfnmt.firefoxIntegration.profiles = {
      myprofile = {  # The name of the Firefox profile where the FNMT Configurator will be enabled
        enable = true;
      };
    };

    programs.firefox = {
      enable = true;
      policies = {
        SecurityDevices = {
          "OpenSC PKCS11" = "${pkgs.opensc}/lib/opensc-pkcs11.so";  # To use DNIe and other smart cards
          "DNIeRemote" = "${config.programs.dnieremote.finalPackage}/lib/libdnieremotepkcs11.so";  # To use DNIe via NFC from an Android mobile
        };
      };
      profiles.myprofile = {
        id = 0;  # Makes this profile the default profile
        # ... Other configuration options for this profile
      };
    };
  };
}
```

### NixOS Configuration

The AutoFirma integration in NixOS enables the `autofirma` command for signing PDF
documents and configures the Firefox browser (if enabled through
`programs.firefox.enable`) to use AutoFirma on websites that require it.

Additionally, you can enable DNIe integration, including NFC-based DNIe from an
Android mobile via DNIeRemote.

```nix
# flake.nix

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    autofirma-nix.url = "github:nilp0inter/autofirma-nix";
    # autofirma-nix.url = "github:nilp0inter/autofirma-nix/release-24.11";  # If you're using NixOS 24.11
  };

  outputs = { self, nixpkgs, autofirma-nix, ... }: {
    nixosConfigurations."hostname" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        autofirma-nix.nixosModules.default
        ({ pkgs, config, ... }: {
          programs.autofirma.enable = true;
          programs.autofirma.fixJavaCerts = true;
          programs.autofirma.firefoxIntegration.enable = true;  # Let Firefox use AutoFirma

          programs.dnieremote.enable = true;

          programs.configuradorfnmt.enable = true;
          programs.configuradorfnmt.firefoxIntegration.enable = true;  # Let Firefox use the FNMT Configurator

          # Firefox
          programs.firefox.enable = true;
          programs.firefox.policies = {
            SecurityDevices = {
              "OpenSC PKCS#11" = "${pkgs.opensc}/lib/opensc-pkcs11.so";  # To use DNIe and other smart cards
              "DNIeRemote" = "${config.programs.dnieremote.finalPackage}/lib/libdnieremotepkcs11.so";  # To use DNIe via NFC from an Android mobile
            };
          };
        })
      ];
    };
  };
}
```

### Creating Certificates

Once AutoFirma is installed and enabled, you need to create a certificate so that
the browser can communicate with AutoFirma. To do this, run the following command
(with Firefox open):

```
$ autofirma-setup
```

Afterwards, restart Firefox for the changes to take effect.

### Uninstalling Certificates

If you wish to uninstall the certificates created by `autofirma-setup`, you can run:

```
$ autofirma-setup --uninstall
```

## Managing Certificates in **autofirma-nix**

The Government publishes a list of authorized service providers, each offering various
certificates (production, development, valid, expired, etc.). For **autofirma-nix** to
trust a specific certificate, two conditions must be met:

1. It must come from one of these official providers.
2. It must also appear in the system’s *ca-bundle* (or *cacerts*) on NixOS.

This way, **autofirma-nix** only accepts certificates recognized by both the Government
and the system. If the user blocks or adds one in the NixOS configuration, those changes
are automatically applied to **autofirma-nix**. If a certificate is not in the local
*ca-bundle*, even if an official provider publishes it, **autofirma-nix** will not include
it.

### Relevant NixOS Options

The following NixOS options determine which certificates are accepted or blocked in the
system *truststore*, directly affecting **autofirma-nix**:

- **`security.pki.certificateFiles`**  
  Adds additional certificates to the global *truststore*. If any match the official list,
  **autofirma-nix** will accept them.

- **`security.pki.caCertificateBlacklist`**  
  Blocks specific certificates. Even if they are on the official list, **autofirma-nix** will
  exclude them if they appear in this blacklist.

**Minimal Example**:
```nix
{
  security.pki = {
    certificateFiles = [
      ./my-certificate.crt
    ];
    caCertificateBlacklist = [
      "Izenpe.com"
    ];
  };
  programs.autofirma.enable = true;
}
```

If `./my-certificate.crt` is on the official list, it will be included in autofirma-nix.
However, since `Izenpe.com` is blocked, it will be ignored even if it appears on the
official list.

## Troubleshooting

### Security devices do not seem to update or do not appear

If you have installed AutoFirma and enabled Firefox integration, but Firefox does not
detect the security devices, you may need to remove the `pkcs11.txt` file from the
Firefox profile folder. For instance, if you enabled the Home Manager module and the
profile is named `myprofile`, the file is located in `~/.mozilla/firefox/myprofile/pkcs11.txt`.

Removing it and restarting Firefox should solve the issue:

```console
$ rm ~/.mozilla/firefox/myprofile/pkcs11.txt
$ firefox
```

### Missing certificates even though the DNIe PIN was requested

If OpenSC PKCS#11 prompts you for a password but no certificates are available for
signing, you might see something like the following in the Autofirma logs (when
running it from a terminal):

```console
$ autofirma
...
INFO: El almacen externo 'OpenSC PKCS#11' ha podido inicializarse, se anadiran sus entradas y se detiene la carga del resto de almacenes
...
INFO: Se ocultara el certificado por no estar vigente: java.security.cert.CertificateExpiredException: NotAfter: Sat Oct 26 15:03:27 GMT 2024
...
INFO: Se ocultara el certificado por no estar vigente: java.security.cert.CertificateExpiredException: NotAfter: Sat Oct 26 15:03:27 GMT 2024
...
SEVERE: Se genero un error en el dialogo de seleccion de certificados: java.lang.reflect.InvocationTargetException
....
SEVERE: El almacen no contiene ningun certificado que se pueda usar para firmar: es.gob.afirma.keystores.AOCertificatesNotFoundException: No se han encontrado certificados validos en el almacen
```

This occurs because your certificates have expired, as indicated by the “NotAfter:” date.

If the certificates are not expired because you recently renewed them, but you used
AutoFirma before this renewal, it is possible that OpenSC has cached your old certificates.
To fix this, you need to delete the OpenSC cache. [By default, it is located at
$HOME/.cache/opensc](https://github.com/OpenSC/OpenSC/wiki/Environment-variables).

```console
$ rm -rf $HOME/.cache/opensc
```
