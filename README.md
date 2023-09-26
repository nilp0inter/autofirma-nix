# autofirma-nix
Integración de AutoFirma en Nix/NixOS


## Ejemplo de uso
```
$ nix run github:nilp0inter/autofirma-nix
```

## Autofirma en NixOS

La integración de AutoFirma en NixOS habilita únicamente el comando `autofirma`
para el firmado de documentos PDF y configura el navegador Firefox (si está
habilitado mediante la opción `programs.firefox.enable`) para que utilice
AutoFirma en sitios web que lo requieran.

### Configuración

```
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
        autofirma-nix.nixosModules.autofirma 
        {
          programs.autofirma = {
            enable = true;
            firefoxIntegration = {
              enable = true;
              securityDevice.enable = true;
            };
          };
        }
      ];
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
