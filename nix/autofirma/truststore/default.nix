{ stdenv, jre, xmlstarlet, curl, fetchurl, storepass ? "autofirma" }:
stdenv.mkDerivation {
  name = "autofirma-truststore";
  srcs = [
    #
    # ACCV
    #
    (fetchurl {
      url = "https://www.accv.es/fileadmin/Archivos/certificados/accv_root_rsa_tls_2024.crt";
      hash = "sha256-tAv6iICgL5MCVkPG27053xlKKFTQduFnor2EZ8+eLDQ=";
      meta = {
        NombreSocial = "Infraestructuras y Servicios de Telecomunicaciones y Certificación S.A.";
        Cif = "A40573396";
        Certificado = "ACCV ROOT RSA TLS 2024 | CA RAÍZ (Vigente hasta 26/01/2049)";
        AvailableAt = "https://www.accv.es/servicios/empresas/descarga-de-certificados-jerarquia/";
      };
    })
    (fetchurl {
      url = "https://www.accv.es/fileadmin/Archivos/certificados/accv_root_ecc_tls_2024.crt";
      hash = "sha256-ec1VRVKWrftVzfDb6RdphaC1A8VEJ2xakwXy7JtmaTo=";
      meta = {
        NombreSocial = "Infraestructuras y Servicios de Telecomunicaciones y Certificación S.A.";
        Cif = "A40573396";
        Certificado = "ACCV ROOT ECC TLS 2024 | CA RAÍZ (Vigente hasta 26/01/2049)";
        AvailableAt = "https://www.accv.es/servicios/empresas/descarga-de-certificados-jerarquia/";
      };
    })
    (fetchurl {
      url = "https://www.accv.es/fileadmin/Archivos/certificados/accv_root_rsa_eidas_tsa_2024.crt";
      hash = "sha256-Y8MIDMi/Y8lMdBpw2u9StSdKz+CD64zsKRMeogk4jCU=";
      meta = {
        NombreSocial = "Infraestructuras y Servicios de Telecomunicaciones y Certificación S.A.";
        Cif = "A40573396";
        Certificado = "ACCV ROOT RSA TSA EIDAS 2024 | CA RAÍZ (Vigente hasta 26/01/2049)";
        AvailableAt = "https://www.accv.es/servicios/empresas/descarga-de-certificados-jerarquia/";
      };
    })
    (fetchurl {
      url = "https://www.accv.es/fileadmin/Archivos/certificados/accv_root_ecc_eidas_tsa_2024.crt";
      hash = "sha256-rMrf6ruG3fp/K6Euo4UruQs809w5tYNkwy3ooqvQbLw=";
      meta = {
        NombreSocial = "Infraestructuras y Servicios de Telecomunicaciones y Certificación S.A.";
        Cif = "A40573396";
        Certificado = "ACCV ROOT ECC TSA EIDAS 2024 | CA RAÍZ (Vigente hasta 26/01/2049)";
        AvailableAt = "https://www.accv.es/servicios/empresas/descarga-de-certificados-jerarquia/";
      };
    })

    #
    # ANF AC
    #
    (fetchurl {
      url = "https://crl.anf.es/certificates-download/ANFACSLRootCA.cer";
      hash = "sha256-+NhqlreyFcWoeJaXJkEE0pa0W1x5y0FY7pOhUOFNyaQ=";
      meta = {
        NombreSocial = "ANF AUTORIDAD DE CERTIFICACIÓN ASOCIACIÓN (ANF AC)";
        Cif = "G63287510";
        Certificado = "ANF AC SL Root CA";
        AvailableAt = "https://crl.anf.es/";
      };
    })

    #
    # FNMT-RCM
    #
    (fetchurl {
      url = "https://www.sede.fnmt.gob.es/documents/10445900/10526749/AC_Raiz_FNMT-RCM_SHA256.cer";
      hash = "sha256-68VXDCkBjE1nsaoSe68S9wO0YR68F7fatVc4lBebk/o=";
      meta = {
        NombreSocial = "Fábrica Nacional de Moneda y Timbre - Real Casa de la Moneda, Entidad Pública Empresarial, Medio Propio (FNMT-RCM)";
        Cif = "Q2826004J";
        Certificado = "AC Raíz FNMT-RCM";
        AvailableAt = "https://www.sede.fnmt.gob.es/descargas/certificados-raiz-de-la-fnmt";
      };
    })
    (fetchurl {
      url = "https://www.sede.fnmt.gob.es/documents/10445900/10526749/AC_Raiz_FNMT-RCM-SS.cer";
      hash = "sha256-VUFTsT0s+d23U7++Gk4K4I0KpBhwWP5gorhisuS4e8s=";
      meta = {
        NombreSocial = "Fábrica Nacional de Moneda y Timbre - Real Casa de la Moneda, Entidad Pública Empresarial, Medio Propio (FNMT-RCM)";
        Cif = "Q2826004J";
        Certificado = "AC Raíz FNMT-RCM Servidores Seguros";
        AvailableAt = "https://www.sede.fnmt.gob.es/descargas/certificados-raiz-de-la-fnmt";
      };
    })

  ];

  dontUnpack = true;

  buildPhase = ''
    for _src in $srcs; do
      ls -l $_src
      ${jre}/bin/keytool -importcert -noprompt -alias $_src -keystore $out -storepass ${storepass} -file $_src
    done
  '';
}
