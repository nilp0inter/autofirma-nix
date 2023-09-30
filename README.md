# autofirma-nix
Integración de AutoFirma en Nix/NixOS


## Ejemplo de uso
```console
$ nix run github:nilp0inter/autofirma-nix
```

## Autofirma en NixOS y Home Manager

Se proporciona un módulo de NixOS para habilitar AutoFirma en NixOS y otro para
Home Manager. Sólo es necesario habilitar uno de ellos, dependiendo de si se
quiere habilitar AutoFirma a nivel de sistema o de usuario.

Una vez habilitado uno de los módulos, si se quiere utilizar AutoFirma en
Firefox, es necesario ejecutar el comando `autofirma-setup` (ver más abajo).


### Configuración de NixOS

La integración de AutoFirma en NixOS habilita el comando `autofirma` para el
firmado de documentos PDF y configura el navegador Firefox (si está habilitado
mediante la opción `programs.firefox.enable`) para que utilice AutoFirma en
sitios web que lo requieran.

Adicionalmente, se puede habilitar la integración con el DNIe y el DNIe por NFC
desde un móvil Android usando DNIeRemote.


```nix
# flake.nix

{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    autofirma-nix.url = "github:nilp0inter/autofirma-nix";
  };

  outputs = { self, nixpkgs, autofirma-nix, ... }: {
    nixosConfigurations."hostname" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        autofirma-nix.nixosModules.default
        ({ pkgs, config, ... }: {
          programs.autofirma.enable = true;
          programs.autofirma.firefoxIntegration.enable = true;  # Para que Firefox utilice AutoFirma

          programs.DNIeRemote.enable = true;

          # Firefox
          programs.firefox.enable = true;
          programs.firefox.policies =  {
            SecurityDevices = {
              "OpenSC PKCS#11" = "${pkgs.opensc}/lib/opensc-pkcs11.so";  # Para poder utilizar el DNIe, y otras tarjetas inteligentes
              "DNIeRemote" = "${config.programs.DNIeRemote.finalPackage}/lib/libdnieremotepkcs11.so";  # Para poder utilizar el DNIe por NFC desde un móvil Android
            };
          };
        })
      ];
    };
  };
}
```

### Configuración de Home Manager

La integración de AutoFirma en Home Manager habilita el comando `autofirma` para
el firmado de documentos PDF y configura el navegador Firefox (si está habilitado
mediante la opción `programs.firefox.enable`) para que utilice AutoFirma en
sitios web que lo requieran.

Adicionalmente, se puede habilitar la integración con el DNIe y el DNIe por NFC
desde un móvil Android usando DNIeRemote.

```nix
# home.nix
{ pkgs, config, ... }: {
  config = {
    programs.autofirma.enable = true;
    programs.autofirma.firefoxIntegration.enable = true;  # Para que Firefox utilice AutoFirma
    programs.autofirma.firefoxIntegration.profiles = {
      miperfil = {  # El nombre del perfil de firefox donde se habilitará AutoFirma
        enable = true;
      };
    };
    programs.DNIeRemote.enable = true;

    programs.firefox = {
      enable = true;
      package = pkgs.firefox.override (args: {
        extraPolicies = {
          SecurityDevices = {
            "OpenSC PKCS11" = "${pkgs.opensc}/lib/opensc-pkcs11.so";  # Para poder utilizar el DNIe, y otras tarjetas inteligentes
            "DNIeRemote" = "${config.programs.DNIeRemote.finalPackage}/lib/libdnieremotepkcs11.so";  # Para poder utilizar el DNIe por NFC desde un móvil Android
          };
        };
      });
      profiles.miperfil = {
        id = 0;  # Hace que este perfil sea el perfil por defecto
        # ... El resto de opciones de configuración de este perfil
      };
    };
  };
}
```

### Creación de certificados

Una vez instalado y habilitado AutoFirma, es necesario crear un certificado
para que el navegador pueda comunicarse con AutoFirma. Para ello, se debe ejecutar
el siguiente comando (con Firefox abierto):

```
$ autofirma-setup
```

Después es necesario reiniciar Firefox para que los cambios surtan efecto.
